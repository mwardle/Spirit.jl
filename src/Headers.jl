export Headers, append, get, set, delete

import Base

struct Headers
    data::Dict{AbstractString, AbstractString}
    keymap::Dict{AbstractString, AbstractString}
end # Headers

function Headers()
    Headers(Dict{AbstractString, AbstractString}(), Dict{AbstractString, AbstractString}())
end

function Headers{K <: AbstractString,V <: AbstractString}(entries::Pair{K,V}...)
    function reducer(headers, entry)
        append(headers, first(entry), last(entry))
    end
    reduce(reducer, Headers(), entries)
end

function Base.getindex(headers::Headers, name::AbstractString)
    if !haskey(headers, name)
        throw(BoundsError(headers, name))
    end
    
    get(headers, name, "")
end

function Base.haskey(headers::Headers, name::AbstractString)
    lcname = lowercase(name)
    haskey(headers.keymap, lcname)
end

function Base.get(headers::Headers, name::AbstractString, default)
    lcname = lowercase(name)
    if !haskey(headers.keymap, lcname)
        default
    else
        realname = get(headers.keymap, lcname, "")
        get(headers.data, realname, default)
    end
end

function set(headers::Headers, name::AbstractString, value::AbstractString)
    lcname = lowercase(name)
    newdata = merge!(Dict{AbstractString, AbstractString}(), headers.data)
    newkeymap = merge!(Dict{AbstractString, AbstractString}(), headers.keymap)
    
    if haskey(newkeymap, lcname)
        oldname = get(newkeymap, lcname, "")
        Base.delete!(newdata, oldname)
        Base.delete!(newkeymap, lcname)
    end
    
    Base.setindex!(newkeymap, name, lcname)
    Base.setindex!(newdata, value, name)
    
    Headers(newdata, newkeymap)
end

function append(headers::Headers, name::AbstractString, value::AbstractString)
    lcname = lowercase(name)
    if haskey(headers.keymap, lcname)
        name = Base.get(headers.keymap, lcname, name)
        value = string(Base.get(headers.data, name, ""), ", ", value)
    end
    
    set(headers, name, value)
end

function delete(headers::Headers, name::AbstractString)
    lcname = lowercase(name)
    if haskey(headers.keymap, lcname)
        newdata = merge!(Dict{AbstractString, AbstractString}(), headers.data)
        newkeymap = merge!(Dict{AbstractString, AbstractString}(), headers.keymap)
        oldname = get(newkeymap, lcname, "")
        Base.delete!(newdata, oldname)
        Base.delete!(newkeymap, lcname)
        Headers(newdata, newkeymap)
    else
        headers
    end
end

function Base.show(io::IO, headers::Headers)
    comma = false
    print(io, "Headers(")
    for (name, value) in headers.data
        if comma
            print(io, ", ")
        end
        show(io, name)
        print(io, " => ")
        show(io, value)

        comma = true
    end
    print(io, ")")
end

Base.start(headers::Headers) = Base.start(headers.data)
Base.done(headers::Headers, state) = Base.done(headers.data, state)
Base.next(headers::Headers, state) = Base.next(headers.data, state)
Base.isempty(headers::Headers) = Base.isempty(headers.data)
Base.length(headers::Headers) = Base.length(headers.data)
Base.eltype(headers::Headers) = Base.eltype(headers.data)
Base.keytype(headers::Headers) = Base.keytype(headers.data)
Base.valtype(headers::Headers) = Base.valtype(headers.data)
Base.reduce(fn, init, headers::Headers) = Base.reduce(fn, init, headers.data)
Base.keys(headers::Headers) = Base.keys(headers.data)
Base.values(headers::Headers) = Base.values(headers.data)
function Base.merge(headers::Headers, others::Headers...)
    if isempty(others)
        headers
    else 
        (head, tail) = (others[1], others[2:end])
        for (k,v) in head
            headers = set(headers, k, v)
        end
        
        Base.merge(headers, tail)
    end
end
