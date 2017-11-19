export HTTPError

struct HTTPError <: Exception
    code::UInt16
    message::AbstractString
    data::Dict{AbstractString, Any}
    safe::Bool
    shouldclose::Bool
end

function HTTPError(code::Integer;
    message::AbstractString="", 
    data::Dict{AbstractString, Any}=Dict{AbstractString, Any}(), 
    safe::Bool=code<500,
    shouldclose::Bool=false)
    
    HTTPError(code, message, data, safe, shouldclose)
end
