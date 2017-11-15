export HttpError

struct HttpError <: Exception
    code::UInt16
    message::AbstractString
    data::Dict{AbstractString, Any}
    safe::Bool
    shouldclose::Bool
end

function HttpError(code::Integer;
    message::AbstractString="", 
    data::Dict{AbstractString, Any}=Dict{AbstractString, Any}(), 
    safe::Bool=code<500,
    shouldclose::Bool=false)
    
    HttpError(code, message, data, safe, shouldclose)
end
