struct Request
    client::Client
    method::AbstractString 
    uri::AbstractString
    httpversion::AbstractString
    headers::Headers
    resource::AbstractString
    base::AbstractString
    params::Dict{AbstractString,Any}
    query::Dict{AbstractString,Any}
    body::Dict{AbstractString,Any}
    cookies::Dict{AbstractString,Any}
    session::Dict{AbstractString,Any}
    files::Dict{AbstractString,Any}
end # Request

function Request(client::Client, method::AbstractString, uri::AbstractString, httpversion::AbstractString, headers::Headers)
    resource = uri # todo: this is just the path, fix this
    base = ''
    params = Dict{AbstractString, Any}()
    query = Dict{AbstractString, Any}()
    body = Dict{AbstractString, Any}()
    cookies = Dict{AbstractString, Any}()
    session = Dict{AbstractString, Any}()
    files = Dict{AbstractString, Any}()
    Request(client, method, uri, httpversion, headers, resource, base, params, query, body, cookies, session, files)
end

function Request(req::Request; 
    method=req.method,
    uri=req.uri,
    httpversion=req.httpversion,
    headers=req.headers, 
    resource=req.resource,
    base=req.base,
    params=req.params,
    query=req.query,
    body=req.body,
    cookies=req.cookies,
    session=req.session,
    files=req.files)
    
    Request(req.client, method, uri, httpversion, headers, resource, base, params, query, body, cookies, session, files)
end

function getheader(req::Request, name::AbstractString)
    get(req.headers, name)
end

function setheader(req::Request, name::AbstractString, value::AbstractString)
    headers = set(req.headers, name, value)
    Request(req; headers=headers)
end

function appendheader(req::Request, name::AbstractString, value::AbstractString)
    headers = append(req.headers, name, value)
    Request(req; headers=headers)
end