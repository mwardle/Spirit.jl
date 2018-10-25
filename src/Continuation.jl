export done, next, isdone, isnext, Continuation, Done, Next

@enum ContinuationState Done Next

struct Continuation{T <: Tuple}
    state::ContinuationState
    data::T
end # Continuation

isdone(continuation::Continuation) = continuation.state == Done
isnext(continuation::Continuation) = continuation.state == Next

done(args...) = Continuation(Done, tuple(args...))
next(args...) = Continuation(Next, tuple(args...))

function Base.show(io::IO, next::Continuation)
    
    if next.state == Done
        print(io, "done(")
    else
        print(io, "next(")
    end
    
    comma = false
    for v in next
        if comma
            print(io, ", ")
        end
        comma = true
        
        show(io, v)
    end
    
    print(io, ")")
end

Base.iterate(c::Continuation) = Base.iterate(c.data)
Base.iterate(c::Continuation, state) = Base.iterate(c.data, state) 
# Base.start(c::Continuation) = Base.start(c.data)
# Base.done(c::Continuation, state) = Base.done(c.data, state)
# Base.next(c::Continuation, state) = Base.next(c.data, state)
