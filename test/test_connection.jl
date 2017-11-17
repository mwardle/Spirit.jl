httptest1 = include("./data/http/test1.jl")
httptest2 = include("./data/http/test2.jl")

@testset "readrequestline" begin
    const io = IOBuffer(httptest1)
    const c = Connection(io)
    
    Spirit.readrequestline!(c)
    
    @test get(c.method) == "POST"
    @test get(c.uri) == "/"
    @test get(c.httpversion) == "1.1"
    close(io)
    
    const io = IOBuffer(httptest2)
    const c = Connection(io)
    
    Spirit.readrequestline!(c)
    
    @test get(c.method) == "GET"
    @test get(c.uri) == "/docs/index.html"
    @test get(c.httpversion) == "1.1"
    close(io)
end

@testset "readheaders" begin
    const io = IOBuffer(httptest1)
    const c = Connection(io)

    Spirit.readrequestline!(c)
    Spirit.readheaders!(c)
    
    @test !isnull(c.rawheaders)
    @test !isnull(c.headers)
    rawheaders = get(c.rawheaders)
    headers = get(c.headers)
    @test length(rawheaders) == 2
    @test length(headers) == 2
    @test rawheaders[1] == ("Host" => "www.somewhere.com")
    @test rawheaders[2] == ("Content-Length" => "9")
    
    close(io)
    
    const io = IOBuffer(httptest2)
    const c = Connection(io)

    Spirit.readrequestline!(c)
    Spirit.readheaders!(c)
    
    @test !isnull(c.rawheaders)
    @test !isnull(c.headers)
    rawheaders = get(c.rawheaders)
    headers = get(c.headers)
    @test length(rawheaders) == 5
    @test length(headers) == 5
    @test rawheaders[1] == ("Host" => "www.nowhere123.com")
    @test rawheaders[2] == ("Accept" => "image/gif, image/jpeg, */*")
    @test rawheaders[3] == ("Accept-Language" => "en-us")
    @test rawheaders[4] == ("Accept-Encoding" => "gzip, deflate")
    @test rawheaders[5] == ("User-Agent" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)")

    close(io)
end
