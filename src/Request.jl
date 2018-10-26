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

function getheader(req::Request, name::AbstractString, default=nothing)
    get(req.headers, name, default)
end

function setheader(req::Request, name::AbstractString, value::AbstractString)
    headers = set(req.headers, name, value)
    Request(req; headers=headers)
end

function appendheader(req::Request, name::AbstractString, value::AbstractString)
    headers = append(req.headers, name, value)
    Request(req; headers=headers)
end
