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
    resp = try
        xai_chat(config, config.grok_model, messages; temperature=0.3)
    catch e
        @warn "Grok rewrite failed" exception=e
        return thought  # fall back to original text
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
    prompt = """Search X/Twitter for posts expressing the same core idea as this: "$query"

Return a JSON object with a "posts" array. Each post has: text (exact tweet text), author (handle with @), url (the tweet URL), similarity (float 0.0-1.0 where 1.0=identical idea, 0.9+=same core point). Sort by similarity descending."""

    messages = [Dict("role" => "user", "content" => prompt)]
    tools = [Dict("type" => "x_search")]
    resp = try
        xai_chat(config, config.search_model, messages; tools=tools)
    catch e
        @warn "Grok search failed" exception=e
        return SearchResult[]
    end
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
