using Spirit
using Test
using Sockets

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

@testset "Util" begin
    include("test_util.jl")
end

@testset "Connection" begin
    include("test_connection.jl")
end

@testset "ChunkedTransferDecodeStream" begin
    include("test_chunkedtransferdecodestream.jl")
end

@testset "SizedStream" begin
    include("test_sizedstream.jl")
end

@testset "URI" begin
    include("test_uri.jl")
end
