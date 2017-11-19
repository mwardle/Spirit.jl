export URI, URIAuthority, @uri_str

const uriregex = r"^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?"
const authorityregex = r"^(([^/?#\[\]]*)@)?(([^:/?#\[\]@]+)|(\[([^/?#@\[\]]+)\]))(:([0-9]+))?$"
const ipv4regex = r"^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
struct URIAuthority
    userinfo::Union{AbstractString,Void}
    host::Union{AbstractString,IPv4,IPv6,Void}
    port::Union{UInt,Void}
end # struct URIAuthority

struct URI
    scheme::Union{AbstractString,Void}
    authority::Union{URIAuthority,Void}
    path::Union{AbstractString,Void}
    query::Union{AbstractString,Void}
    fragment::Union{AbstractString,Void}
end # struct URI



function URIAuthority(authority::AbstractString)
    parts = match(authorityregex, authority)
    if parts == nothing
        return URIAuthority(nothing, nothing, nothing)
    end
    
    userinfo = parts[2]
    host = if parts[4] != nothing
        if ismatch(ipv4regex, parts[4])
            try
                IPv4(parts[4])
            catch e
                parts[4]
            end
        else
            parts[4]
        end
    elseif parts[6] != nothing
        try
            IPv6(parts[6])
        catch e
            "[$(parts[4])]"
        end
    else
        nothing
    end
    
    port = if parts[8] == nothing
        nothing 
    else 
        parse(UInt, parts[8]) 
    end
    
    URIAuthority(userinfo, host, port)
end

function URI(uri::AbstractString)
    parts = match(uriregex, uri)
    scheme = parts[2]
    authority = if parts[4] == nothing nothing else URIAuthority(parts[4]) end
    path = parts[5]
    query = parts[7]
    fragment = parts[9]
    URI(scheme, authority, path, query, fragment)
end

macro uri_str(uri)
    URI(uri)
end

function Base.print(io::IO, authority::URIAuthority)
    if authority.userinfo != nothing
        print(io, authority.userinfo)
        print(io, '@')
    end
    
    if authority.host isa AbstractString || authority.host isa IPv4
        print(io, authority.host)
    elseif authority.host isa IPv6
        print(io, '[')
        print(io, authority.host)
        print(io, ']')
    end
    
    if authority.port != nothing
        print(io, ':')
        print(io, authority.port)
    end
end

function Base.print(io::IO, uri::URI)
    if uri.scheme != nothing
        print(io, uri.scheme)
        print(io, ':')
    end
    if uri.authority != nothing
        print(io, "//")
        print(io, uri.authority)
    end
    if uri.path != nothing
        print(io, uri.path)
    end
    if uri.query != nothing
        print(io, '?')
        print(io, uri.query)
    end
    if (uri.fragment != nothing)
        print(io, '#')
        print(io, uri.fragment)
    end
end
