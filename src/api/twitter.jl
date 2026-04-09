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

    replies = [(
        text = string(t.text),
        author = "@" * get(users, string(t.author_id), "unknown"),
    ) for t in tweets if string(t.id) != tweet_id]

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
