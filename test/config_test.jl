using Test
using TOML

# Include source files needed
include("../src/types.jl")
include("../src/config.jl")

@testset "Config" begin
    @testset "loads valid config" begin
        path = tempname() * ".toml"
        write(path, """
        [xai]
        api_key = "xai-test-key"
        model = "grok-3"

        [search]
        similarity_threshold = 0.85
        """)
        cfg = load_config(path)
        @test cfg.xai_api_key == "xai-test-key"
        @test cfg.model == "grok-3"
        @test cfg.similarity_threshold == 0.85
        rm(path)
    end

    @testset "uses defaults for optional fields" begin
        path = tempname() * ".toml"
        write(path, """
        [xai]
        api_key = "xai-test-key"
        """)
        cfg = load_config(path)
        @test cfg.model == "grok-4.20-0309-reasoning"
        @test cfg.similarity_threshold == 0.9
        rm(path)
    end

    @testset "picks up XAI_API_KEY from env" begin
        path = tempname() * ".toml"
        write(path, """
        [models]
        grok = "grok-3"
        """)
        old = get(ENV, "XAI_API_KEY", nothing)
        try
            ENV["XAI_API_KEY"] = "xai-from-env"
            cfg = load_config(path)
            @test cfg.xai_api_key == "xai-from-env"
        finally
            if old === nothing
                delete!(ENV, "XAI_API_KEY")
            else
                ENV["XAI_API_KEY"] = old
            end
        end
        rm(path)
    end

    @testset "uses env var with missing config file" begin
        old = get(ENV, "XAI_API_KEY", nothing)
        try
            ENV["XAI_API_KEY"] = "xai-from-env"
            cfg = load_config("/nonexistent/path.toml")
            @test cfg.xai_api_key == "xai-from-env"
            @test cfg.model == "grok-4.20-0309-reasoning"
        finally
            if old === nothing
                delete!(ENV, "XAI_API_KEY")
            else
                ENV["XAI_API_KEY"] = old
            end
        end
    end

    @testset "errors on missing api_key without env" begin
        path = tempname() * ".toml"
        write(path, """
        [models]
        grok = "grok-3"
        """)
        old = get(ENV, "XAI_API_KEY", nothing)
        try
            delete!(ENV, "XAI_API_KEY")
            @test_throws ErrorException load_config(path)
        finally
            if old !== nothing
                ENV["XAI_API_KEY"] = old
            end
        end
        rm(path)
    end

    @testset "errors on missing config file and missing env" begin
        old = get(ENV, "XAI_API_KEY", nothing)
        try
            delete!(ENV, "XAI_API_KEY")
            @test_throws ErrorException load_config("/nonexistent/path.toml")
        finally
            if old !== nothing
                ENV["XAI_API_KEY"] = old
            end
        end
    end
end
