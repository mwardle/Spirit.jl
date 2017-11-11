export done
export next

@enum ContinuationState Done Next

immutable Continuation
    state::ContinuationState
    req::Request
    res::Response
end # Continuation

isdone(continuation::Continuation) = continuation.state == Done
isnext(continuation::Continuation) = continuation.state == Next

done(req::Request, res::Response) = Continuation(Done, req, res)
done(res::Response, req::Request) = done(req, res)

next(req::Request, res::Response) = Continuation(Next, req, res)
next(res::Response, req::Request) = next(req, res)
