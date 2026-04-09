# GreatMinds TUI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a terminal UI that lets users type a thought, have Grok distill it, search X for similar posts, and browse results — with a playful personality that shifts based on the user's originality track record.

**Architecture:** Single Tachikoma.jl Model with a screen enum driving a 5-screen linear flow (home → groking → searching → results → detail). Async API calls use Tachikoma's TaskQueue with wake-channel signaling. History persists to `~/.greatminds/history.json` and feeds an exponentially-weighted originality score that shifts UI copy across 5 tone tiers.

**Tech Stack:** Julia, Tachikoma.jl (TUI), HTTP.jl (API calls), JSON3.jl (JSON), TOML (stdlib, config)

**Spec:** `docs/superpowers/specs/2026-04-09-greatminds-tui-design.md`

---

## File Structure

```
GreatMinds/
├── config.toml                  # API keys + settings (user creates from template)
├── config.example.toml          # Template with placeholder values
├── Project.toml                 # Julia package manifest
├── src/
│   ├── GreatMinds.jl            # Module definition, includes, exports, main()
│   ├── types.jl                 # All data types (Screen enum, SearchResult, etc.)
│   ├── config.jl                # load_config(path) → Config
│   ├── similarity.jl            # cosine_similarity, cluster
│   ├── history.jl               # load/save history, compute_originality
│   ├── personality.jl           # tone_tier, tone_copy (all UI copy variants)
│   ├── api/
│   │   ├── xai.jl              # rewrite(), search_similar()
│   │   └── twitter.jl          # fetch_replies()
│   ├── app.jl                   # GreatMindsApp model, update!, view, should_quit
│   └── screens/
│       ├── home.jl              # render_home(model, frame)
│       ├── groking.jl           # render_groking(model, frame)
│       ├── searching.jl         # render_searching(model, frame)
│       ├── results.jl           # render_results(model, frame)
│       └── detail.jl            # render_detail(model, frame)
└── test/
    ├── runtests.jl              # Test runner
    ├── similarity_test.jl       # Cosine similarity + clustering tests
    ├── history_test.jl          # History persistence + originality scoring tests
    ├── personality_test.jl      # Tone tier + copy tests
    └── config_test.jl           # Config loading tests
```

---

### Task 1: Project Scaffold

**Files:**
- Create: `Project.toml`
- Create: `config.example.toml`
- Create: `src/GreatMinds.jl` (stub)
- Create: `test/runtests.jl` (stub)

- [ ] **Step 1: Create Project.toml**

```toml
name = "GreatMinds"
uuid = "generate-with-uuidgen"
version = "0.1.0"

[deps]
HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"
JSON3 = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
Tachikoma = "insert-uuid"

[extras]
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[targets]
test = ["Test"]
```

Note: Generate a real UUID with `using UUIDs; uuid4()`. Look up Tachikoma's UUID from the registry or its Project.toml.

- [ ] **Step 2: Create config.example.toml**

```toml
[xai]
api_key = "xai-YOUR-KEY-HERE"

[twitter]
bearer_token = "YOUR-BEARER-TOKEN-HERE"

[models]
grok = "grok-3"
search = "grok-4-fast-non-reasoning"

[search]
similarity_threshold = 0.9
```

- [ ] **Step 3: Create module stub src/GreatMinds.jl**

```julia
module GreatMinds

using Tachikoma
@tachikoma_app
using HTTP
using JSON3
using TOML
using LinearAlgebra
using Dates

include("types.jl")
include("config.jl")
include("similarity.jl")
include("history.jl")
include("personality.jl")
include("api/xai.jl")
include("api/twitter.jl")
include("screens/home.jl")
include("screens/groking.jl")
include("screens/searching.jl")
include("screens/results.jl")
include("screens/detail.jl")
include("app.jl")

export main

end # module
```

Create placeholder files so the module loads without error. Each placeholder is just a comment:

`src/types.jl`:
```julia
# Types — implemented in Task 2
```

`src/config.jl`:
```julia
# Config — implemented in Task 3
```

`src/similarity.jl`:
```julia
# Similarity — implemented in Task 4
```

`src/history.jl`:
```julia
# History — implemented in Task 5
```

`src/personality.jl`:
```julia
# Personality — implemented in Task 6
```

`src/api/xai.jl`:
```julia
# XAI API — implemented in Task 7
```

`src/api/twitter.jl`:
```julia
# Twitter API — implemented in Task 8
```

`src/screens/home.jl`:
```julia
# Home screen — implemented in Task 10
```

`src/screens/groking.jl`:
```julia
# Groking screen — implemented in Task 11
```

`src/screens/searching.jl`:
```julia
# Searching screen — implemented in Task 12
```

`src/screens/results.jl`:
```julia
# Results screen — implemented in Task 13
```

`src/screens/detail.jl`:
```julia
# Detail screen — implemented in Task 14
```

`src/app.jl`:
```julia
# App model — implemented in Task 9
function main() end
```

- [ ] **Step 4: Create test stub test/runtests.jl**

```julia
using Test

@testset "GreatMinds" begin
    # Tests added in subsequent tasks
end
```

- [ ] **Step 5: Install dependencies and verify module loads**

Run:
```bash
cd /Users/jake/Desktop/GreatMinds
julia --project=. -e 'using Pkg; Pkg.add(["HTTP", "JSON3", "Tachikoma"]); Pkg.resolve()'
julia --project=. -e 'using GreatMinds; println("Module loaded OK")'
```

Expected: "Module loaded OK"

- [ ] **Step 6: Commit**

```bash
git init
echo "config.toml" > .gitignore
echo ".superpowers/" >> .gitignore
git add Project.toml config.example.toml src/ test/ .gitignore docs/
git commit -m "feat: scaffold GreatMinds project with deps and file structure"
```

---

### Task 2: Data Types

**Files:**
- Modify: `src/types.jl`

- [ ] **Step 1: Define all types in src/types.jl**

```julia
@enum Screen home groking searching results detail

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

struct ThoughtRecord
    thought::String
    distilled::String
    max_similarity::Float64
    result_count::Int
    timestamp::String
end

struct Config
    xai_api_key::String
    twitter_bearer_token::String
    grok_model::String
    search_model::String
    similarity_threshold::Float64
end

@enum ToneTier npc normie neutral freethinker insane
```

- [ ] **Step 2: Verify types load**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Types OK")'
```

Expected: "Types OK"

- [ ] **Step 3: Commit**

```bash
git add src/types.jl
git commit -m "feat: define data types for screens, search results, history, and config"
```

---

### Task 3: Config Loading

**Files:**
- Modify: `src/config.jl`
- Create: `test/config_test.jl`
- Modify: `test/runtests.jl`

- [ ] **Step 1: Write failing test in test/config_test.jl**

```julia
using Test
using TOML

# We test load_config directly since it's pure logic
# Include the source files needed
include("../src/types.jl")
include("../src/config.jl")

@testset "Config" begin
    @testset "loads valid config" begin
        path = tempname() * ".toml"
        write(path, """
        [xai]
        api_key = "xai-test-key"

        [twitter]
        bearer_token = "test-bearer"

        [models]
        grok = "grok-3"
        search = "grok-4-fast-non-reasoning"

        [search]
        similarity_threshold = 0.85
        """)
        cfg = load_config(path)
        @test cfg.xai_api_key == "xai-test-key"
        @test cfg.twitter_bearer_token == "test-bearer"
        @test cfg.grok_model == "grok-3"
        @test cfg.search_model == "grok-4-fast-non-reasoning"
        @test cfg.similarity_threshold == 0.85
        rm(path)
    end

    @testset "uses defaults for optional fields" begin
        path = tempname() * ".toml"
        write(path, """
        [xai]
        api_key = "xai-test-key"

        [twitter]
        bearer_token = "test-bearer"
        """)
        cfg = load_config(path)
        @test cfg.grok_model == "grok-3"
        @test cfg.search_model == "grok-4-fast-non-reasoning"
        @test cfg.similarity_threshold == 0.9
        rm(path)
    end

    @testset "errors on missing config file" begin
        @test_throws ErrorException load_config("/nonexistent/path.toml")
    end

    @testset "errors on missing api_key" begin
        path = tempname() * ".toml"
        write(path, """
        [twitter]
        bearer_token = "test-bearer"
        """)
        @test_throws ErrorException load_config(path)
        rm(path)
    end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
julia --project=. test/config_test.jl
```

Expected: FAIL — `load_config` not defined

- [ ] **Step 3: Implement load_config in src/config.jl**

```julia
function load_config(path::String)::Config
    isfile(path) || error("Config file not found: $path")
    data = TOML.parsefile(path)

    xai = get(data, "xai", Dict())
    twitter = get(data, "twitter", Dict())
    models = get(data, "models", Dict())
    search = get(data, "search", Dict())

    haskey(xai, "api_key") || error("Missing [xai] api_key in config")
    haskey(twitter, "bearer_token") || error("Missing [twitter] bearer_token in config")

    Config(
        xai["api_key"],
        twitter["bearer_token"],
        get(models, "grok", "grok-3"),
        get(models, "search", "grok-4-fast-non-reasoning"),
        get(search, "similarity_threshold", 0.9),
    )
end
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
julia --project=. test/config_test.jl
```

Expected: All 4 tests pass

- [ ] **Step 5: Wire into runtests.jl**

Update `test/runtests.jl`:

```julia
using Test

@testset "GreatMinds" begin
    include("config_test.jl")
end
```

- [ ] **Step 6: Commit**

```bash
git add src/config.jl test/config_test.jl test/runtests.jl
git commit -m "feat: config loading from TOML with defaults and validation"
```

---

### Task 4: Cosine Similarity & Clustering

**Files:**
- Modify: `src/similarity.jl`
- Create: `test/similarity_test.jl`
- Modify: `test/runtests.jl`

- [ ] **Step 1: Write failing test in test/similarity_test.jl**

```julia
using Test
using LinearAlgebra

include("../src/similarity.jl")

@testset "Similarity" begin
    @testset "cosine_similarity" begin
        @test cosine_similarity([1.0, 0.0], [1.0, 0.0]) ≈ 1.0
        @test cosine_similarity([1.0, 0.0], [0.0, 1.0]) ≈ 0.0
        @test cosine_similarity([1.0, 0.0], [-1.0, 0.0]) ≈ -1.0
        @test cosine_similarity([1.0, 1.0], [1.0, 1.0]) ≈ 1.0
        @test cosine_similarity([3.0, 4.0], [4.0, 3.0]) ≈ 0.96 atol=0.01
    end

    @testset "cluster groups similar items" begin
        items = [
            (text="a", embedding=[1.0, 0.0, 0.0]),
            (text="b", embedding=[0.99, 0.1, 0.0]),  # similar to a
            (text="c", embedding=[0.0, 0.0, 1.0]),    # different
            (text="d", embedding=[0.0, 0.05, 0.99]),   # similar to c
        ]
        groups = cluster(items, 0.9)
        @test length(groups) == 2
        @test length(groups[1].items) == 2  # a + b
        @test length(groups[2].items) == 2  # c + d
    end

    @testset "cluster with no matches" begin
        items = [
            (text="a", embedding=[1.0, 0.0]),
            (text="b", embedding=[0.0, 1.0]),
        ]
        groups = cluster(items, 0.9)
        @test length(groups) == 2
        @test length(groups[1].items) == 1
        @test length(groups[2].items) == 1
    end

    @testset "cluster with empty input" begin
        groups = cluster([], 0.9)
        @test length(groups) == 0
    end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
julia --project=. test/similarity_test.jl
```

Expected: FAIL — `cosine_similarity` not defined

- [ ] **Step 3: Implement similarity.jl**

```julia
cosine_similarity(a, b) = dot(a, b) / (norm(a) * norm(b))

struct Cluster
    items::Vector
end

function cluster(items, threshold::Float64)
    groups = Cluster[]
    for item in items
        placed = false
        for group in groups
            if cosine_similarity(item.embedding, group.items[1].embedding) >= threshold
                push!(group.items, item)
                placed = true
                break
            end
        end
        if !placed
            push!(groups, Cluster([item]))
        end
    end
    groups
end
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
julia --project=. test/similarity_test.jl
```

Expected: All tests pass

- [ ] **Step 5: Add to runtests.jl and commit**

Add `include("similarity_test.jl")` to `test/runtests.jl` inside the testset.

```bash
git add src/similarity.jl test/similarity_test.jl test/runtests.jl
git commit -m "feat: cosine similarity and embedding-based clustering"
```

---

### Task 5: History Persistence & Originality Scoring

**Files:**
- Modify: `src/history.jl`
- Create: `test/history_test.jl`
- Modify: `test/runtests.jl`

- [ ] **Step 1: Write failing test in test/history_test.jl**

```julia
using Test
using JSON3
using Dates

include("../src/types.jl")
include("../src/history.jl")

@testset "History" begin
    @testset "load_history returns empty for missing file" begin
        h = load_history("/nonexistent/path/history.json")
        @test isempty(h)
    end

    @testset "save and load round-trip" begin
        dir = mktempdir()
        path = joinpath(dir, "history.json")
        records = [
            ThoughtRecord("thought1", "distilled1", 0.96, 5, "2026-04-09T10:00:00"),
            ThoughtRecord("thought2", "distilled2", 0.40, 3, "2026-04-09T11:00:00"),
        ]
        save_history(path, records)
        loaded = load_history(path)
        @test length(loaded) == 2
        @test loaded[1].thought == "thought1"
        @test loaded[1].max_similarity == 0.96
        @test loaded[2].thought == "thought2"
        rm(dir, recursive=true)
    end

    @testset "compute_originality with empty history" begin
        @test compute_originality(ThoughtRecord[]) == 0.5
    end

    @testset "compute_originality with single high-similarity result" begin
        records = [ThoughtRecord("t", "d", 0.96, 5, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        # originality = 1.0 - 0.96 = 0.04
        @test score ≈ 0.04 atol=0.01
    end

    @testset "compute_originality with single low-similarity result" begin
        records = [ThoughtRecord("t", "d", 0.30, 2, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        # originality = 1.0 - 0.30 = 0.70
        @test score ≈ 0.70 atol=0.01
    end

    @testset "compute_originality weights recent more heavily" begin
        records = [
            ThoughtRecord("old", "d", 0.10, 1, "2026-04-08T10:00:00"),  # original (0.9)
            ThoughtRecord("new", "d", 0.95, 5, "2026-04-09T10:00:00"),  # unoriginal (0.05)
        ]
        score = compute_originality(records)
        # Most recent (index 2) has weight 1.0, originality 0.05
        # Older (index 1) has weight 0.7, originality 0.9
        # weighted avg = (0.05 * 1.0 + 0.9 * 0.7) / (1.0 + 0.7) = 0.68 / 1.7 ≈ 0.40
        @test score ≈ 0.40 atol=0.02
    end

    @testset "compute_originality all original → high score" begin
        records = [
            ThoughtRecord("t1", "d", 0.10, 1, "2026-04-07T10:00:00"),
            ThoughtRecord("t2", "d", 0.20, 1, "2026-04-08T10:00:00"),
            ThoughtRecord("t3", "d", 0.15, 1, "2026-04-09T10:00:00"),
        ]
        score = compute_originality(records)
        @test score > 0.7
    end

    @testset "compute_originality all unoriginal → low score" begin
        records = [
            ThoughtRecord("t1", "d", 0.95, 5, "2026-04-07T10:00:00"),
            ThoughtRecord("t2", "d", 0.92, 4, "2026-04-08T10:00:00"),
            ThoughtRecord("t3", "d", 0.98, 6, "2026-04-09T10:00:00"),
        ]
        score = compute_originality(records)
        @test score < 0.1
    end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
julia --project=. test/history_test.jl
```

Expected: FAIL — `load_history` not defined

- [ ] **Step 3: Implement history.jl**

```julia
const HISTORY_DIR = joinpath(homedir(), ".greatminds")
const HISTORY_PATH = joinpath(HISTORY_DIR, "history.json")
const DECAY_FACTOR = 0.7

function load_history(path::String=HISTORY_PATH)::Vector{ThoughtRecord}
    isfile(path) || return ThoughtRecord[]
    data = JSON3.read(read(path, String), Vector{Dict{String,Any}})
    [ThoughtRecord(
        d["thought"],
        d["distilled"],
        d["max_similarity"],
        d["result_count"],
        d["timestamp"],
    ) for d in data]
end

function save_history(path::String, records::Vector{ThoughtRecord})
    dir = dirname(path)
    isdir(dir) || mkpath(dir)
    data = [Dict(
        "thought" => r.thought,
        "distilled" => r.distilled,
        "max_similarity" => r.max_similarity,
        "result_count" => r.result_count,
        "timestamp" => r.timestamp,
    ) for r in records]
    write(path, JSON3.write(data))
end

function save_history(records::Vector{ThoughtRecord})
    save_history(HISTORY_PATH, records)
end

function compute_originality(records::Vector{ThoughtRecord})::Float64
    isempty(records) && return 0.5
    total_weight = 0.0
    weighted_sum = 0.0
    n = length(records)
    for (i, r) in enumerate(records)
        # Most recent record is last in the array (index n), weight = 1.0
        # Second most recent (index n-1), weight = 0.7, etc.
        weight = DECAY_FACTOR ^ (n - i)
        originality = 1.0 - r.max_similarity
        weighted_sum += originality * weight
        total_weight += weight
    end
    weighted_sum / total_weight
end
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
julia --project=. test/history_test.jl
```

Expected: All tests pass

- [ ] **Step 5: Add to runtests.jl and commit**

Add `include("history_test.jl")` to `test/runtests.jl` inside the testset.

```bash
git add src/history.jl test/history_test.jl test/runtests.jl
git commit -m "feat: history persistence and exponentially-weighted originality scoring"
```

---

### Task 6: Personality — Tone Tiers & UI Copy

**Files:**
- Modify: `src/personality.jl`
- Create: `test/personality_test.jl`
- Modify: `test/runtests.jl`

- [ ] **Step 1: Write failing test in test/personality_test.jl**

```julia
using Test

include("../src/types.jl")
include("../src/personality.jl")

@testset "Personality" begin
    @testset "tone_tier thresholds" begin
        @test tone_tier(0.0) == npc
        @test tone_tier(0.15) == npc
        @test tone_tier(0.25) == npc
        @test tone_tier(0.26) == normie
        @test tone_tier(0.40) == normie
        @test tone_tier(0.41) == neutral
        @test tone_tier(0.50) == neutral
        @test tone_tier(0.60) == neutral
        @test tone_tier(0.61) == freethinker
        @test tone_tier(0.75) == freethinker
        @test tone_tier(0.76) == insane
        @test tone_tier(1.0) == insane
    end

    @testset "tone_copy returns strings for all screens and tiers" begin
        for tier in instances(ToneTier)
            prompt = input_prompt(tier)
            @test prompt isa String
            @test length(prompt) > 0

            label = groking_label(tier)
            @test label isa String

            searching_msg = searching_status(tier)
            @test searching_msg isa String

            for is_original in [true, false]
                verdict = results_verdict(tier, is_original)
                @test verdict isa String
            end

            label_str = score_label(tier)
            @test label_str isa String
        end
    end

    @testset "specific copy spot-checks" begin
        @test contains(input_prompt(npc), "NPC")
        @test contains(input_prompt(insane), "psycho") || contains(input_prompt(insane), "original") || contains(input_prompt(insane), "unhinged")
        @test input_prompt(neutral) == "What's your take?"
    end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
julia --project=. test/personality_test.jl
```

Expected: FAIL — `tone_tier` not defined

- [ ] **Step 3: Implement personality.jl**

```julia
function tone_tier(score::Float64)::ToneTier
    score <= 0.25 ? npc :
    score <= 0.40 ? normie :
    score <= 0.60 ? neutral :
    score <= 0.75 ? freethinker :
    insane
end

function input_prompt(tier::ToneTier)::String
    tier == npc         ? "What's your take, NPC?" :
    tier == normie      ? "Go on then, what's your take?" :
    tier == neutral     ? "What's your take?" :
    tier == freethinker ? "What's your take, original?" :
    "What's your take, you absolute psycho?"
end

function groking_label(tier::ToneTier)::String
    tier == npc         ? "Here's what you actually meant (we both know someone already said it)" :
    tier == normie      ? "Here's what you're really saying" :
    tier == neutral     ? "Here's the core idea" :
    tier == freethinker ? "Here's the core idea — let's see if it's really new" :
    "Here's the core idea (brace yourself, this might actually be new)"
end

function searching_status(tier::ToneTier)::String
    tier == npc         ? "Searching for who said it first..." :
    tier == normie      ? "Let's see how common this is..." :
    tier == neutral     ? "Searching X..." :
    tier == freethinker ? "Scanning the timeline for fellow travelers..." :
    "Let's see if anyone else is this unhinged..."
end

function results_verdict(tier::ToneTier, is_original::Bool)::String
    if is_original
        tier == npc         ? "Wait... did you just have an original thought?" :
        tier == normie      ? "Huh, that's actually kind of fresh" :
        tier == neutral     ? "Original take!" :
        tier == freethinker ? "Another original — you're on a streak" :
        "Nobody. You're alone out here. Again."
    else
        tier == npc         ? "Called it. NPC confirmed." :
        tier == normie      ? "Yeah, a few people beat you to it" :
        tier == neutral     ? "Already expressed" :
        tier == freethinker ? "Even originals overlap sometimes" :
        "Even geniuses repeat sometimes"
    end
end

function score_label(tier::ToneTier)::String
    tier == npc         ? "NPC" :
    tier == normie      ? "Normie" :
    tier == neutral     ? "Thinker" :
    tier == freethinker ? "Free Thinker" :
    "Insane"
end
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
julia --project=. test/personality_test.jl
```

Expected: All tests pass

- [ ] **Step 5: Add to runtests.jl and commit**

Add `include("personality_test.jl")` to `test/runtests.jl` inside the testset.

```bash
git add src/personality.jl test/personality_test.jl test/runtests.jl
git commit -m "feat: personality system with 5 tone tiers and screen-specific UI copy"
```

---

### Task 7: XAI API — Rewrite & Search

**Files:**
- Modify: `src/api/xai.jl`

- [ ] **Step 1: Implement rewrite function**

```julia
const XAI_BASE = "https://api.x.ai/v1"

function xai_chat(config::Config, model::String, messages::Vector; tools=nothing, temperature=0.7)
    headers = [
        "Authorization" => "Bearer $(config.xai_api_key)",
        "Content-Type" => "application/json",
    ]
    body = Dict{String,Any}(
        "model" => model,
        "messages" => messages,
        "temperature" => temperature,
    )
    if tools !== nothing
        body["tools"] = tools
    end
    resp = HTTP.post("$XAI_BASE/chat/completions", headers, JSON3.write(body))
    JSON3.read(String(resp.body))
end

const REWRITE_SYSTEM = "You are a rewriter. Take the user's thought and rewrite it as a plain, neutral statement. Remove all wit, humor, sarcasm, metaphor, and style. Keep only the core idea. Return only the rewritten statement, nothing else."

function rewrite(config::Config, thought::String)::String
    messages = [
        Dict("role" => "system", "content" => REWRITE_SYSTEM),
        Dict("role" => "user", "content" => thought),
    ]
    resp = xai_chat(config, config.grok_model, messages; temperature=0.3)
    resp.choices[1].message.content
end
```

- [ ] **Step 2: Implement search_similar function**

```julia
function parse_llm_json(content::String)
    cleaned = content
    m = match(r"```(?:json)?\s*\n?(.*?)\n?\s*```"s, cleaned)
    if m !== nothing
        cleaned = m.captures[1]
    end
    try
        JSON3.read(strip(cleaned))
    catch
        []
    end
end

function search_similar(config::Config, query::String)::Vector{SearchResult}
    prompt = """Search X/Twitter for posts expressing the same core idea as this: "$query"

Return a JSON object with a "posts" array. Each post has: text (exact tweet text), author (handle with @), url (the tweet URL), similarity (float 0.0-1.0 where 1.0=identical idea, 0.9+=same core point). Sort by similarity descending."""

    messages = [Dict("role" => "user", "content" => prompt)]
    tools = [Dict("type" => "x_search")]
    resp = xai_chat(config, config.search_model, messages; tools=tools)
    content = resp.choices[1].message.content

    parsed = parse_llm_json(content)
    posts = if parsed isa AbstractVector
        parsed
    else
        get(parsed, :posts, [])
    end

    [SearchResult(
        let m = match(r"/status/(\d+)", string(get(p, :url, ""))); m !== nothing ? m.captures[1] : "" end,
        string(get(p, :text, "")),
        string(get(p, :author, "")),
        Float64(get(p, :similarity, 0.0)),
        string(get(p, :url, "")),
    ) for p in posts]
end
```

- [ ] **Step 3: Verify API module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("API module OK")'
```

Expected: "API module OK"

- [ ] **Step 4: Commit**

```bash
git add src/api/xai.jl
git commit -m "feat: XAI API integration — rewrite and search_similar via Grok"
```

---

### Task 8: Twitter API — Fetch Replies

**Files:**
- Modify: `src/api/twitter.jl`

- [ ] **Step 1: Implement fetch_replies**

```julia
const TWITTER_API = "https://api.twitter.com/2"

function fetch_replies(config::Config, tweet_id::String)::Vector{ReplyCluster}
    isempty(tweet_id) && return ReplyCluster[]

    headers = ["Authorization" => "Bearer $(config.twitter_bearer_token)"]
    query = "conversation_id:$tweet_id"
    url = "$TWITTER_API/tweets/search/recent?query=$(HTTP.escapeuri(query))&tweet.fields=author_id,text&expansions=author_id&user.fields=username&max_results=100"

    resp = try
        HTTP.get(url, headers)
    catch e
        @warn "Failed to fetch replies" exception=e
        return ReplyCluster[]
    end

    data = JSON3.read(String(resp.body))
    tweets = get(data, :data, [])
    isempty(tweets) && return ReplyCluster[]

    users_list = get(get(data, :includes, Dict()), :users, [])
    users = Dict(string(u.id) => string(u.username) for u in users_list)

    # Build reply list, excluding the original tweet
    replies = [(
        text = string(t.text),
        author = "@" * get(users, string(t.author_id), "unknown"),
    ) for t in tweets if string(t.id) != tweet_id]

    # Since we don't have embeddings for replies, group identical/near-identical text
    # by simple string matching. Each unique reply becomes a cluster.
    clusters = Dict{String,Tuple{String,String,Int}}()
    for r in replies
        key = lowercase(strip(r.text))
        if haskey(clusters, key)
            _, author, count = clusters[key]
            clusters[key] = (r.text, author, count + 1)
        else
            clusters[key] = (r.text, r.author, 1)
        end
    end

    [ReplyCluster(text, author, count) for (_, (text, author, count)) in clusters]
end
```

- [ ] **Step 2: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Twitter API OK")'
```

Expected: "Twitter API OK"

- [ ] **Step 3: Commit**

```bash
git add src/api/twitter.jl
git commit -m "feat: Twitter API reply fetching with text-based clustering"
```

---

### Task 9: App Model & Core Wiring

**Files:**
- Modify: `src/app.jl`

- [ ] **Step 1: Define the model struct and initialization**

```julia
mutable struct GreatMindsApp <: Model
    # Screen state
    screen::Screen
    quit::Bool

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
    replies_loading::Bool

    # Personality
    history::Vector{ThoughtRecord}
    originality_score::Float64

    # Infra
    config::Config
    task_queue_ref::TaskQueue
    notify::Union{Function,Nothing}
end

function GreatMindsApp(config::Config)
    history = load_history()
    score = compute_originality(history)
    GreatMindsApp(
        home, false,
        TextArea(label=""),
        "", "", false,
        SearchResult[], false, 0,
        1,
        Phrasing[], ReplyCluster[], 0, false,
        history, score,
        config, TaskQueue(), nothing,
    )
end
```

- [ ] **Step 2: Implement Tachikoma lifecycle methods**

```julia
function set_wake!(m::GreatMindsApp, notify::Function)
    m.notify = notify
    m.task_queue_ref = TaskQueue(on_ready=notify)
end

task_queue(m::GreatMindsApp) = m.task_queue_ref

should_quit(m::GreatMindsApp) = m.quit

function view(m::GreatMindsApp, f::Frame)
    # Main content area + status bar
    layout = Layout(Vertical, [Fill(), Fixed(1)])
    rects = split_layout(layout, f.area)

    # Dispatch to screen renderer
    if m.screen == home
        render_home(m, rects[1], f.buffer)
    elseif m.screen == groking
        render_groking(m, rects[1], f.buffer)
    elseif m.screen == searching
        render_searching(m, rects[1], f.buffer)
    elseif m.screen == results
        render_results(m, rects[1], f.buffer)
    elseif m.screen == detail
        render_detail(m, rects[1], f.buffer)
    end

    # Status bar with originality score
    render_status_bar(m, rects[2], f.buffer)
end

function render_status_bar(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    label = score_label(tier)
    score_str = string(round(m.originality_score, digits=2))

    # Build gauge characters: filled vs empty out of 10
    filled = round(Int, m.originality_score * 10)
    gauge = "█"^filled * "░"^(10 - filled)

    bar = StatusBar(
        left=[Span("[$label $gauge $score_str]", tstyle(:accent, bold=true))],
        right=[Span(status_bar_keys(m.screen), tstyle(:text_dim))],
        style=tstyle(:text_dim),
    )
    render(bar, area, buf)
end

function status_bar_keys(screen::Screen)::String
    screen == home      ? "Esc: quit  Enter: grok it" :
    screen == groking   ? "Esc: back  R: regenerate  Enter: search" :
    screen == searching ? "Esc: cancel" :
    screen == results   ? "Esc: back  ↑↓: navigate  Enter: detail" :
    "Esc: back  ↑↓: scroll  O: open in browser"
end
```

- [ ] **Step 3: Implement update! dispatch**

```julia
function update!(m::GreatMindsApp, e::KeyEvent)
    e.action == key_press || e.action == key_repeat || return

    if m.screen == home
        update_home!(m, e)
    elseif m.screen == groking
        update_groking!(m, e)
    elseif m.screen == searching
        update_searching!(m, e)
    elseif m.screen == results
        update_results!(m, e)
    elseif m.screen == detail
        update_detail!(m, e)
    end
end

function update!(m::GreatMindsApp, e::TaskEvent)
    if e.id == :rewrite
        m.distilled_text = e.value::String
        m.groking_loading = false
    elseif e.id == :search
        m.search_results = e.value::Vector{SearchResult}
        m.searching = false
        m.search_count = length(m.search_results)
        # Record to history
        max_sim = isempty(m.search_results) ? 0.0 : maximum(r.similarity for r in m.search_results)
        record = ThoughtRecord(
            m.original_text, m.distilled_text, max_sim,
            length(m.search_results), Dates.format(now(), "yyyy-mm-ddTHH:MM:SS"),
        )
        push!(m.history, record)
        save_history(m.history)
        m.originality_score = compute_originality(m.history)
        m.screen = results
    elseif e.id == :replies
        m.clustered_replies = e.value::Vector{ReplyCluster}
        m.replies_loading = false
    end
end
```

- [ ] **Step 4: Implement main entry point**

```julia
function main(config_path::String="config.toml")
    config = load_config(config_path)
    model = GreatMindsApp(config)
    app(model)
end
```

- [ ] **Step 5: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("App model OK")'
```

Expected: "App model OK"

- [ ] **Step 6: Commit**

```bash
git add src/app.jl
git commit -m "feat: app model with screen dispatch, status bar, async task handling, and history recording"
```

---

### Task 10: Home Screen

**Files:**
- Modify: `src/screens/home.jl`

- [ ] **Step 1: Implement render_home**

```julia
function render_home(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    prompt = input_prompt(tier)

    layout = Layout(Vertical, [Fixed(3), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Input area with prompt label
    m.input.label = prompt
    block = Block(title="Your thought", border_style=tstyle(:border))
    inner = render(block, rects[2], buf)
    render(m.input, inner, buf)
end
```

- [ ] **Step 2: Implement update_home!**

```julia
function update_home!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.quit = true
    elseif e.key == :enter && !isempty(strip(value(m.input)))
        m.original_text = strip(value(m.input))
        m.groking_loading = true
        m.distilled_text = ""
        m.screen = groking
        # Fire async rewrite
        spawn_task!(m.task_queue_ref, :rewrite) do
            rewrite(m.config, m.original_text)
        end
    else
        handle_key!(m.input, e)
    end
end
```

- [ ] **Step 3: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Home screen OK")'
```

Expected: "Home screen OK"

- [ ] **Step 4: Manual test — launch app and see home screen**

Create `config.toml` from `config.example.toml` with valid keys, then:

Run:
```bash
julia --project=. -e 'using GreatMinds; GreatMinds.main()'
```

Expected: TUI launches showing "GreatMinds" title, prompt text, and input area. Esc quits.

- [ ] **Step 5: Commit**

```bash
git add src/screens/home.jl
git commit -m "feat: home screen with TextArea input and personality-driven prompt"
```

---

### Task 11: Groking Screen

**Files:**
- Modify: `src/screens/groking.jl`

- [ ] **Step 1: Implement render_groking**

```julia
function render_groking(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    label = groking_label(tier)

    layout = Layout(Vertical, [Fixed(3), Fixed(1), Fill(), Fixed(1), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Groking", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Label
    render(Paragraph(label; alignment=align_center), rects[2], buf)

    # Original text (dimmed, left border)
    orig_block = Block(title="Your thought", border_style=tstyle(:text_dim))
    orig_inner = render(orig_block, rects[3], buf)
    render(Paragraph(m.original_text; wrap=word_wrap, style=tstyle(:text_dim)), orig_inner, buf)

    # Distilled text or loading spinner
    if m.groking_loading
        dist_block = Block(title="Distilling...", border_style=tstyle(:accent))
        dist_inner = render(dist_block, rects[5], buf)
        render(Paragraph("Groking your thought..."; wrap=word_wrap, style=tstyle(:text_dim, italic=true)), dist_inner, buf)
    else
        dist_block = Block(title="Core idea", border_style=tstyle(:accent))
        dist_inner = render(dist_block, rects[5], buf)
        render(Paragraph(m.distilled_text; wrap=word_wrap, style=tstyle(:text_bright)), dist_inner, buf)
    end
end
```

- [ ] **Step 2: Implement update_groking!**

```julia
function update_groking!(m::GreatMindsApp, e::KeyEvent)
    m.groking_loading && return  # block input while loading

    if e.key == :escape
        m.screen = home
    elseif e.key == :enter && !isempty(m.distilled_text)
        # Approve and search
        m.searching = true
        m.search_results = SearchResult[]
        m.search_count = 0
        m.selected_result = 1
        m.screen = searching
        spawn_task!(m.task_queue_ref, :search) do
            search_similar(m.config, m.distilled_text)
        end
    elseif e.key == :char && lowercase(e.char) == 'r'
        # Regenerate
        m.groking_loading = true
        m.distilled_text = ""
        spawn_task!(m.task_queue_ref, :rewrite) do
            rewrite(m.config, m.original_text)
        end
    end
end
```

- [ ] **Step 3: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Groking screen OK")'
```

Expected: "Groking screen OK"

- [ ] **Step 4: Commit**

```bash
git add src/screens/groking.jl
git commit -m "feat: groking screen with async rewrite, regenerate, and approval flow"
```

---

### Task 12: Searching Screen

**Files:**
- Modify: `src/screens/searching.jl`

- [ ] **Step 1: Implement render_searching**

```julia
function render_searching(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    status = searching_status(tier)

    # Center the content
    content_area = center(area, min(50, area.width), 7)

    layout = Layout(Vertical, [Fixed(3), Fixed(1), Fixed(1), Fixed(1)])
    rects = split_layout(layout, content_area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Searching", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Status message
    render(Paragraph(status; alignment=align_center, style=tstyle(:accent)), rects[2], buf)

    # Progress gauge (indeterminate — pulse between 0.3 and 0.7)
    gauge = Gauge(0.5; filled_style=tstyle(:accent), label="")
    render(gauge, rects[3], buf)

    # Count
    count_msg = m.search_count > 0 ? "Found $(m.search_count) results so far..." : ""
    render(Paragraph(count_msg; alignment=align_center, style=tstyle(:text_dim)), rects[4], buf)
end
```

- [ ] **Step 2: Implement update_searching!**

```julia
function update_searching!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        # Cancel search and go back
        m.searching = false
        m.screen = groking
    end
end
```

- [ ] **Step 3: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Searching screen OK")'
```

Expected: "Searching screen OK"

- [ ] **Step 4: Commit**

```bash
git add src/screens/searching.jl
git commit -m "feat: searching screen with gauge and personality-driven status"
```

---

### Task 13: Results Screen

**Files:**
- Modify: `src/screens/results.jl`

- [ ] **Step 1: Implement render_results**

```julia
function render_results(m::GreatMindsApp, area::Rect, buf::Buffer)
    tier = tone_tier(m.originality_score)
    threshold = m.config.similarity_threshold
    has_duplicates = any(r.similarity >= threshold for r in m.search_results)
    verdict = results_verdict(tier, !has_duplicates)

    layout = Layout(Vertical, [Fixed(3), Fixed(2), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Results ($(length(m.search_results)) found)", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Verdict banner
    verdict_style = has_duplicates ? tstyle(:error, bold=true) : tstyle(:success, bold=true)
    dup_count = count(r -> r.similarity >= threshold, m.search_results)
    suffix = has_duplicates ? " — $dup_count posts ≥$(round(Int, threshold*100))% similar" : ""
    render(Paragraph([Span(verdict, verdict_style), Span(suffix, tstyle(:text_dim))]; alignment=align_center), rects[2], buf)

    # Results list
    if isempty(m.search_results)
        render(Paragraph("No results found."; alignment=align_center, style=tstyle(:text_dim)), rects[3], buf)
    else
        items = [format_result_line(r, threshold, area.width) for r in m.search_results]
        list = SelectableList(items;
            selected=m.selected_result,
            highlight_style=tstyle(:accent, bold=true),
            block=Block(border_style=tstyle(:border)),
        )
        render(list, rects[3], buf)
    end
end

function format_result_line(r::SearchResult, threshold::Float64, width::Int)::String
    pct = string(round(Int, r.similarity * 100)) * "%"
    badge = r.similarity >= threshold ? "[$pct]" : "[$pct]"
    author = r.author
    max_text = max(10, width - length(badge) - length(author) - 6)
    text = length(r.text) > max_text ? r.text[1:max_text] * "…" : r.text
    "$badge $author $text"
end
```

- [ ] **Step 2: Implement update_results!**

```julia
function update_results!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.screen = groking
    elseif e.key == :enter && !isempty(m.search_results)
        # Enter detail view
        m.detail_scroll = 0
        m.similar_phrasings = Phrasing[]
        m.clustered_replies = ReplyCluster[]
        m.replies_loading = true
        m.screen = detail

        # Fetch replies async
        result = m.search_results[m.selected_result]
        spawn_task!(m.task_queue_ref, :replies) do
            fetch_replies(m.config, result.id)
        end

        # Build similar phrasings from other high-similarity results
        threshold = m.config.similarity_threshold
        m.similar_phrasings = [
            Phrasing(r.text, r.author)
            for (i, r) in enumerate(m.search_results)
            if i != m.selected_result && r.similarity >= threshold
        ]
    elseif e.key == :up && m.selected_result > 1
        m.selected_result -= 1
    elseif e.key == :down && m.selected_result < length(m.search_results)
        m.selected_result += 1
    end
end
```

- [ ] **Step 3: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Results screen OK")'
```

Expected: "Results screen OK"

- [ ] **Step 4: Commit**

```bash
git add src/screens/results.jl
git commit -m "feat: results screen with similarity badges, verdict, and selectable list"
```

---

### Task 14: Detail Screen

**Files:**
- Modify: `src/screens/detail.jl`

- [ ] **Step 1: Implement render_detail**

```julia
function render_detail(m::GreatMindsApp, area::Rect, buf::Buffer)
    result = m.search_results[m.selected_result]
    threshold = m.config.similarity_threshold
    pct = string(round(Int, result.similarity * 100)) * "%"

    layout = Layout(Vertical, [Fixed(3), Fixed(6), Fill()])
    rects = split_layout(layout, area)

    # Title
    title = Paragraph(
        [Span("GreatMinds", tstyle(:accent, bold=true)),
         Span(" — Detail", tstyle(:text_dim))];
        alignment=align_center,
    )
    render(title, rects[1], buf)

    # Tweet block
    tweet_block = Block(
        title="$(result.author) · $pct",
        border_style=result.similarity >= threshold ? tstyle(:error) : tstyle(:primary),
    )
    tweet_inner = render(tweet_block, rects[2], buf)
    tweet_layout = Layout(Vertical, [Fill(), Fixed(1)])
    tweet_rects = split_layout(tweet_layout, tweet_inner)
    render(Paragraph(result.text; wrap=word_wrap), tweet_rects[1], buf)
    render(Paragraph(result.url; style=tstyle(:text_dim)), tweet_rects[2], buf)

    # Bottom section: phrasings + replies
    bottom_layout = Layout(Vertical, [Fixed(1), Fill(), Fixed(1), Fill()])
    bottom_rects = split_layout(bottom_layout, rects[3])

    # Similar phrasings
    phrasing_label = "Similar phrasings ($(length(m.similar_phrasings)))"
    render(Paragraph(phrasing_label; style=tstyle(:text_dim)), bottom_rects[1], buf)

    if !isempty(m.similar_phrasings)
        phrasing_block = Block(border_style=tstyle(:accent))
        phrasing_inner = render(phrasing_block, bottom_rects[2], buf)
        lines = [Span(""$(p.text)" $(p.author)\n", tstyle(:text)) for p in m.similar_phrasings]
        render(Paragraph(lines; wrap=word_wrap, scroll_offset=m.detail_scroll), phrasing_inner, buf)
    end

    # Clustered replies
    if m.replies_loading
        reply_label = "Replies (loading...)"
    else
        reply_label = "Replies ($(length(m.clustered_replies)) clusters)"
    end
    render(Paragraph(reply_label; style=tstyle(:text_dim)), bottom_rects[3], buf)

    if !isempty(m.clustered_replies)
        reply_block = Block(border_style=tstyle(:border))
        reply_inner = render(reply_block, bottom_rects[4], buf)
        reply_lines = Span[]
        for rc in m.clustered_replies
            count_str = rc.similar_count > 1 ? " (+$(rc.similar_count - 1) similar)" : ""
            push!(reply_lines, Span("$(rc.author)$count_str\n", tstyle(:text_dim)))
            push!(reply_lines, Span("  $(rc.text)\n\n", tstyle(:text)))
        end
        render(Paragraph(reply_lines; wrap=word_wrap), reply_inner, buf)
    end
end
```

- [ ] **Step 2: Implement update_detail!**

```julia
function update_detail!(m::GreatMindsApp, e::KeyEvent)
    if e.key == :escape
        m.screen = results
    elseif e.key == :up && m.detail_scroll > 0
        m.detail_scroll -= 1
    elseif e.key == :down
        m.detail_scroll += 1
    elseif e.key == :char && lowercase(e.char) == 'o'
        # Open tweet URL in system browser
        result = m.search_results[m.selected_result]
        if !isempty(result.url)
            @static if Sys.isapple()
                run(`open $(result.url)`, wait=false)
            elseif Sys.islinux()
                run(`xdg-open $(result.url)`, wait=false)
            end
        end
    end
end
```

- [ ] **Step 3: Verify module compiles**

Run:
```bash
julia --project=. -e 'using GreatMinds; println("Detail screen OK")'
```

Expected: "Detail screen OK"

- [ ] **Step 4: Commit**

```bash
git add src/screens/detail.jl
git commit -m "feat: detail screen with tweet, similar phrasings, clustered replies, and browser open"
```

---

### Task 15: End-to-End Integration & Manual Testing

**Files:**
- No new files — testing the full flow

- [ ] **Step 1: Create config.toml with real keys**

Copy `config.example.toml` to `config.toml` and fill in real API keys:

```bash
cp config.example.toml config.toml
# Edit config.toml with real XAI and Twitter keys
```

- [ ] **Step 2: Run all unit tests**

Run:
```bash
julia --project=. test/runtests.jl
```

Expected: All tests pass (config, similarity, history, personality)

- [ ] **Step 3: Launch app and test full flow**

Run:
```bash
julia --project=. -e 'using GreatMinds; GreatMinds.main()'
```

Manual test checklist:
1. Home screen shows with personality prompt and originality gauge in status bar
2. Type a thought, press Enter → transitions to Groking
3. Groking shows loading, then original + distilled text
4. Press R → regenerates distilled text
5. Press Enter → transitions to Searching screen with gauge
6. Search completes → transitions to Results with verdict and list
7. Arrow keys navigate results list
8. Enter → drills into Detail showing tweet, phrasings, replies
9. O → opens tweet URL in browser
10. Esc chain: Detail → Results → Groking → Home → quit
11. After multiple searches, originality score updates and UI copy shifts

- [ ] **Step 4: Verify history persistence**

Run app, complete a search, quit, then:

```bash
cat ~/.greatminds/history.json
```

Expected: JSON array with the thought record

Relaunch — originality score should reflect the saved history.

- [ ] **Step 5: Fix any issues found during manual testing**

Address any rendering, navigation, or API issues discovered in steps 3-4.

- [ ] **Step 6: Final commit**

```bash
git add -A
git commit -m "feat: end-to-end integration — full search flow with personality system"
```

---

## Summary

| Task | Component | Files | Tests |
|------|-----------|-------|-------|
| 1 | Project scaffold | 15 files | compile check |
| 2 | Data types | types.jl | compile check |
| 3 | Config loading | config.jl | 4 tests |
| 4 | Similarity | similarity.jl | 4 tests |
| 5 | History | history.jl | 7 tests |
| 6 | Personality | personality.jl | 3 test groups |
| 7 | XAI API | api/xai.jl | compile check |
| 8 | Twitter API | api/twitter.jl | compile check |
| 9 | App model | app.jl | compile check |
| 10 | Home screen | screens/home.jl | manual |
| 11 | Groking screen | screens/groking.jl | manual |
| 12 | Searching screen | screens/searching.jl | manual |
| 13 | Results screen | screens/results.jl | manual |
| 14 | Detail screen | screens/detail.jl | manual |
| 15 | Integration | — | full manual flow |
