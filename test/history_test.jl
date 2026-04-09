using Test
using JSON3
using Dates

include("../src/types.jl")
include("../src/history.jl")

@testset "History" begin
    @testset "load_history returns empty for missing file" begin
        h = load_history("/nonexistent/path/history.json")
        @test isempty(h)
    end

    @testset "save and load round-trip" begin
        dir = mktempdir()
        path = joinpath(dir, "history.json")
        records = [
            ThoughtRecord("thought1", "distilled1", 0.96, 5, "2026-04-09T10:00:00"),
            ThoughtRecord("thought2", "distilled2", 0.40, 3, "2026-04-09T11:00:00"),
        ]
        save_history(path, records)
        loaded = load_history(path)
        @test length(loaded) == 2
        @test loaded[1].thought == "thought1"
        @test loaded[1].max_similarity == 0.96
        @test loaded[2].thought == "thought2"
        rm(dir, recursive=true)
    end

    @testset "compute_originality with empty history" begin
        @test compute_originality(ThoughtRecord[]) == 0.5
    end

    @testset "compute_originality with near-perfect match" begin
        records = [ThoughtRecord("t", "d", 0.99, 5, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        # 0.99^20 ≈ 0.818, originality ≈ 0.182
        @test score ≈ 0.18 atol=0.03
    end

    @testset "compute_originality with 95% match is still fairly original" begin
        records = [ThoughtRecord("t", "d", 0.95, 5, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        # 0.95^20 ≈ 0.358, originality ≈ 0.642
        @test score > 0.5
    end

    @testset "compute_originality with low similarity is near 1.0" begin
        records = [ThoughtRecord("t", "d", 0.30, 2, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        @test score > 0.99
    end

    @testset "compute_originality weights recent more heavily" begin
        records = [
            ThoughtRecord("old", "d", 0.50, 1, "2026-04-08T10:00:00"),  # very original
            ThoughtRecord("new", "d", 0.99, 5, "2026-04-09T10:00:00"),  # near-perfect match
        ]
        score = compute_originality(records)
        # Recent (0.99) drags it down, old (0.50) is near 1.0
        # But recent is weighted more → score should be well below the all-original case
        @test score < 0.7
    end

    @testset "compute_originality all original" begin
        records = [
            ThoughtRecord("t1", "d", 0.10, 1, "2026-04-07T10:00:00"),
            ThoughtRecord("t2", "d", 0.20, 1, "2026-04-08T10:00:00"),
            ThoughtRecord("t3", "d", 0.15, 1, "2026-04-09T10:00:00"),
        ]
        score = compute_originality(records)
        @test score > 0.99
    end

    @testset "compute_originality all near-perfect matches" begin
        records = [
            ThoughtRecord("t1", "d", 0.99, 5, "2026-04-07T10:00:00"),
            ThoughtRecord("t2", "d", 0.99, 4, "2026-04-08T10:00:00"),
            ThoughtRecord("t3", "d", 0.99, 6, "2026-04-09T10:00:00"),
        ]
        score = compute_originality(records)
        @test score < 0.25
    end
end
