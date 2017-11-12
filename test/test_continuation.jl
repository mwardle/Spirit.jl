@testset "fin" begin
    c = fin("v", 1)
    
    @test typeof(c) <: Continuation
    @test typeof(c) == Continuation{Tuple{String, Int64}}
    @test c.data == ("v", 1)
    @test c.state == Finish
end

@testset "cont" begin
    c = cont("v", 1)
    
    @test typeof(c) <: Continuation
    @test typeof(c) == Continuation{Tuple{String, Int64}}
    @test c.data == ("v", 1)
    @test c.state == Continue
end

@testset "isfin" begin
    @test isfin(fin("v", 1)) == true
    @test isfin(cont("v", 1)) == false
end

@testset "iscont" begin
    @test iscont(fin("v", 1)) == false
    @test iscont(cont("v", 1)) == true
end