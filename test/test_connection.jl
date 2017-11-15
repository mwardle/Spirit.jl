@testset "readrequestline" begin
    const io = open("./test/data/http/test1.http")
    const c = Connection(io)
    
    Spirit.readrequestline!(c)
    
    @test get(c.method) == "POST"
    @test get(c.uri) == "/"
    @test get(c.httpversion) == "1.1"
    close(io)
end

@testset "readheaders" begin
    const io = open("./test/data/http/test1.http")
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
end
