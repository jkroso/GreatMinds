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

        [twitter]
        bearer_token = "test-bearer"

        [models]
        grok = "grok-3"
        search = "grok-4-fast-non-reasoning"

        [search]
        similarity_threshold = 0.85
        """)
        cfg = load_config(path)
        @test cfg.xai_api_key == "xai-test-key"
        @test cfg.twitter_bearer_token == "test-bearer"
        @test cfg.grok_model == "grok-3"
        @test cfg.search_model == "grok-4-fast-non-reasoning"
        @test cfg.similarity_threshold == 0.85
        rm(path)
    end

    @testset "uses defaults for optional fields" begin
        path = tempname() * ".toml"
        write(path, """
        [xai]
        api_key = "xai-test-key"

        [twitter]
        bearer_token = "test-bearer"
        """)
        cfg = load_config(path)
        @test cfg.grok_model == "grok-3"
        @test cfg.search_model == "grok-4-fast-non-reasoning"
        @test cfg.similarity_threshold == 0.9
        rm(path)
    end

    @testset "errors on missing config file" begin
        @test_throws ErrorException load_config("/nonexistent/path.toml")
    end

    @testset "errors on missing api_key" begin
        path = tempname() * ".toml"
        write(path, """
        [twitter]
        bearer_token = "test-bearer"
        """)
        @test_throws ErrorException load_config(path)
        rm(path)
    end
end
