using Test
using HTTP
using JSON3

include("../src/types.jl")
include("../src/api/xai.jl")

@testset "API error formatting" begin
    @testset "extract_api_error_message" begin
        @test extract_api_error_message("") == ""
        @test extract_api_error_message("""{"code":"invalid-argument","error":"Incorrect API key provided. You can obtain an API key from https://console.x.ai."}""") ==
              "Incorrect API key provided. You can obtain an API key from https://console.x.ai."
        @test extract_api_error_message("""{"message":"model not found"}""") == "model not found"
        @test extract_api_error_message("plain failure text") == "plain failure text"
    end

    @testset "format_api_error for generic Exception" begin
        msg = format_api_error(ErrorException("boom"))
        @test contains(msg, "boom")
    end

    @testset "format_api_error for HTTP.StatusError" begin
        body = """{"code":"invalid-argument","error":"Incorrect API key provided. You can obtain an API key from https://console.x.ai."}"""
        resp = HTTP.Response(400, body)
        err = HTTP.StatusError(400, "POST", "/v1/responses", resp)
        msg = format_api_error(err)
        @test startswith(msg, "API error 400:")
        @test contains(msg, "Incorrect API key provided")
    end
end
