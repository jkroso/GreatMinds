const XAI_BASE = "https://api.x.ai/v1"

const XAI_HEADERS(config) = [
    "Authorization" => "Bearer $(config.xai_api_key)",
    "Content-Type" => "application/json",
]

# Chat Completions API — for rewrite (no special tools needed)
function xai_chat(config::Config, model::String, messages::Vector; temperature=0.7)
    body = Dict{String,Any}(
        "model" => model,
        "messages" => messages,
        "temperature" => temperature,
    )
    resp = HTTP.post("$XAI_BASE/chat/completions", XAI_HEADERS(config), JSON3.write(body))
    JSON3.read(String(resp.body))
end

# Responses API — for search (supports x_search tool)
function xai_responses(config::Config, model::String, input::Vector; tools=[], temperature=0.7, instructions=nothing)
    body = Dict{String,Any}(
        "model" => model,
        "input" => input,
        "temperature" => temperature,
        "stream" => false,
    )
    !isempty(tools) && (body["tools"] = [t isa Dict ? t : Dict("type" => t) for t in tools])
    instructions !== nothing && (body["instructions"] = instructions)
    resp = HTTP.post("$XAI_BASE/responses", XAI_HEADERS(config), JSON3.write(body))
    JSON3.read(String(resp.body))
end

const REWRITE_SYSTEM = "You are a rewriter. Take the user's thought and rewrite it as a plain, neutral statement. Remove all wit, humor, sarcasm, metaphor, and style. Keep only the core idea. Return only the rewritten statement, nothing else."

function rewrite(config::Config, thought::String)::String
    messages = [
        Dict("role" => "system", "content" => REWRITE_SYSTEM),
        Dict("role" => "user", "content" => thought),
    ]
    resp = try
        xai_chat(config, config.model, messages; temperature=0.3)
    catch e
        @warn "Grok rewrite failed" exception=e
        return thought
    end
    resp.choices[1].message.content
end

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
    prompt = """Search X for posts expressing the same core idea as this: "$query"

    Return a JSON object with a "posts" array. Each post has: text (exact tweet text), author (handle with @), url (the tweet URL), similarity (float 0.0-1.0 where 1.0=identical idea exoressed in a similar way, 0.5+=similar core point, 0.95+=same core point). Sort by similarity descending.
    """

    input = [Dict("type" => "message", "role" => "user", "content" => prompt)]
    resp = try
        xai_responses(config, config.model, input; tools=["x_search", "code_execution"])
    catch e
        @warn "Grok search failed" exception=e
        return SearchResult[]
    end

    # Responses API returns output array — find the text content
    content = ""
    for item in get(resp, :output, [])
        if get(item, :type, "") == "message"
            for part in get(item, :content, [])
                if get(part, :type, "") == "output_text"
                    content *= get(part, :text, "")
                end
            end
        end
    end

    isempty(content) && return SearchResult[]

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
