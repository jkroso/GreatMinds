const XAI_BASE = "https://api.x.ai/v1"

const XAI_HEADERS(config) = [
    "Authorization" => "Bearer $(config.xai_api_key)",
    "Content-Type" => "application/json",
]

"""Extract a user-facing message from an API error body (JSON or plain text)."""
function extract_api_error_message(body::AbstractString)::String
    isempty(body) && return ""
    try
        j = JSON3.read(body)
        err = get(j, :error, nothing)
        err === nothing && (err = get(j, :message, nothing))
        err === nothing && return strip(String(body))
        return err isa AbstractString ? String(err) : string(err)
    catch
        return strip(String(body))
    end
end

"""Format exceptions for display in the TUI (HTTP status errors include API body text)."""
function format_api_error(e)::String
    if e isa HTTP.StatusError
        body = try
            String(e.response.body)
        catch
            ""
        end
        msg = extract_api_error_message(body)
        isempty(msg) && (msg = HTTP.statustext(e.status))
        return "API error $(e.status): $msg"
    else
        return sprint(showerror, e)
    end
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

function response_text(resp)::String
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
    return content
end

function search_similar(config::Config, query::String)::Vector{SearchResult}
    prompt = """Search X for posts expressing the same core idea as this: "$query"

    Return a JSON object with a "posts" array. Each post has: text (exact tweet text), author (handle with @), url (the tweet URL), similarity (float 0.0-1.0 where 1.0=identical idea exoressed in a similar way, 0.5+=similar core point, 0.95+=same core point). Sort by similarity descending.
    """

    input = [Dict("type" => "message", "role" => "user", "content" => prompt)]
    # Let HTTP/API failures propagate — Tachikoma delivers them as TaskEvent values
    # and the TUI surfaces them instead of treating them as empty results.
    resp = xai_responses(config, config.model, input; tools=["x_search", "code_execution"])
    content = response_text(resp)

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
