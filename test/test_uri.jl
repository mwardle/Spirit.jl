@testset "URIAuthority" begin
    import Spirit.URIAuthority
    tests = Dict((
        "google.com" => [nothing, "google.com", nothing],
        "google.com:8080" => [nothing, "google.com", UInt(8080)],
        "me@google.com:8080" => ["me", "google.com", UInt(8080)],
        "user:pass@danger.somewhere.com" => ["user:pass", "danger.somewhere.com", nothing],
        "255.255.255.255" => [nothing, IPv4("255.255.255.255"), nothing],
        "255.255.255.256" => [nothing, "255.255.255.256", nothing],
        "[::1]" => [nothing, IPv6("::1"), nothing],
        "[::1]:456" => [nothing, IPv6("::1"), UInt(456)]
    ))
    
    for (str, params) in tests
        authority = URIAuthority(str)
        expected = URIAuthority(params...)
        @test authority.userinfo == expected.userinfo
        @test authority.host == expected.host
        @test authority.port == expected.port
        
        @test string(authority) == str
    end
end

@testset "URI" begin
    import Spirit.URI
    import Spirit.@uri_str
    
        
    uri = uri"https://bro@www.coolsite.com/path/to/awesome?pie=yes#partytime"
    @test uri.scheme == "https"
    @test uri.authority.userinfo == "bro"
    @test uri.authority.host == "www.coolsite.com"
    @test uri.authority.port == nothing
    @test uri.path == "/path/to/awesome"
    @test uri.query == "pie=yes"
    @test uri.fragment == "partytime"
    @test string(uri) == "https://bro@www.coolsite.com/path/to/awesome?pie=yes#partytime"
    
    uri = uri"urn:starwars:battles:hoth"
    @test uri.scheme == "urn"
    @test uri.authority == nothing
    @test uri.path == "starwars:battles:hoth"
    @test uri.query == nothing
    @test uri.fragment == nothing
    @test string(uri) == "urn:starwars:battles:hoth"
    
    uri = uri"/jump/to/conclusions?mat=ofcourse?"
    @test uri.scheme == nothing
    @test uri.authority == nothing
    @test uri.path == "/jump/to/conclusions"
    @test uri.query == "mat=ofcourse?"
    @test uri.fragment == nothing
    @test string(uri) == "/jump/to/conclusions?mat=ofcourse?"
end
