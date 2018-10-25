@testset "done" begin
    c = done("v", 1)
    
    @test typeof(c) <: Continuation
    @test typeof(c) == Continuation{Tuple{String, Int64}}
    @test c.data == ("v", 1)
    @test c.state == Done
end

@testset "next" begin
    c = next("v", 1)
    
    @test typeof(c) <: Continuation
    @test typeof(c) == Continuation{Tuple{String, Int64}}
    @test c.data == ("v", 1)
    @test c.state == Next
end

@testset "isdone" begin
    @test isdone(done("v", 1)) == true
    @test isdone(next("v", 1)) == false
end

@testset "isnext" begin
    @test isnext(done("v", 1)) == false
    @test isnext(next("v", 1)) == true
end
