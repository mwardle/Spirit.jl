export fin, cont, isfin, iscont, Continuation, Finish, Continue

@enum ContinuationState Finish Continue

struct Continuation{T <: Tuple}
    state::ContinuationState
    data::T
end # Continuation

isfin(continuation::Continuation) = continuation.state == Finish
iscont(continuation::Continuation) = continuation.state == Continue

fin(args...) = Continuation(Finish, tuple(args...))
cont(args...) = Continuation(Continue, tuple(args...))

function Base.show(io::IO, cont::Continuation)
    
    if cont.state == Finish
        print(io, "fin(")
    else
        print(io, "cont(")
    end
    
    comma = false
    for v in cont
        if comma
            print(io, ", ")
        end
        comma = true
        
        show(io, v)
    end
    
    print(io, ")")
end
    
Base.start(c::Continuation) = Base.start(c.data)
Base.done(c::Continuation, state) = Base.done(c.data, state)
Base.next(c::Continuation, state) = Base.next(c.data, state)