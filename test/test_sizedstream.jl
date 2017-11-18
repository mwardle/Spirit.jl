@testset "read" begin
    testsized1 = "'Twas brillig, and the slithy toves\n" *
        "      Did gyre and gimble in the wabe:\n" *
        "All mimsy were the borogoves,\n" *
        "      And the mome raths outgrabe." *
        "An some extra nonsense at the end, just for good measure"

    io = IOBuffer(testsized1)
    s = SizedStream(io, 139)
    
    data = read(s)

        
    expected = "'Twas brillig, and the slithy toves\n" *
        "      Did gyre and gimble in the wabe:\n" *
        "All mimsy were the borogoves,\n" *
        "      And the mome raths outgrabe."        
    @test String(data) == expected
    
    close(s)
end
