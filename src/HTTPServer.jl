export HTTPServer

struct HTTPServer
    io::Base.IOServer
    handler::Function
    # options::Dict{Symbol,Any}
end

function createpipelinehandler(opts)
    opts = Dict{Symbol, Any}(opts)
    fn = function(socket::IO)
        connection = Connection(socket)
        allowedopts = [
            :maxheader, 
            :maxuri, 
            :maxmethod, 
            :maxversion,
            :maxbody,
            :maxtrailer,
            :keepcomments,
            :strict
        ]
        processopts = Vector{Pair{Symbol,Any}}()
        for opt in allowedopts
            if haskey(opts, opt)
                processopts[opt] = opts[opt]
            end
        end
        processrequest!(connection; processopts...)
        # req = Request(connection)
        # res = Response(connection)
        cont(connection)
        
        # TODO: make req + res
    end
end

function HTTPServer(io::Base.IOServer, p::Pipeline; options...)
    
    fallthroughhandler = function(conn)
        # TODO: content negotation
        throw(HTTPError(404; message="Not Found"))
    end
    errorhandler = function(error, conn) # TODO: req, res
        shouldclose = false
        if !isa(error, HTTPError)
            error = HTTPError(500)
        end
        
        statusCode = error.code
        statusMessage = STATUS_CODES[statusCode]
        safe = error.safe
        message = safe ? error.message : statusMessage
        shoudclose = error.shouldclose
        contentlength = length(message)
        
        headers = Headers(
            "Content-Length" => string(contentlength),
            "Content-Type" => "text/plain;charset=utf-8"
        )
        
        writeresponse!(conn, statusCode, statusMessage, headers, IOBuffer(message))
        
        if shouldclose
            close(conn.socket)
        end
        
        fin(conn)
    end
    p = pipe(p, fallthroughhandler)
    p = recover(p, errorhandler)
    p = pipe(createpipelinehandler(options), p)
    handler = function(socket::IO)
        Distributed.@spawn begin
            println("running handler")
            run(p, socket)
            true
        end
    end
    
    HTTPServer(io, handler)
end

function Base.run(server::HTTPServer)
    while isopen(server.io)
        println("ran")
        sock = accept(server.io)
        println("new socket")
        begin
            while isopen(sock)
                res = resolve_future(server.handler(sock))
                println("open $(isopen(sock))")
            end
            println("socket closed $(isopen(sock))")
        end
        
        println("Server open? $(isopen(server.io))")
    end    
end
