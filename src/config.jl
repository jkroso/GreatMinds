function load_config(path::String)::Config
    isfile(path) || error("Config file not found: $path")
    data = TOML.parsefile(path)

    xai = get(data, "xai", Dict())
    models = get(data, "models", Dict())
    search = get(data, "search", Dict())

    haskey(xai, "api_key") || error("Missing [xai] api_key in config")

    Config(
        xai["api_key"],
        get(models, "grok", "grok-3"),
        get(models, "search", "grok-4-fast-non-reasoning"),
        get(search, "similarity_threshold", 0.9),
    )
end
