export ChunkedTransferDecodeStream

mutable struct ChunkedTransferDecodeStream <: IO
    source::IO
    maxsize::UInt64
    nread::UInt64
    chunkstart::UInt64
    chunksize::UInt64   # of the current chunk
    ondone::Function
    onstart::Function
end

function ChunkedTransferDecodeStream(source::IO; maxsize=typemax(UInt64), ondone::Function=NOOP, onstart::Function=NOOP)
    ChunkedTransferDecodeStream(source, maxsize, 0, 0, 0, ondone, onstart)
end

function Base.read(s::ChunkedTransferDecodeStream, ::Type{UInt8})
    # has the side affect of parsing the next chunksize if necessary
    if eof(s)
        throw(EOFError())
    end
    b = read(s.source, UInt8)
    s.nread += 1
    if s.nread >= s.maxsize
        throw(HTTPError(413; message="Unwilling to process a request entity with total size greater than $(s.maxsize)", shouldclose=true))
    end
    b
end

# function Base.readbytes!(s::ChunkedTransferDecodeStream, dest::Vector{UInt8}, count::Int64)
#     for i in 1:count
#         push!(dest, read(s, UInt8))
#     end
#     
#     count
# end

function Base.eof(s::ChunkedTransferDecodeStream)
    if s.nread == 0
        s.onstart()
    end
    if eof(s.source)
        true
    else
        chunkpos = s.nread - s.chunkstart
        if s.nread == 0 || chunkpos == s.chunksize
            readchunksize(s)
        end
        
        eof(s.source) || s.chunksize == 0
    end 
end

function Base.isopen(s::ChunkedTransferDecodeStream)
    isopen(s.source)
end

function Base.close(s::ChunkedTransferDecodeStream)
    nothing
end

function readchunksize(s::ChunkedTransferDecodeStream)
    source = s.source
    complete = false
    hexbytes = Vector{UInt8}()
    if isopen(source)
        b = read(s.source, UInt8)
        s.nread += 1
        while in(b, HEX) && isopen(source)
            if s.nread >= s.maxsize
                throw(HTTPError(413; message="Unwilling to process a request entity with total size greater than $(s.maxsize)", shouldclose=true))
            end
            push!(hexbytes, b)
            b = read(source, UInt8)
            s.nread += 1
        end
        
        if length(hexbytes) == 0
            throw(HTTPError(400; message="Chunked transfer encoding is missing chunksize at position $(s.nread) (found $(b))", shouldclose=true))
        end
        
        extcount = 0
        # TODO: We really don't care about any chunked encoding extensions at this point, but
        #       we may want to in the future...also we should validate that at least the syntax
        #       is correct for the extension.  Currently limiting the total extensions size to
        #       1024 bytes, but we may want to make this configurable.
        while b != CR && b != LF && isopen(source)
            extcount += 1
            if extcount > 1024
                throw(HTTPError(400; message="Unwilling to parse a chunked encoding extension greater than 1024 bytes", shouldclose=true))
            end
            if s.nread >= s.maxsize
                throw(HTTPError(413; message="Unwilling to process a request entity with total size greater than $(s.maxsize)", shouldclose=true))
            end
            
            b = read(source, UInt8)
            s.nread += 1
        end
        
        if b == LF
            throw(HTTPError(400; message="Invalid line ending in chunked encoding after chunk size", shouldclose=true))
        end
        
        if s.nread >= s.maxsize
            throw(HTTPError(413; message="Unwilling to process a request entity with total size greater than $(s.maxsize)", shouldclose=true))
        end
        
        if b == CR && isopen(source)
            b = read(source, UInt8)
            s.nread += 1
            
            foundend = true
            if s.nread >= s.maxsize
                throw(HTTPError(413; message="Unwilling to process a request entity with total size greater than $(s.maxsize)", shouldclose=true))
            end
            if b != LF
                throw(HTTPError(400; message="Invalid line ending in chunked encoding after chunk size", shouldclose=true))
            end
        end
    end
    
    if !foundend
        # source must have closed unexpectedly
        throw(HTTPError(400; "Unexpected end of entity data while decoding chunked transfer encoding", shouldclose=true))
    end
    
    try
        s.chunksize = parse(UInt64, String(hexbytes), 16)
        # println("CHUNK SIZE:", s.chunksize)
    catch e
        if isa(e, OverflowError)
            throw(HTTPError(413; "Chunk size too large to be parsed", shouldclose=true))
        else
            throw(HTTPError(500; "Unexpected error occurred", shouldclose=true, data=Dict{AbstractString, Any}(error => e)))
        end
    end
    
    s.chunkstart = s.nread
    
    # notify parser so trailers can be consumed
    if s.chunksize == 0
        s.ondone()
    end

    s.chunksize
end
