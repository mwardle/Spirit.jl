export SizedStream

mutable struct SizedStream <: IO
    source::IO
    size::UInt64
    nread::UInt64
    ondone::Nullable{Function}
end

function SizedStream(source, size; ondone=Nullable{Function}())
    SizedStream(source, size, 0, ondone)
end

function Base.read(s::SizedStream, ::Type{UInt8})
    if eof(s)
        throw(EOFError())
    end
    
    s.nread += 1
    b = read(s.source, UInt8)
    if s.nread == s.size && !isnull(s.ondone)
        get(s.ondone)()
    end
    b
end

function Base.eof(s::SizedStream)
    return eof(s.source) || s.nread >= s.size
end

function Base.isopen(s::SizedStream)
    return isopen(s.source)
end

function Base.close(s::SizedStream)
    nothing
end
