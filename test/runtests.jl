using Spirit
using Base.Test

# write your own tests here
@testset "Headers" begin
    include("test_headers.jl")
end

@testset "Continuation" begin
    include("test_continuation.jl")
end

@testset "Pipeline" begin
    include("test_pipeline.jl")
end