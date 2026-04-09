# GreatMinds

A terminal UI for finding out if your thoughts are original. Type a take, and GreatMinds uses Grok to search X for similar posts -- because great minds think alike.

## How it works

1. **Type your take** -- enter whatever's on your mind
2. **Groking** -- Grok distills your thought down to its core idea, stripping out wit, style, and rhetoric. If grok gets the essence wrong then you should reword your input until groks response isn’t lossy. Grok will be doing the searching so you need to write for Grok to understand.
3. **Search** -- Grok searches X for posts expressing the same idea
4. **Results** -- see who else said it, with similarity scores. Red badges for near-matches, blue for loose ones.
5. **Detail** -- drill into a result to read replies. Arrow left/right to browse alternative phrasings of the same idea.

## Personality

GreatMinds tracks your originality over time. If your thoughts keep coming back as duplicates, the UI starts calling you an NPC. String together a run of original takes and it shifts to impressed disbelief. Five tiers:

| Score | Label | Vibe |
|-------|-------|------|
| 0.00 - 0.25 | NPC | "Called it. NPC confirmed." |
| 0.25 - 0.40 | Normie | "Yeah, a few people beat you to it" |
| 0.40 - 0.60 | Thinker | Neutral |
| 0.60 - 0.75 | Free Thinker | "Another original -- you're on a streak" |
| 0.75 - 1.00 | Insane | "Nobody. You're alone out here. Again." |

The originality score uses an exponential curve -- a 95% similarity match isn't that harsh. Only near-perfect matches (98%+) really punish you.

## Setup

Requires Julia 1.12+ and an [xAI API key](https://console.x.ai/).

### Install

```julia
using Pkg
Pkg.Apps.add(url="https://github.com/jkroso/GreatMinds.git")
```

Then configure your API key:

```bash
mkdir -p ~/.greatminds
cat > ~/.greatminds/config.toml << 'EOF'
[xai]
api_key = "xai-YOUR-KEY-HERE"
EOF
```

Make sure `~/.julia/bin` is in your PATH, then run:

```bash
greatminds
```

### Compile a standalone binary (optional)

For instant startup with no JIT warmup:

```bash
git clone https://github.com/jkroso/GreatMinds.git && cd GreatMinds
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. $(julia -e 'print(joinpath(Sys.BINDIR,"..","share","julia","juliac","juliac.jl"))') \
  --experimental --output-exe greatminds greatminds.jl
cp greatminds /usr/local/bin/
```

## Configuration

`~/.greatminds/config.toml`:

```toml
[xai]
api_key = "xai-..."

[models]
grok = "grok-4.20-0309-reasoning"      # used for rewriting
search = "grok-4.20-0309-reasoning"    # used for search + replies

[search]
similarity_threshold = 0.9             # cutoff for "already expressed"
```

## Keybindings

| Key | Action |
|-----|--------|
| Enter | Submit / approve / drill in |
| Esc | Back / quit |
| Up/Down | Navigate results, scroll replies |
| Left/Right | Browse similar phrasings (detail screen) |
| R | Regenerate rewrite (groking screen) |
| O | Open tweet in browser (detail screen) |
| Ctrl+H | Clear originality history |

## Built with

- [Tachikoma.jl](https://github.com/kahliburke/Tachikoma.jl) -- terminal UI framework
- [xAI Responses API](https://docs.x.ai) -- Grok models + x_search for live X search
