# GreatMinds

A terminal UI for finding out if your thoughts are original. Type a take, and GreatMinds uses Grok to search X for similar posts -- because great minds think alike.

## Why

I wrote this because X hasn’t really been getting any better lately in terms of showing me things that I find interesting. They recently made their API cheaper so I got excited and decided to have a crack at building a better interface. This is not that. The API is still absurdly expensive so you can’t do any large scale analysis on your own machine. But I did discover that Grok has an `x_search` tool which enables me to do a fraction of what I wanted. This tool is that fraction. It’s fun to play with and works well enough. I’ve already found 1 new follow that I never would have found without this tool.

## Thoughts on X

Playing with it made me realise just how reputation centered X is. The way to build a big following on X seems to be to consistently have slightly above average takes on all current affairs as soon as they happen. Too far above average and you will go over people's heads. It basically rewards wit and prolificness, not intellectual depth. But there are many brilliant people on X, we all know they are there because we stumble upon them regularly. 

The reason X has the ability to follow people is just as a heuristic for good content. Good people tend to produce good content. But it’s a very noisy signal. 

I’d like to see X become a graph of unique takes. That’s not to say there is no place for wit. But that the witty version of a take and the plain version should be grouped together. So any engagement with one is also engagement with the other. They are the same object just presented differently to different people. Including people who speak different languages. This grouping mechanism should be applied to the replies too so when you open the replies each reply is unique. On current X when I open the replies to a popular post I scroll quickly because there is so much crap which I’m sure causes me to miss some good replies. I rarely reply to popular posts because I know my take won’t be seen anyway if the post is more than a few minutes old already.

Which version of a post you see by default, be it witty, kind, unhinged would just be a matter of preference. The key insight here is that every row on our X feed or the replies to a post should be semantically unique. That would make X much more rewarding to use. This might sound hard to implement but it’s actually very easy to do using semantic embeddings. Unfortunately this can’t be done from outside X with the current API pricing.

## How it works

1. **Type your take** -- enter whatever's on your mind
2. **Groking** -- Grok distills your thought down to its core idea, stripping out wit, style, and rhetoric. If grok gets the essence wrong then you should reword your input until Grok’s response isn’t lossy. Grok will be doing the searching so you need to write for Grok to understand.
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

Then configure your API key (either way works):

```bash
# Option A: config file
mkdir -p ~/.greatminds
cat > ~/.greatminds/config.toml << 'EOF'
[xai]
api_key = "xai-YOUR-KEY-HERE"
EOF

# Option B: environment variable
export XAI_API_KEY="xai-YOUR-KEY-HERE"
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
