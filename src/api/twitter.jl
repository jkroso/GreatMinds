"""
Detect whether `text` is exactly a tweet URL (twitter.com or x.com).
Returns `(tweet_id, normalized_url)` or `nothing`.
"""
function parse_tweet_url(text::AbstractString)::Union{Nothing,Tuple{String,String}}
    s = strip(text)
    m = match(r"^https?://(?:www\.|mobile\.)?(?:twitter|x)\.com/[\w]+/status(?:es)?/(\d+)(?:/[^\s?#]*)?(?:[?#][^\s]*)?$"i, s)
    m === nothing && return nothing
    return (String(m.captures[1]), String(m.match))
end

"""
Fetch a tweet's text/author and clustered replies in a single Grok call.
Returns `(SearchResult|nothing, Vector{ReplyCluster})`.
"""
function fetch_tweet_and_replies(config::Config, tweet_id::String)
    isempty(tweet_id) && return (nothing, ReplyCluster[])

    url = "https://x.com/i/status/$tweet_id"
    prompt = """For the tweet at $url:

Return a JSON object with:
- "tweet": { "text": the tweet text, "author": handle with @ }
- "replies": array of objects, each with text (the reply text), author (handle with @), similar_count (number of other replies expressing the same point, minimum 1)."""

    input = [Dict("type" => "message", "role" => "user", "content" => prompt)]
    resp = try
        xai_responses(config, config.model, input; tools=["x_search"])
    catch e
        @warn "Failed to fetch tweet via Grok" exception=e
        return (nothing, ReplyCluster[])
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

    isempty(content) && return (nothing, ReplyCluster[])

    parsed = parse_llm_json(content)
    parsed isa AbstractDict || return (nothing, ReplyCluster[])

    tweet_obj = get(parsed, :tweet, Dict())
    sr = SearchResult(
        tweet_id,
        string(get(tweet_obj, :text, "")),
        string(get(tweet_obj, :author, "")),
        1.0,
        url,
    )

    raw_replies = get(parsed, :replies, [])
    replies = [ReplyCluster(
        string(get(r, :text, "")),
        string(get(r, :author, "")),
        Int(get(r, :similar_count, 1)),
    ) for r in raw_replies]

    return (sr, replies)
end

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
