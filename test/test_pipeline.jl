@testset "pipe" begin

    # basic usage
    @test isa(pipe, Function)
    p = pipe(
        (v) -> next(v + 1),
        (v) -> done(v * 2) )
    
    @test isa(p, Pipeline)
    
    c = run(p, 4)
    
    @test isa(c, Continuation) == true
    @test isdone(c) == true
    @test c.data == (10,)
    
    # short-circuit
    p = pipe(
        (v) -> done(v + 1),
        (v) -> done(v * 2) )
    
    @test isa(p, Pipeline)
    
    c = run(p, 4)
    
    @test isa(c, Continuation) == true
    @test isdone(c) == true
    @test c.data == (5,)
    
    # concatenation
    p2 = pipe(v -> next(v + 1))
    
    p = pipe(
        p2,
        (v) -> done(v * 2) )
    
    @test isa(p, Pipeline)
    
    c = run(p, 4)
    
    @test isa(c, Continuation) == true
    @test isdone(c) == true
    @test c.data == (10,)
    
    # multiple parameters
    p = pipe(
        (v1, v2) -> next(v1 + 2, v1 + v2),
        (v1, v2) -> next(v1 * 2, v2 + 7) )
        
    c = run(p, 1, 1)
    @test c.data == (6, 9)
end

@testset "resume" begin
    # normal usage
    p1 = pipe(v -> done(v + 1))
    p2 = pipe(v -> done(v * 2))
    
    p3 = resume(p1, p2)
    
    @test isa(p3, Pipeline) == true
    
    c = run(p3, 3)
    
    @test isa(c, Continuation) == true
    @test c.data == (8,)
    
    # when not done
    p1 = pipe(v -> next(v + 1))
    p2 = pipe(v -> done(v * 2))
    
    p3 = resume(p1, p2)
    
    @test isa(p3, Pipeline) == true
    
    c = run(p3, 3)
    
    @test isa(c, Continuation) == true
    @test c.data == (4,)
    
    # when not done, but always set to true
    p1 = pipe(v -> next(v + 1))
    p2 = pipe(v -> done(v * 2))
    
    p3 = resume(p1, p2; always=true)
    
    @test isa(p3, Pipeline) == true
    
    c = run(p3, 3)
    
    @test isa(c, Continuation) == true
    @test c.data == (8,)
    
    # when done, and always set to true
    p1 = pipe(v -> done(v + 1))
    p2 = pipe(v -> done(v * 2))
    
    p3 = resume(p1, p2; always=true)
    
    @test isa(p3, Pipeline) == true
    
    c = run(p3, 3)
    
    @test isa(c, Continuation) == true
    @test c.data == (8,)
    
    # with a function
    p1 = pipe(v -> done(v + 1))
    p2 = v -> done(v * 2)
    
    p3 = resume(p1, p2)
    
    @test isa(p3, Pipeline) == true
    
    c = run(p3, 3)
    
    @test isa(c, Continuation) == true
    @test c.data == (8,)
    
    # with multiple arguments
    p1 = pipe(v -> done(v + 1))
    p2 = pipe(v -> next(v * 2))
    
    p3 = resume(p1, p2, v -> done(v + 9))
    
    @test isa(p3, Pipeline) == true
    
    c = run(p3, 3)
    
    @test isa(c, Continuation) == true
    @test c.data == (17,)
    
end

@testset "recover" begin
    # with no exception
    p = pipe(v -> done(v + 2))
    p = recover(p, (err, v) -> done(v * 12))
    @test isa(p, Pipeline) == true

    c = run(p, 4)
    @test isa(c, Continuation) == true
    
    @test isdone(c) == true
    @test c.data == (6,)
    
    # with exception
    p = pipe(v -> throw(UndefVarError(:sushi)))
    p = recover(p, (err, v) -> begin 
        @test isa(err, UndefVarError)
        @test v == 4
        done(v * 12)
    end)
    @test isa(p, Pipeline) == true

    c = run(p, 4)
    @test isa(c, Continuation) == true
    
    @test isdone(c) == true
    @test c.data == (48,)
end
