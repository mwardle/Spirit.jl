export pipeline
export join
export resume
export Pipeline

immutable Pipeline
    pipe::Function
end # Pipeline

function resolve_continuation(continuation)
    isa(continuation, Future) ? fetch(continuation) : continuation
end # resolveContinuation

const pipeline_reducer = function(fn, nextpipe)
    function (continuation)
        if isdone(continuation)
            continuation
        else
            continuation = resolve_continuation(fn(continuation.req, continuation.res))
            if isdone(continuation)
                continuation
            else
                nextpipe(continuation)
            end
        end
    end
end


"""
    join(Pipeline, Pipeline|Function)
    
Concatenate two pipelines into one

```julia
p = pipeline([
    (req, res) -> next(req, setheader(res, "X-Powered-By", "Spirit"))
])

p = join(p, pipeline([
    (req, res) -> done(req, respond_text(res, "Powered by Spirit!"))
]))
```
"""
function join(first::Pipeline, second::Pipeline)::Pipeline
    pipe = function(continuation)
        continuation = second(first(continuation))
    end

    Pipeline(pipe)
end # join

function join(first::Pipeline, second::Function)::Pipeline
    join(first, pipeline([second]))
end # join


"""
    resume(Pipeline, Pipeline|Function)
    
Continue a pipeline that is done.

```julia
p = pipeline([
    (req, res) -> done(req, respond_text("this is wrong"))
])

p = resume(p, pipeline([
    (req, res) -> done(req, respond_text("this is right"))
]))
```
"""
function resume(first::Pipeline, second::Pipeline)::Pipeline
    pipe = function(continuation)
        continuation = first(continuation)
        if isnext(continuation)
            continuation
        else
            second(next(continuation.req, continuation.res))
        end
    end

    Pipeline(pipe)
end # resume

function resume(first::Pipeline, second::Function)::Pipeline
    resume(first, pipeline([second]))
end # resume


"""
    pipeline(stages::Vector{Function})::Pipeline
        
Create an http handler pipeline.

```julia
pipeline([
    (req::Request, res::Response) -> next(req, setheader(res, "X-Powered-By", "Spirit")),
    (req::Request, res::Response) -> done(req, respond_text(res, "A text response...")) 
])
```
"""
function pipeline(stages::Vector{Function})::Pipeline
    pipe = foldr(pipeline_reducer, c -> c, stages)
    Pipeline(pipe)
end # pipeline

function pipeline(stages)::Pipeline
    # should throw if invalid
    pipeline(Vector{Function}(stages))
end # pipeline

   
function (pipeline::Pipeline)(req::Request, res::Response)::Continuation
    pipeline(next(req, res))
end # Pipeline()

function (pipeline::Pipeline)(continuation::Continuation)::Continuation
    resolve_continuation(pipeline.pipe(continuation))
end
