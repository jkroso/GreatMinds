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

    @testset "compute_originality with single high-similarity result" begin
        records = [ThoughtRecord("t", "d", 0.96, 5, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        @test score ≈ 0.04 atol=0.01
    end

    @testset "compute_originality with single low-similarity result" begin
        records = [ThoughtRecord("t", "d", 0.30, 2, "2026-04-09T10:00:00")]
        score = compute_originality(records)
        @test score ≈ 0.70 atol=0.01
    end

    @testset "compute_originality weights recent more heavily" begin
        records = [
            ThoughtRecord("old", "d", 0.10, 1, "2026-04-08T10:00:00"),  # original (0.9)
            ThoughtRecord("new", "d", 0.95, 5, "2026-04-09T10:00:00"),  # unoriginal (0.05)
        ]
        score = compute_originality(records)
        # Most recent (index 2) weight=1.0, originality=0.05
        # Older (index 1) weight=0.7, originality=0.9
        # weighted avg = (0.05*1.0 + 0.9*0.7) / (1.0+0.7) = 0.68/1.7 ≈ 0.40
        @test score ≈ 0.40 atol=0.02
    end

    @testset "compute_originality all original" begin
        records = [
            ThoughtRecord("t1", "d", 0.10, 1, "2026-04-07T10:00:00"),
            ThoughtRecord("t2", "d", 0.20, 1, "2026-04-08T10:00:00"),
            ThoughtRecord("t3", "d", 0.15, 1, "2026-04-09T10:00:00"),
        ]
        score = compute_originality(records)
        @test score > 0.7
    end

    @testset "compute_originality all unoriginal" begin
        records = [
            ThoughtRecord("t1", "d", 0.95, 5, "2026-04-07T10:00:00"),
            ThoughtRecord("t2", "d", 0.92, 4, "2026-04-08T10:00:00"),
            ThoughtRecord("t3", "d", 0.98, 6, "2026-04-09T10:00:00"),
        ]
        score = compute_originality(records)
        @test score < 0.1
    end
end
