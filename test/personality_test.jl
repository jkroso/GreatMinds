using Test

include("../src/types.jl")
include("../src/personality.jl")

@testset "Personality" begin
    @testset "tone_tier thresholds" begin
        @test tone_tier(0.0) == npc
        @test tone_tier(0.15) == npc
        @test tone_tier(0.25) == npc
        @test tone_tier(0.26) == normie
        @test tone_tier(0.40) == normie
        @test tone_tier(0.41) == neutral
        @test tone_tier(0.50) == neutral
        @test tone_tier(0.60) == neutral
        @test tone_tier(0.61) == freethinker
        @test tone_tier(0.75) == freethinker
        @test tone_tier(0.76) == insane
        @test tone_tier(1.0) == insane
    end

    @testset "tone_copy returns strings for all screens and tiers" begin
        for tier in instances(ToneTier)
            prompt = input_prompt(tier)
            @test prompt isa String
            @test length(prompt) > 0

            label = groking_label(tier)
            @test label isa String

            searching_msg = searching_status(tier)
            @test searching_msg isa String

            for is_original in [true, false]
                verdict = results_verdict(tier, is_original)
                @test verdict isa String
            end

            label_str = score_label(tier)
            @test label_str isa String
        end
    end

    @testset "specific copy spot-checks" begin
        @test contains(input_prompt(npc), "NPC")
        @test input_prompt(neutral) == "What's your take?"
    end
end
