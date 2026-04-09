# GreatMinds TUI — Design Spec

A terminal UI for searching X/Twitter for tweets similar to your thoughts, powered by XAI's Grok API. Built in Julia using [Tachikoma.jl](https://github.com/kahliburke/Tachikoma.jl).

Core concept: type a thought → Grok distills it to its core idea → searches X for similar posts → shows results with similarity scores → drill into detail with similar phrasings and clustered replies.

## Screens

### 1. Input

Full-screen TextArea with the prompt "What's your take?" in a placeholder/label. User types their thought (multi-line supported). Enter submits, Esc quits the app.

### 2. Groking

Split view showing:
- **Top**: the user's original text, dimmed, with a left border
- **Bottom**: Grok's distilled version, bright, with a gold accent border

Keybindings:
- `R` — regenerate (call Grok again)
- `Enter` — approve and proceed to search
- `Esc` — back to Input (preserving typed text)

While waiting for Grok's response, show a spinner/loading indicator.

### 3. Searching

Centered loading state with a Gauge or spinner. Displays "Searching X..." and a count of results found so far as they stream in. Automatically transitions to Results when the search completes.

### 4. Results

Header shows a verdict:
- Red badge "Already expressed" + count if any results >= 90% similarity
- Green badge "Original take" if all results < 90%

SelectableList of results, each row showing:
- Similarity badge: red background for >= 90%, blue for < 90%, with percentage
- Author handle (`@username`)
- Tweet text (truncated to fit terminal width)

The currently selected row is highlighted with a gold border. Arrow keys navigate, Enter drills into Detail, Esc goes back to Groking.

### 5. Detail

Full view of the selected tweet:
- Author, similarity badge, full tweet text
- Tweet URL (displayed, and `O` opens it in the system browser)

Below that, two sections:
- **Similar phrasings**: other tweets expressing the same core idea, shown as a list with gold left border
- **Clustered replies**: replies grouped by semantic similarity, each showing the representative reply text, author, and a count of similar replies (e.g., "+4 similar")

Arrow keys scroll, Esc goes back to Results.

## Architecture

### Single Model

One `GreatMinds <: Tachikoma.Model` struct with:

```julia
@enum Screen home groking searching results detail

mutable struct GreatMinds <: Model
    screen::Screen
    # Input
    input::TextArea
    # Groking
    original_text::String
    distilled_text::String
    groking_loading::Bool
    # Search
    search_results::Vector{SearchResult}
    searching::Bool
    search_count::Int
    # Results
    selected_result::Int
    # Detail
    similar_phrasings::Vector{Phrasing}
    clustered_replies::Vector{ReplyCluster}
    detail_scroll::Int
    # Config
    config::Config
end
```

### Data Types

```julia
struct SearchResult
    id::String
    text::String
    author::String
    similarity::Float64
    url::String
end

struct Phrasing
    text::String
    author::String
end

struct ReplyCluster
    text::String
    author::String
    similar_count::Int
end

struct Config
    xai_api_key::String
    twitter_bearer_token::String  # app-only auth for fetching replies
    grok_model::String            # default: "grok-3"
    search_model::String          # default: "grok-4-fast"
    similarity_threshold::Float64 # default: 0.9
end
```

### Event Handling

`update!(model, event)` dispatches on `model.screen`:

- **home**: TextArea handles its own input. Enter triggers transition to groking.
- **groking**: R regenerates, Enter approves, Esc goes back. Loading state blocks input.
- **searching**: No user input — auto-transitions when done.
- **results**: Up/Down navigate list, Enter selects, Esc goes back.
- **detail**: Up/Down scroll, O opens URL, Esc goes back.

### Async API Calls

Use Tachikoma's task queue with wake-channel signaling:

1. **Rewrite**: Spawn async task calling Grok 3 to distill the thought. On completion, update `distilled_text` and set `groking_loading = false`.
2. **Search**: Spawn async task calling Grok with x_search. Results arrive as a batch (parsed from Grok's JSON response). On completion, populate `search_results` and set `searching = false`.
3. **Replies**: When entering Detail, spawn async task to fetch replies via Twitter API v2 and cluster them by cosine similarity.

Wake-channel signaling ensures the UI updates with minimal latency (~1-2ms) when async results arrive.

### View Rendering

`view(model, frame)` switches on `model.screen` and renders the appropriate layout:

- Each screen uses `split_layout()` with constraints to divide the terminal area
- StatusBar at the bottom of every screen shows context-appropriate keybindings
- Widgets: TextArea (input), Paragraph (text display), SelectableList (results), Gauge (search progress), Block (containers with borders)

### XAI API Integration

Two API functions, ported from take.best's `xai.jl`:

**`rewrite(config, thought) -> String`**
- POST to `https://api.x.ai/v1/chat/completions`
- Model: `config.grok_model` (Grok 3)
- System prompt: strip wit/humor/style, return plain-language core idea
- Temperature: 0.3

**`search_similar(config, query) -> Vector{SearchResult}`**
- POST to `https://api.x.ai/v1/chat/completions`
- Model: `config.search_model` (Grok 4 Fast)
- Uses x_search tool to find similar posts on X
- Prompt asks for JSON array with text, author, similarity, url fields
- Parses response into `SearchResult` structs

**`fetch_replies(config, tweet_id) -> Vector{ReplyCluster}`**
- GET from Twitter API v2 search endpoint
- Searches for replies to the given tweet
- Clusters replies by cosine similarity (threshold from config)

### Similarity

Ported from take.best's `similarity.jl`:
- `cosine_similarity(a, b)` — dot product / (norm * norm)
- `cluster(items, threshold)` — groups items above threshold, returns representative + count

### Configuration

`config.toml` in the project root:

```toml
[xai]
api_key = "xai-..."

[twitter]
bearer_token = "AAAA..."   # app-only bearer token for fetching replies

[models]
grok = "grok-3"
search = "grok-4-fast"

[search]
similarity_threshold = 0.9
```

Loaded at startup via a TOML parser. All values accessed through the `Config` struct.

## Originality Tracking & Playful Personality

### Concept

The app tracks the user's history of thoughts and their similarity scores. Based on this track record, the UI copy shifts tone along an NPC-to-insane spectrum:

- **NPC mode** (mostly unoriginal thoughts) — gentle ribbing, "What's your take this time, NPC?", "Searching for who said it first...", "Shocking — someone else thought this too"
- **Neutral** (mixed results) — default tone, "What's your take?"
- **Insane mode** (mostly original thoughts) — impressed/unhinged, "What's your take, you absolute original?", "Let's see if anyone else is this unhinged...", "Nobody. You're alone out here."

### Originality Score

A single number from 0.0 (pure NPC) to 1.0 (pure insane), displayed in the StatusBar at the bottom of every screen. Computed as a weighted average of past search results, where recent thoughts count more than older ones.

**Calculation:**
- Each past thought gets a per-thought originality: `1.0 - max_similarity` (where `max_similarity` is the highest similarity score from that search). If the best match was 96%, the thought scores 0.04. If the best match was 40%, it scores 0.60.
- Weights decay exponentially: most recent thought has weight 1.0, second most recent 0.7, third 0.49, etc. (decay factor: 0.7)
- Originality score = weighted average of per-thought originality scores
- First-time users start at 0.5 (neutral)

### Tone Thresholds

| Score Range | Label | Tone |
|-------------|-------|------|
| 0.0 – 0.25 | NPC | Maximum ribbing |
| 0.25 – 0.40 | Normie | Light teasing |
| 0.40 – 0.60 | — | Neutral/default |
| 0.60 – 0.75 | Free thinker | Mild praise |
| 0.75 – 1.0 | Insane | Full unhinged praise |

### Tone-Shifted UI Copy

Each screen has variant copy keyed to the tone tier. Examples:

**Input screen prompt:**
- NPC: "What's your take, NPC?"
- Normie: "Go on then, what's your take?"
- Neutral: "What's your take?"
- Free thinker: "What's your take, original?"
- Insane: "What's your take, you absolute psycho?"

**Groking screen (approval):**
- NPC: "Here's what you actually meant (we both know someone already said it)"
- Neutral: "Here's the core idea"
- Insane: "Here's the core idea (brace yourself, this might actually be new)"

**Results verdict:**
- NPC + already expressed: "Called it. NPC confirmed."
- Neutral + already expressed: "Already expressed"
- Insane + already expressed: "Even geniuses repeat sometimes"
- NPC + original: "Wait... did you just have an original thought?"
- Neutral + original: "Original take!"
- Insane + original: "Nobody. You're alone out here. Again."

**Searching status:**
- NPC: "Searching for who said it first..."
- Neutral: "Searching X..."
- Insane: "Let's see if anyone else is this unhinged..."

### StatusBar Display

Bottom of every screen shows the originality score with label:

```
[NPC ████░░░░░░ 0.18]     Esc: back  ↑↓: navigate  Enter: select
```

The gauge fills proportionally to the score. Label updates with tone tier name.

### History Persistence

Stored in `~/.greatminds/history.json`:

```json
[
  {
    "thought": "AI will replace most jobs...",
    "distilled": "Artificial intelligence will likely displace...",
    "max_similarity": 0.96,
    "result_count": 5,
    "timestamp": "2026-04-09T14:30:00"
  },
  ...
]
```

Loaded at startup, appended after each search completes. No cap on history size (the exponential decay makes old entries negligible anyway).

### Data Types

```julia
struct ThoughtRecord
    thought::String
    distilled::String
    max_similarity::Float64
    result_count::Int
    timestamp::String
end
```

Added to the Model:

```julia
# In GreatMinds model
history::Vector{ThoughtRecord}
originality_score::Float64  # 0.0 (NPC) to 1.0 (insane)
```

### Functions

- `load_history() -> Vector{ThoughtRecord}` — reads `~/.greatminds/history.json`, returns empty vector if missing
- `save_history(history)` — writes to `~/.greatminds/history.json`
- `compute_originality(history) -> Float64` — weighted average with 0.7 decay
- `tone_tier(score) -> Symbol` — returns `:npc`, `:normie`, `:neutral`, `:freethinker`, or `:insane`
- `tone_copy(screen, element, tier) -> String` — returns the appropriate copy for the given screen, element, and tone

## Navigation Summary

| Screen    | Enter            | Esc              | Other        |
|-----------|------------------|------------------|--------------|
| Input     | → Groking        | Quit app         |              |
| Groking   | → Searching      | ← Input          | R: regenerate|
| Searching | (auto-advance)   | ← Groking (cancel)| —           |
| Results   | → Detail         | ← Groking        | ↑↓: navigate |
| Detail    | —                | ← Results        | O: open URL, ↑↓: scroll |

## Dependencies

- **Tachikoma.jl** — TUI framework
- **HTTP.jl** — HTTP client for API calls
- **JSON3.jl** — JSON parsing
- **TOML** (stdlib) — config parsing

## Project Structure

```
GreatMinds/
├── config.toml              # User configuration (API keys, model settings)
├── Project.toml             # Julia package manifest
├── src/
│   ├── GreatMinds.jl        # Module definition, exports
│   ├── app.jl               # Model struct, init, update!, view, should_quit
│   ├── screens/
│   │   ├── home.jl          # Input screen rendering
│   │   ├── groking.jl       # Groking screen rendering
│   │   ├── searching.jl     # Search progress screen rendering
│   │   ├── results.jl       # Results list screen rendering
│   │   └── detail.jl        # Detail view screen rendering
│   ├── api/
│   │   ├── xai.jl           # Grok rewrite + search functions
│   │   └── twitter.jl       # Reply fetching
│   ├── similarity.jl        # Cosine similarity + clustering
│   ├── config.jl            # Config loading from TOML
│   ├── history.jl           # History persistence + originality scoring
│   ├── personality.jl       # Tone tiers + UI copy variants
│   └── types.jl             # Data type definitions
└── docs/
```
