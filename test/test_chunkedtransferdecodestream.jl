chunkedtest1 = include("./data/chunked/test1.jl")

@testset "read" begin
    io = IOBuffer(chunkedtest1)
    s = ChunkedTransferDecodeStream(io)
    
    data = read(s)
        
    expected = "'Twas brillig, and the slithy toves\n" *
        "      Did gyre and gimble in the wabe:\n" *
        "All mimsy were the borogoves,\n" *
        "      And the mome raths outgrabe."
        
    @test String(data) == expected
    
    close(s)
end
