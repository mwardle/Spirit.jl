@testset "constructor <from connection>"  begin    
    io = IOBuffer(httptest1)
    c = Connection(io)
    Spirit.processrequest!(c)
        
    req = Spirit.Request(c)
    
    @test req.method == "POST"
    @test req.uri == "/"
    @test req.httpversion == "1.1"
    @test length(req.headers) == 2
    @test get(req.headers, "Host") == "www.somewhere.com"
    @test get(req.headers, "Content-Length") == "9"
    @test req.resource == "/"
    @test req.resource_base == ""
    
    close(io)
    
    io = IOBuffer(httptest2)
    c = Connection(io)
    Spirit.processrequest!(c)
        
    req = Spirit.Request(c)
    
    @test req.method == "GET"
    @test req.uri == "/docs/index.html"
    @test req.httpversion == "1.1"
    @test length(req.headers) == 5
    @test get(req.headers, "Host") == "www.nowhere123.com"
    @test get(req.headers, "Accept") == "image/gif, image/jpeg, */*"
    @test get(req.headers, "Accept-Language") == "en-us"
    @test get(req.headers, "Accept-Encoding") == "gzip, deflate"
    @test get(req.headers, "User-Agent") == "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"
    @test req.resource == "/docs/index.html"
    @test req.resource_base == ""
    
    close(io)
end
