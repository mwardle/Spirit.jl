@testset "getindex" begin
    headers = Headers("Content-Type" => "application/json")
    @test headers["Content-Type"] == "application/json"
    @test headers["content-type"] == "application/json"
    @test headers["CoNtEnT-tYpE"] == "application/json"

    headers = Headers("CoNtEnT-tYpE" => "text/csv")

    @test headers["Content-Type"] == "text/csv"
    @test headers["content-type"] == "text/csv"
    @test headers["CoNtEnT-tYpE"] == "text/csv"

    @test_throws BoundsError headers["Bad-Header"]
end

@testset "get" begin
    headers = Headers("Content-Type" => "application/json")

    @test get(headers, "Content-Type", "default") == "application/json"
    @test get(headers, "content-type", "default") == "application/json"
    @test get(headers, "Fake-Header", "default") == "default"
end

@testset "haskey" begin
    headers = Headers("Content-Type" => "application/json")

    @test haskey(headers, "Content-Type") == true
    @test haskey(headers, "content-TYPE") == true
    @test haskey(headers, "Fake-Header") == false
end

@testset "set" begin
    headers = Headers("Content-Type" => "application/json")
    
    modified = set(headers, "X-Powered-By", "Spirit")
    
    @test haskey(modified, "Content-Type") == true
    @test haskey(modified, "X-Powered-By") == true
    @test haskey(headers, "X-Powered-By") == false
    @test modified["X-Powered-By"] == "Spirit"
    @test modified["Content-Type"] == "application/json"
    
    modified = set(headers, "content-type", "application/yaml")
    
    @test headers["content-type"] == "application/json"
    @test modified["Content-Type"] == "application/yaml"
end

@testset "append" begin
    headers = Headers()
    
    headers = append(headers, "Accept", "application/json; q=0.6")
    @test headers["accept"] == "application/json; q=0.6"

    headers = append(headers, "aCcEpT", "application/yaml; q=0.8")
    
    @test headers["accept"] == "application/json; q=0.6, application/yaml; q=0.8"
end

@testset "delete" begin
    headers = Headers("Content-Type" => "application/json")
    
    modified = delete(headers, "content-type")
    
    @test haskey(headers, "content-type") == true
    @test haskey(modified, "content-type") == false
end
