using Test
using LinearAlgebra

include("../src/similarity.jl")

@testset "Similarity" begin
    @testset "cosine_similarity" begin
        @test cosine_similarity([1.0, 0.0], [1.0, 0.0]) ≈ 1.0
        @test cosine_similarity([1.0, 0.0], [0.0, 1.0]) ≈ 0.0
        @test cosine_similarity([1.0, 0.0], [-1.0, 0.0]) ≈ -1.0
        @test cosine_similarity([1.0, 1.0], [1.0, 1.0]) ≈ 1.0
        @test cosine_similarity([3.0, 4.0], [4.0, 3.0]) ≈ 0.96 atol=0.01
    end

    @testset "cluster groups similar items" begin
        items = [
            (text="a", embedding=[1.0, 0.0, 0.0]),
            (text="b", embedding=[0.99, 0.1, 0.0]),
            (text="c", embedding=[0.0, 0.0, 1.0]),
            (text="d", embedding=[0.0, 0.05, 0.99]),
        ]
        groups = cluster(items, 0.9)
        @test length(groups) == 2
        @test length(groups[1].items) == 2
        @test length(groups[2].items) == 2
    end

    @testset "cluster with no matches" begin
        items = [
            (text="a", embedding=[1.0, 0.0]),
            (text="b", embedding=[0.0, 1.0]),
        ]
        groups = cluster(items, 0.9)
        @test length(groups) == 2
        @test length(groups[1].items) == 1
        @test length(groups[2].items) == 1
    end

    @testset "cluster with empty input" begin
        groups = cluster([], 0.9)
        @test length(groups) == 0
    end
end
