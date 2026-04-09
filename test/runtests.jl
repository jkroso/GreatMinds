using Test

@testset "GreatMinds" begin
    include("config_test.jl")
    include("similarity_test.jl")
    include("history_test.jl")
    include("personality_test.jl")
end
