function fetch_replies(config::Config, tweet_id::String)::Vector{ReplyCluster}
    isempty(tweet_id) && return ReplyCluster[]

    prompt = """Find replies to this tweet: https://x.com/i/status/$tweet_id

Return a JSON object with a "replies" array. Each reply has: text (the reply text), author (handle with @), similar_count (number of other replies expressing the same point, minimum 1)."""

    input = [Dict("type" => "message", "role" => "user", "content" => prompt)]
    resp = try
        xai_responses(config, config.model, input; tools=["x_search"])
    catch e
        @warn "Failed to fetch replies via Grok" exception=e
        return ReplyCluster[]
    end

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

    isempty(content) && return ReplyCluster[]

    parsed = parse_llm_json(content)
    replies = if parsed isa AbstractVector
        parsed
    else
        get(parsed, :replies, [])
    end

    [ReplyCluster(
        string(get(r, :text, "")),
        string(get(r, :author, "")),
        Int(get(r, :similar_count, 1)),
    ) for r in replies]
end
