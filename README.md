# GreatMinds

Whenever I draft a post I wonder how many other people have had the same basic idea. This tool enables you to see them

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
model = "grok-4.5"

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
