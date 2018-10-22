httptest1 = include("./data/http/test1.jl")
httptest2 = include("./data/http/test2.jl")
httptest3 = include("./data/http/test3.jl")

@testset "readrequestline" begin
    io = IOBuffer(httptest1)
    c = Connection(io)
    
    Spirit.readrequestline!(c)
    
    @test c.method == "POST"
    @test c.uri == "/"
    @test c.httpversion == "1.1"
    close(io)
    
    io = IOBuffer(httptest2)
    c = Connection(io)
    
    Spirit.readrequestline!(c)
    
    @test c.method == "GET"
    @test c.uri == "/docs/index.html"
    @test c.httpversion == "1.1"
    close(io)
end

@testset "readheaders!" begin
    io = IOBuffer(httptest1)
    c = Connection(io)

    Spirit.readrequestline!(c)
    Spirit.readheaders!(c)
    
    @test !isequal(nothing, c.rawheaders)
    @test !isequal(nothing, c.headers)
    rawheaders = c.rawheaders
    headers = c.headers
    @test length(rawheaders) == 2
    @test length(headers) == 2
    @test rawheaders[1] == ("Host" => "www.somewhere.com")
    @test rawheaders[2] == ("Content-Length" => "9")
    
    close(io)
    
    io = IOBuffer(httptest2)
    c = Connection(io)

    Spirit.readrequestline!(c)
    Spirit.readheaders!(c)
    
    @test !isequal(nothing, c.rawheaders)
    @test !isequal(nothing, c.headers)
    rawheaders = c.rawheaders
    headers = c.headers
    @test length(rawheaders) == 5
    @test length(headers) == 5
    @test rawheaders[1] == ("Host" => "www.nowhere123.com")
    @test rawheaders[2] == ("Accept" => "image/gif, image/jpeg, */*")
    @test rawheaders[3] == ("Accept-Language" => "en-us")
    @test rawheaders[4] == ("Accept-Encoding" => "gzip, deflate")
    @test rawheaders[5] == ("User-Agent" => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)")

    close(io)
end

@testset "createbodystream!" begin

    # with content-length
    io = IOBuffer(httptest1)
    c = Connection(io)

    Spirit.readrequestline!(c)
    Spirit.readheaders!(c)
    Spirit.createbodystream!(c)
    
    @test isequal(nothing, c.bodystream) == false
    @test isa(c.bodystream, SizedStream)
    @test c.bodystream.size == 9
    @test c.bodystartedread == false
    @test c.bodyfullyread == false
    b = read(c.bodystream, UInt8)
    @test b == UInt8('B')
    @test c.bodystartedread == true
    @test c.bodyfullyread == false
    str = read(c.bodystream)
    @test c.bodystartedread == true
    @test c.bodyfullyread == true
    @test String(str) == "ody Body"
    close(io)
    
    # transfer encoding
    io = IOBuffer(httptest3)
    c = Connection(io)

    Spirit.readrequestline!(c)
    Spirit.readheaders!(c)
    Spirit.createbodystream!(c)
    
    @test isequal(nothing, c.bodystream) == false
    @test isa(c.bodystream, ChunkedTransferDecodeStream)
    @test c.bodystartedread == false
    @test c.bodyfullyread == false
    b = read(c.bodystream, UInt8)
    @test b == UInt8('\'')
    @test c.bodystartedread == true
    @test c.bodyfullyread == false
    @test isequal(nothing, c.trailers) == true
    @test isequal(nothing, c.rawtrailers) == true
    str = read(c.bodystream)
    @test c.bodystartedread == true
    @test c.bodyfullyread == true
    expected = "Twas brillig, and the slithy toves\n" *
        "      Did gyre and gimble in the wabe:\n" *
        "All mimsy were the borogoves,\n" *
        "      And the mome raths outgrabe."
    @test String(str) == expected
    @test isequal(nothing, c.trailers) == false
    @test isequal(nothing, c.rawtrailers) == false

    rawtrailers = c.rawtrailers
    @test length(rawtrailers) == 2
    @test rawtrailers[1] == ("Happiness" => "100")
    @test rawtrailers[2] == ("Author" => "Lewis Carroll")
    
    close(io)
end

@testset "processrequest!" begin
    io = IOBuffer(httptest1)
    c = Connection(io)
    Spirit.processrequest!(c)
    close(io)
end

@testset "writeresponse!" begin
    io = IOBuffer()
    c = Connection(io)
    
    body = "Safety First"
    bodyio = IOBuffer(body)
    headers = Spirit.Headers("Content-Length" => string(length(body)))
    Spirit.writeresponse!(c, 200, "OK", headers, bodyio)
    
    response = take!(io)
    
    expected = "HTTP/1.1 200 OK\r\n" *
        "Content-Length: 12\r\n" *
        "\r\n" *
        "Safety First"
        
    @test expected == String(response)
end
