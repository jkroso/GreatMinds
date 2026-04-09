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
