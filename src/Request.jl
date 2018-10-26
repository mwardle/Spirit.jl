struct Request
    connection::Connection
    method::AbstractString 
    uri::AbstractString
    httpversion::AbstractString
    headers::Headers
    resource::AbstractString
    resource_base::AbstractString
    params::Dict{AbstractString,Any}
    query::Dict{AbstractString,Any}
    body::Dict{AbstractString,Any}
    cookies::Dict{AbstractString,Any}
    session::Dict{AbstractString,Any}
    files::Dict{AbstractString,Any}
    data::Dict{AbstractString,Any}
end # Request

function Request(connection::Connection)
    parseduri = URI(connection.uri)
    
    method = connection.method
    uri = connection.uri
    httpversion = connection.httpversion
    headers = connection.headers
    resource = parseduri.path
    resource_base = ""
    params = Dict{AbstractString, Any}()
    query = Dict{AbstractString, Any}()
    body = Dict{AbstractString, Any}()
    cookies = Dict{AbstractString, Any}()
    session = Dict{AbstractString, Any}()
    files = Dict{AbstractString, Any}()
    data = Dict{AbstractString, Any}()
    Request(connection, method, uri, httpversion, headers, resource, 
        resource_base, params, query, body, cookies, session, files, data)
end

function Request(req::Request; 
    method=req.method,
    uri=req.uri,
    httpversion=req.httpversion,
    headers=req.headers, 
    resource=req.resource,
    resource_base=req.resource_base,
    params=req.params,
    query=req.query,
    body=req.body,
    cookies=req.cookies,
    session=req.session,
    files=req.files,
    data=req.data)
    
    Request(req.connection, method, uri, httpversion, headers, resource, 
        resource_base, params, query, body, cookies, session, files, data)
end

"""
Retrieve a request's header.

The name is case-insensitive

```julia
getheader(req, "Content-Type") == getheader(req, "content-type") # true
```
"""
function getheader(req::Request, name::AbstractString, default=nothing)
    get(req.headers, name, default)
end

"""
Set a header for a request.

This function does not mutate the request or its headers, but instead
returns a new version of the request with the updated header.

If the value is `nothing`, the header will be deleted.

```julia
req2 = setheader(req, "X-Special-Header", "header value")
getheader(req, "X-Special-Header")  # nothing
getheader(req2, "X-Special-Header") # "header value"
```
"""
function setheader(req::Request, name::AbstractString, value::Union{AbstractString,Nothing})
    headers = set(req.headers, name, value)
    Request(req; headers=headers)
end

"""
Append a header for a request.

This function does not mutate the request or its headers, but instead
returns a new version of the request with the updated header.

If the header already exists, the header is appended to the existing header value
with a comma used as a separator.  Otherwise, the header is set to the value.

```julia
req = appendheader(req, "X-Special-Header", "header value 1")
getheader(req, "X-Special-Header") # "header value 1"

req = appendheader(req, "X-Special-Header", "header value 2")
getheader(req, "X-Special-Header") # "header value 1, header value 2"
```
"""
function appendheader(req::Request, name::AbstractString, value::AbstractString)
    headers = append(req.headers, name, value)
    Request(req; headers=headers)
end
