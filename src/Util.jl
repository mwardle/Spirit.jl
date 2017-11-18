export parse_header_value

const NOOP = (args...) -> nothing
const IDENTITY = (v, args...) -> v

function parse_header_value(header::AbstractString; headername::AbstractString="", parameterized=true, multi=true, paramsep=UInt8(';'), permittedchars=TOKEN, allowempty=false, filterempty=false)
    paramsep = UInt8(paramsep)
    
    const Param = Pair{AbstractString,AbstractString}
    const Params = Vector{Param}
    const Entry = Pair{AbstractString,Params}
    const Entries = Vector{Entry}
    entries = Entries()
    header = string(header)
    value = ""
    paramkey = ""
    paramval = ""
    params = Params()
    
    buff = Vector{UInt8}()
    
    lws = true
    tws = false
    inquote = false
    inescape = false
    parsingparamkey = false
    parsingparamval = false
    const EOF = nothing
    const maxind = length(header)+1
    for i in 1:maxind
        char = i == maxind ? EOF : UInt8(header[i])
        if (lws || tws) && in(char, LWS)
            continue
        elseif inquote && char != EOF
            if inescape
                # TODO: not any character can be quoted...
                push!(buffer, char)
                inescape = false
            elseif b == QUOTE
                inquote = false
                tws = true
            elseif b == BACKSLASH
                inescape = true
            elseif in(b, TEXT)
                push!(buffer, char)
            else
                throw(HttpError(400; message="Invalid $headername header (charcode $char not allowed in quoted-string)"))
            end
        elseif char == EOF || (multi && char == COMMA)
            if parsingparamval
                paramval = String(buff)
                push!(params, paramkey => paramval)
            elseif parsingparamkey
                paramkey = String(buff)
                push!(params, paramkey => paramval)
            else
                value = String(buff)
            end
            
            add = true
            if length(value) == 0
                if !allowempty
                    throw(HttpError(400; message="Invalid $headername header (empty value)"))
                elseif filterempty
                    add = false
                end
            end
            
            if add
                push!(entries, value => params)
            end
            buff = Vector{UInt8}()
            params = Params()
            value = ""
            paramkey = ""
            paramval = ""
            parsingparamkey = false
            parsingparamval = false
            tws = false
            lws = true
        elseif parameterized && char == paramsep
            if parsingparamval
                paramval = String(buff)
                push!(params, paramkey => paramval)
            elseif parsingparamkey
                paramkey = String(buff)
                push!(params, paramkey => paramval)
            else
                value = String(buff)
            end
            if length(value) == 0 && !allowempty
                throw(HttpError(400; message="Invalid $headername header (empty value)"))
            end
            buff = Vector{UInt8}()
            parsingparamkey = true
            parsingparamval = false
            paramkey = ""
            paramval = ""
            lws = true
            tws = false
        elseif parsingparamkey
            if char == EQUAL
                paramkey = String(buff)
                buff = Vector{UInt8}()
                parsingparamkey = false
                parsingparamval = true
                tws = false
                lws = true
            else
                if tws
                    throw(HttpError(400; message="Invalid $headername header (invalid parameter key)"))
                elseif in(char, TOKEN)
                    push!(buff, char)
                elseif in(char, LWS)
                    tws = true
                else
                    throw(HttpError(400; message="Invalid $headername header (invalid parameter key)"))
                end
                lws=false
            end
        elseif parsingparamval
            if lws && char == QUOTE
                inquote = true
            elseif tws
                throw(HttpError(400; message="Invalid $headername header (invalid parameter value)"))
            elseif in(char, TOKEN)
                push!(buff, char)
            elseif in(char, LWS)
                tws = true
            else
                throw(HttpError(400; message="Invalid $headername header (invalid parameter value)"))
            end
            lws=false
        elseif tws
            throw(HttpError(400; message="Invalid $headername header (invalid value)"))
        elseif in(char, permittedchars)
            push!(buff, char)
            lws = false
            tws = false
        elseif in(char, LWS)
            tws = true
        else
            throw(HttpError(400; message="Invalid $headername header (unpermitted bytecode)"))
        end
    end
    
    entries
end
