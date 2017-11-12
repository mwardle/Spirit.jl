export pipe, resume, recover, Pipeline

struct Pipeline
    exec::Function
end # Pipeline

function resolve_continuation(continuation)
    isa(continuation, Future) ? fetch(continuation) : continuation
end # resolveContinuation

const pipeline_reducer = function(prevpipe, nextpipe)
    if (isa(prevpipe, Function))
        function(continuation)
            if isfin(continuation)
                continuation
            else
                continuation = resolve_continuation(prevpipe(continuation...))
                nextpipe(continuation)
            end
        end
    else
        function(continuation)
            nextpipe(prevpipe(continuation))
        end
    end
end

"""
    pipe(stages::Union{Function,Pipeline)...)::Pipeline
        
Create an http handler pipe.

```julia
p = pipe([
    (req::Request, res::Response) -> cont(req, setheader(res, "X-Powered-By", "Spirit")),
    (req::Request, res::Response) -> fin(req, respond_text(res, "A text response...")) 
])

run(p, req, res)
```
"""
function pipe(stages::Union{Function,Pipeline}...)::Pipeline
    exec = foldr(pipeline_reducer, c -> c, stages)
    Pipeline(exec)
end # pipe

function Base.run(p::Pipeline, data...)::Continuation
    p(cont(data...))
end # run

function (pipe::Pipeline)(continuation::Continuation)::Continuation
    resolve_continuation(pipe.exec(continuation))
end # Pipeline()

"""
    resume(Pipeline, Pipeline|Function)
    
Continue a pipe that is fin.

```julia
p = pipe([
    (req, res) -> fin(req, respond_text("this is wrong"))
])

p = resume(p, pipe([
    (req, res) -> fin(req, respond_text("this is right"))
]))
```
"""
function resume(first::Pipeline, stages::Union{Pipeline,Function}...; always::Bool=false)::Pipeline
    second = pipe(stages...)
    exec = function(continuation)
        continuation = first(continuation)
        if iscont(continuation) && !always
            continuation
        else
            second(cont(continuation...))
        end
    end

    Pipeline(exec)
end # resume

"""
    recover(Pipeline, Function)
    
Recover from exceptions thrown within a pipeline
"""
function recover(first::Pipeline, recovery::Function)::Pipeline
    exec = function(continuation)
        try
            first(continuation)
        catch e
            recovery(e, continuation...)
        end
    end
    
    Pipeline(exec)
end # recover
