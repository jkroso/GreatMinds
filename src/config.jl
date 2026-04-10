function load_config(path::String)::Config
    data = isfile(path) ? TOML.parsefile(path) : Dict()

    xai = get(data, "xai", Dict())
    models = get(data, "models", Dict())
    search = get(data, "search", Dict())

    api_key = get(xai, "api_key", get(ENV, "XAI_API_KEY", ""))
    isempty(api_key) && error("Missing XAI API key. Set [xai] api_key in config or XAI_API_KEY env var")

    Config(
        api_key,
        get(models, "grok", "grok-4.20-0309-reasoning"),
        get(models, "search", "grok-4.20-0309-reasoning"),
        get(search, "similarity_threshold", 0.9),
    )
end
