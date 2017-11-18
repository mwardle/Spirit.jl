const Param = Pair{AbstractString,AbstractString}
const Params = Vector{Param}
const Entry = Pair{AbstractString,Params}
const Entries = Vector{Entry}

@testset "parse_header_value" begin
    headervalue = "value1;q=0.5;r=b,value2;q=0"
    parsed = Spirit.parse_header_value(headervalue)
    
    @test isa(parsed, Entries)
    @test length(parsed) == 2
    
    entry1 = parsed[1]
    entry2 = parsed[2]
    
    # @test first(entry1) == "value1"
    # @test length(last(entry1)) == 2
    # @test last(entry1)[1] == Param("q" => "0.5")
    # @test last(entry1)[2] == Param("r" => "b")
    @test parsed == Entries([
        "value1" => [
            "q" => "0.5",
            "r" => "b"
        ],
        "value2" => [
            "q" => "0"
        ]
    ])
    
    headervalue = " value1 ; q = 0.5 ; r = b ,  value2 ; q =  0"
    parsed = Spirit.parse_header_value(headervalue)
    
    @test isa(parsed, Entries)
    @test length(parsed) == 2
    
    entry1 = parsed[1]
    entry2 = parsed[2]
    
    # @test first(entry1) == "value1"
    # @test length(last(entry1)) == 2
    # @test last(entry1)[1] == Param("q" => "0.5")
    # @test last(entry1)[2] == Param("r" => "b")
    @test parsed == Entries([
        "value1" => [
            "q" => "0.5",
            "r" => "b"
        ],
        "value2" => [
            "q" => "0"
        ]
    ])
    
    # no parameters
    headervalue = "value1;q=0.5;r=b,value2;q=0"
    @test_throws HttpError Spirit.parse_header_value(headervalue; parameterized=false)
    
    headervalue = "value1,value2"
    parsed = Spirit.parse_header_value(headervalue)
    @test parsed == Entries([
        "value1" => [
        ],
        "value2" => [
        ]
    ])
    
    headervalue = "value1"
    parsed = Spirit.parse_header_value(headervalue)
    @test parsed == Entries([
        "value1" => [
        ]
    ])
    
    headervalue = ""
    @test_throws HttpError Spirit.parse_header_value(headervalue; allowempty=false)
    
    headervalue = "bird,"
    @test_throws HttpError Spirit.parse_header_value(headervalue; allowempty=false)
    
    headervalue = "bird,,salmon"
    @test_throws HttpError Spirit.parse_header_value(headervalue; allowempty=false)
    
    headervalue = "bird,,salmon"
    parsed = Spirit.parse_header_value(headervalue; allowempty=true)
    @test parsed == Entries([
        "bird" => [
        ],
        "" => [
        ],
        "salmon" => [
        ]
    ])
    
    headervalue = "bird,,salmon"
    parsed = Spirit.parse_header_value(headervalue; allowempty=true, filterempty=true)
    @test parsed == Entries([
        "bird" => [
        ],
        "salmon" => [
        ]
    ])
    
    headervalue = "198"
    parsed = Spirit.parse_header_value(headervalue; permittedchars=Set(UInt8('0'):UInt8('9')))
    @test parsed == Entries([
        "198" => [
        ],
    ])
end
