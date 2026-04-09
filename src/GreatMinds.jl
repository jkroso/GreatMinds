module GreatMinds

using Tachikoma
@tachikoma_app
using HTTP
using JSON3
using TOML
using LinearAlgebra
using Dates

include("types.jl")
include("config.jl")
include("similarity.jl")
include("history.jl")
include("personality.jl")
include("api/xai.jl")
include("api/twitter.jl")
include("screens/home.jl")
include("screens/groking.jl")
include("screens/searching.jl")
include("screens/results.jl")
include("screens/detail.jl")
include("app.jl")

export main

end # module
