export Connection, readrequestline!, readheaders!, readbody!

const DEFAULT_MAX_HEADER = UInt64(80 * 1024)
const DEFAULT_MAX_TRAILER = UInt64(20 * 1024)
const DEFAULT_MAX_BODY = typemax(UInt64)
const DEFAULT_MAX_URI = UInt64(8000)
const DEFAULT_MAX_METHOD = UInt64(16)
const DEFAULT_MAX_VERSION = UInt64(10)

const OCTETS = Set(UInt8(0):UInt8(255))
const CHAR = Set(UInt8(0):UInt8(127))
const VCHAR = Set(UInt8(0x21):UInt8(0x7E))  # visible characters
const UCALPHA = Set(UInt8('A'):UInt8('Z'))
const LCALPHA = Set(UInt8('a'):UInt8('z'))
const ALPHA = union(UCALPHA, LCALPHA)
const DIGIT = Set(UInt8('0'):UInt8('9'))
const CTL = union(Set(UInt8(0):UInt8(39)), Set((UInt8(127))))

const CR = UInt8('\r')
const LF = UInt8('\n')
const SP = UInt8(' ')
const HT = UInt8('\t')
const QUOTE = UInt8('"')
const BACKSLASH = UInt8('\\')   # used for escapes in strings and comments
const LEFTPAREN = UInt8('(')           # used for beginning of comments in some headers
const RIGHTPAREN = UInt8(')')           # used for end of comments in some headers
const COLON = UInt8(':')
const COMMA = UInt8(',')
const EQUAL = UInt8('=')
const LWS = Set([SP,HT])
const TEXT = union(setdiff(OCTETS, CTL), LWS)
const HEX = union(DIGIT, Set(Vector{UInt8}("abcdefABCDEF")))
const SEPARATOR = Set(Vector{UInt8}("()<>@,;:\\\"/[]?={} \t"))
# const TOKEN = setdiff(setdiff(CHAR, SEPARATOR), CTL)
const TOKEN = union(Set(Vector{UInt8}("!#\$%&'*+-.^_`|~")), ALPHA, DIGIT)

const URI_GENDELIMS = Set(Vector{UInt8}(":/?#[]@"))
const URI_SUBDELIMS = Set(Vector{UInt8}("!\$&'()*+,;="))
const URI_RESERVED = union(URI_GENDELIMS, URI_SUBDELIMS)
const URI_UNRESERVED = union(ALPHA, DIGIT, Set(Vector{UInt8}("-._~")))
const URI_CHARS = union(URI_RESERVED, URI_UNRESERVED)

const CRLF = [UInt8('\r'), UInt8('\n')]

const V1_0 = Vector{UInt8}("1.0")
const V1_1 = Vector{UInt8}("1.1")
const V2_0 = Vector{UInt8}("2.0")

const GENERAL_HEADER_FIELDS = [
    "cache-control",
    "connection",
    "date",
    "pragma",
    "trailer",
    "transfer-encoding",
    "upgrade",
    "via",
    "warning"
]

const COMMENTABLE_HEADER_FIELDS = Set([
    "user-agent",
    "server",
    "via"
])

mutable struct Connection
    socket::IO
    method::String
    uri::String
    httpversion::String
    rawheaders::Vector{Pair{String,String}}
    headers::Headers
    bodystream::IO
    rawtrailers::Vector{Pair{String,String}}
    trailers::Headers
    
    requestlineread::Bool
    headersread::Bool
    bodystartedread::Bool
    bodyfullyread::Bool
    responsesent::Bool
end

function Connection(socket::IO)
    Connection(socket, 
        "", 
        "", 
        "", 
        Vector{Pair{String,String}}(),
        Headers(),
        IOBuffer(""),
        Vector{Pair{String,String}}(),
        Headers(),
        false,
        false,
        false,
        false,
        false)
end

function readrequestline!(connection::Connection; maxuri=DEFAULT_MAX_URI, maxmethod=DEFAULT_MAX_METHOD, maxversion=DEFAULT_MAX_VERSION, strict=false)
    if !isequal(false, connection.requestlineread)
        throw(HTTPError(500; message="Cannot read http connection request line when it has already been read", shouldclose=true))
    end
    
    connection.requestlineread = true
    method = Vector{UInt8}()
    uri = Vector{UInt8}()
    version = Vector{UInt8}()
    socket = connection.socket
    foundend = false
    
    # parse the method
    ind = 1
    while isopen(socket) && !eof(socket)
        b = read(socket, UInt8)
        if b == CR && ind == 1 && !strict
            # https://tools.ietf.org/html/rfc7230#section-3.5 (robustness)
            # this is technically wrong, but expected bad behavior
            ind += 1
            b = read(socket, UInt8)
            if b != LF
                throw(HTTPError(400; message="Invalid character in http method", shouldclose=true))
            end
            ind += 1
        end
        if b == SP
            # method is done
            if length(method) == 0
                throw(HTTPError(400; message="Missing http method", shouldclose=true))
            end
            break
        end
        if ind > maxmethod
            throw(HTTPError(405; message="Unwilling to accept methods longer than $maxheader bytes", shouldclose=true))
        end
        if !in(b, TOKEN)
            throw(HTTPError(400; message="Invalid character in http method", shouldclose=true))
        end
        push!(method, b)
        ind += 1
    end
    
    ind = 1
    while isopen(socket)
        b = read(socket, UInt8)
        if b == SP
            # method is done
            break
        end
        if ind > maxuri
            throw(HTTPError(414; message="Unwilling to accept a uri longer than $maxuri bytes", shouldclose=true))
        end
        if !in(b, URI_CHARS)
            throw(HTTPError(400; message="Invalid character in uri", shouldclose=true))
        end
        push!(uri, b)
        ind += 1
    end
    
    ind = 1
    founddot = false
    while isopen(socket)
        b = read(socket, UInt8)
        if (ind < 6)
            if ind == 1 && b != UInt8('H')
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            elseif (ind == 2 || ind == 3) && b != UInt8('T')
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            elseif ind == 4 && b != UInt8('P')
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            elseif ind == 5 && b != UInt8('/')
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            end
        elseif b == UInt8('.')
            if founddot
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            end
            
            founddot = true
            push!(version, b)
        elseif b == CR
            if !founddot
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            end
            
            b = read(socket, UInt8)
            if b != LF
                throw(HTTPError(400; message="Invalid request line (line terminator)", shouldclose=true))
            end
            
            foundend = true
            
            break
        elseif b == LF
            if strict
                throw(HTTPError(400; message="Invalid request line (line terminator)", shouldclose=true))
            end
            
            if !founddot
                throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
            end
            
            foundend = true
            break
            
        elseif !in(b, DIGIT)
            throw(HTTPError(400; message="Invalid http version text", shouldclose=true))
        else
            push!(version, b)
        end
        
        if (ind > maxversion)
            throw(HTTPError(505; message="Unwilling to accept a version string longer than $maxversion bytes long", shouldclose=true))
        end
        ind += 1
    end
    
    if !foundend
        throw(HTTPError(400; message="Unexpected end of file", shouldclose=true))
    end
    connection.method = String(method)
    connection.uri = String(uri)
    # copy here is necessary because `String` method seems to be consuming contents of the byte array
    # this has to be a big in Julia
    connection.httpversion = String(copy(version))

    if version != V1_0 && version != V1_1
        # TODO: support HTTP/2.0
        throw(HTTPError(505, message="HTTP Version not supported", shouldclose=true))
    end
    return connection
end

function processheaders!(connection::Connection; maxheader=DEFAULT_MAX_HEADER, keepcomments=true, strict=false)
    headers = Vector{Pair{String,String}}()
    headername = Vector{UInt8}()
    headervalue = Vector{UInt8}()
    foundend = false
    foundcolon = false
    instring = false
    commentlevel = 0
    socket = connection.socket
    ind = 1
    while isopen(socket)
        
        b = read(socket, UInt8)
        
        if foundcolon && length(headervalue) == 0 && commentlevel == 0 && !instring
            # trim leading white space for value
            while in(b, LWS)
                b = read(socket, UInt8)
                if ind > maxheader
                    throw(HTTPError(431; message="Unwilling to process headers with total size greater than $maxheaders bytes", shouldclose=true))
                end
                ind += 1
            end
        end
        
        if b == CR
            b = read(socket, UInt8)
            if b != LF
                throw(HTTPError(400; message="Invalid header line (line terminator)", shouldclose=true))
            elseif instring
                throw(HTTPError(400; message="Invalid header line (unterminated quoted string)", shouldclose=true))
            elseif commentlevel != 0
                throw(HTTPError(400; message="Invalid header line (unterminated comment)", shouldclose=true))
            elseif !foundcolon
                if length(headername) == 0
                    # last header found
                    foundend = true
                    break
                else
                    throw(HTTPError(400; message="Invalid header line (missing name separator)", shouldclose=true))
                end
            end
            
            push!(headers, String(headername) => String(headervalue))
            
            headername = Vector{UInt8}()
            headervalue = Vector{UInt8}()
            foundcolon = false
        elseif b == LF
            if strict
                throw(HTTPError(400; message="Invalid header line (line terminator)", shouldclose=true))
            elseif instring
                throw(HTTPError(400; message="Invalid header line (unterminated quoted string)", shouldclose=true))
            elseif commentlevel != 0
                throw(HTTPError(400; message="Invalid header line (unterminated comment)", shouldclose=true))
            elseif !foundcolon
                if length(headername) == 0
                    # last header found
                    foundend = true
                    break
                else
                    throw(HTTPError(400; message="Invalid header line (missing name separator)", shouldclose=true))
                end
            end
            
            push!(headers, String(headername) => String(headervalue))
            
            headername = Vector{UInt8}()
            headervalue = Vector{UInt8}()
            foundcolon = false
        elseif !foundcolon
            if b == COLON
                foundcolon = true
            elseif !in(b, TOKEN)
                throw(HTTPError(400; message="Invalid character in header name (charcode $b)", shouldclose=true))
            else
                push!(headername, b)
            end
        else
            if !instring && commentlevel == 0 && in(b, LWS)
                # TODO: LWS is only valid after or before a separator in a non-text header field
                #       or as part of a text header field.  If it is part of a text header
                #       field, should it be condensed?  Really don't want to backtrack to
                #       condense this after the fact.  Also, want to be consistent. So,
                #       probably always condense, or never condense.  Maybe allow this as
                #       an option.
                while in(b, LWS)
                    b = read(socket, UInt8)
                    if ind > maxheader
                        throw(HTTPError(431; message="Unwilling to process headers with size greater than $maxheaders bytes", shouldclose=true))
                    end
                    ind += 1
                end
                
                if b == CR
                    #  Trailing whitespace may be ignored
                    b = read(socket, UInt8)
                    if b != LF
                        throw(HTTPError(400; message="Invalid header line (line terminator)", shouldclose=true))
                    end
                    push!(headers, String(headername) => String(headervalue))
                    
                    headername = Vector{UInt8}()
                    headervalue = Vector{UInt8}()
                    foundcolon = false
                    continue
                elseif b == LF
                    if strict
                        throw(HTTPError(400; message="Invalid header line (line terminator)", shouldclose=true))
                    end
                    push!(headers, String(headername) => String(headervalue))
                    headername = Vector{UInt8}()
                    headervalue = Vector{UInt8}()
                    foundcolon = false
                    continue
                else
                    # Per rfc2616 section 4.2, multiple whitespace LWS characters may
                    # be replaced by a single space character without altering its meaning
                    push!(headervalue, SP)
                end
            end
            
            if instring
                if b == QUOTE
                    push!(headervalue, b)
                    instring = false
                elseif b == BACKSLASH
                    # quoted pair
                    ind += 1
                    push!(headervalue, b)
                    b = read(socket, UInt8)
                    if !in(b, CHAR)
                        throw(HTTPError(400; message="Invalid quoted pair when parsing header value quoted string (charcode $b)", shouldclose=true))
                    end
                    push!(headervalue, b)
                elseif !in(b, TEXT)
                    throw(HTTPError(400; message="Invalid character when parsing header value quoted string (charcode $b)", shouldclose=true))
                else
                    push!(headervalue, b)
                end
            elseif commentlevel != 0
                if b == RIGHTPAREN
                    if keepcomments
                        push!(headervalue, b)
                    end
                    commentlevel -= 1
                elseif b == LEFTPAREN
                    if keepcomments
                        push!(headervalue, b)
                    end
                    commentlevel += 1
                elseif b == BACKSLASH
                    # quoted pair
                    if keepcomments
                        push!(headervalue, b)
                    end                    
                    ind += 1
                    b = read(socket, UInt8)
                    if !in(b, CHAR)
                        throw(HTTPError(400; message="Invalid quoted pair when parsing header value comment (charcode $b)", shouldclose=true))
                    end
                    if keepcomments
                        push!(headervalue, b)
                    end                
                elseif !in(b, TEXT)
                    throw(HTTPError(400; message="Invalid character when parsing header value comment (charcode $b)", shouldclose=true))
                else
                    if keepcomments
                        push!(headervalue, b)
                    end
                end
            elseif b == QUOTE
                # TODO: This is not valid in the middle of a text header field
                push!(headervalue, b)
                instring = true
            elseif b == LEFTPAREN && in(lowercase(String(copy(headername))), COMMENTABLE_HEADER_FIELDS)
                # Dirty dirty bug consumes my 
                if keepcomments
                    push!(headervalue, b)
                end
                commentlevel += 1
            elseif !in(b, TEXT) && !in(b, CTL)
                throw(HTTPError(400; message="Invalid character when parsing header value (charcode $b)", shouldclose=true))
            else
                # Per the spec the value may be *TEXT or combinations
                # of token, separators, and quoted-string.
                # We aren't really handling these two divergent possibilities here.
                # Currently, we are only validating that it MAY be consistent with one of these
                # two possibilities based on the characters given.  Enforcing a strict mode
                # where only one possibility is allowed is a TODO
                push!(headervalue, b)
            end
        end
        
        if ind > maxheader
            throw(HTTPError(431; message="Unwilling to process headers with size greater than $maxheaders bytes", shouldclose=true))
        end
        ind += 1
    end
    
    if !foundend
        throw(HTTPError(400; message="Unexpected end of stream", shouldclose=true))
    end
    
    headers
end

function readheaders!(connection::Connection; maxheader=DEFAULT_MAX_HEADER, keepcomments=true, strict=false)
    if !isequal(false, connection.headersread)
        throw(HTTPError(500, message="Cannot read http connection headers when they have already been read", shouldclose=true))
    end
    
    connection.headersread = true
    
    if isequal(false, connection.requestlineread)
        throw(HTTPError(500, message="Cannot read http connection headers before the requestline has been read", shouldclose=true))
    end
    
    headers = processheaders!(connection; maxheader=maxheader, keepcomments=keepcomments, strict=strict)
    connection.rawheaders = headers
    connection.headers = Headers(headers...)
    
    connection
end

function readtrailers!(connection::Connection; maxtrailer=DEFAULT_MAX_TRAILER, keepcomments=true, strict=false)
    if !connection.bodyfullyread
        throw(HTTPError(500, message="Cannot read http connection trailers when the body has not been processed", shouldclose=true))
    end
    
    trailers = processheaders!(connection; maxheader=maxtrailer, keepcomments=keepcomments, strict=strict)
    connection.rawtrailers = trailers
    connection.trailers = Headers(trailers...)
    
    connection
end

function createbodystream!(connection::Connection; maxbody=DEFAULT_MAX_BODY, maxtrailer=DEFAULT_MAX_TRAILER)
    if isequal(false, connection.headersread)
        throw(HTTPError(500; message="Cannot read body before headers have been parsed", shouldclose=true))
    end
    
    if isequal(true, connection.bodystartedread)
        throw(HTTPError(500; message="Cannot read body twice", shouldclose=true))
    end
    
    headers = connection.headers
    
    function onstart()
        connection.bodystartedread = true
    end
    
    function makesizedstream()
        lengths = []
        try
            lengths = parse_header_value(headers["Content-Length"]; parameterized=false, permittedchars=DIGIT)
        catch e
            throw(HTTPError(400; message="Invalid Content-Length header (invalid syntax)", shouldclose=true))
        end
        
        function iterator(res, pair)
            (v,) = pair
            try
                v = parse(UInt64, v, base=10)
            catch e
                throw(HTTPError(400; message="Invalid Content-Length header (field value must be a decimal number)", shouldclose=true))
            end
            if res == nothing || res == v
                v
            else
                throw(HTTPError(400; message="Invalid Content-Length header (multiple values do not match)", shouldclose=true))
            end
        end
        length = reduce(iterator, lengths; init=nothing)
        if length > maxbody
            throw(HTTPError(413; message="Content-Length too large", shouldclose=true))
        end
        function ondone()
            connection.bodyfullyread = true
        end
        connection.bodystream = SizedStream(connection.socket, length; ondone=ondone, onstart=onstart)
    end
    
    if haskey(headers, "Transfer-Encoding")
        encodings = nothing
        try
            # can extension encodings be parameterized?
            encodings = parse_header_value(headers["Transfer-Encoding"])
        catch e
            throw(HTTPError(400; message="Invalid Transfer-Encoding header (invalid syntax)", shouldclose=true))
        end
        hastransferencoding = reduce((res, encoding) -> res || (first(encoding) == "chunked"), encodings; init = false)
        if !hastransferencoding && haskey(headers, "Content-Length")
            makesizedstream()
        elseif first(encodings[end]) != "chunked"
            throw(HTTPError(400; message="Invalid Transfer-Encoding header (chunked must be the last value)", shouldclose=true))
        else
            function ondone()
                connection.bodyfullyread = true
                readtrailers!(connection; maxtrailer=maxtrailer)
            end
            connection.bodystream = ChunkedTransferDecodeStream(connection.socket; maxsize=maxbody, ondone=ondone, onstart=onstart)
        end
    elseif haskey(headers, "Content-Length")
        makesizedstream()
    else
        # no body
        connection.bodyfullyread = true
        connection.bodystartedread = true
    end
    
    connection
end

function processrequest!(connection::Connection;
    maxheader=DEFAULT_MAX_HEADER, 
    maxuri=DEFAULT_MAX_URI, 
    maxmethod=DEFAULT_MAX_METHOD, 
    maxversion=DEFAULT_MAX_VERSION,
    maxbody=DEFAULT_MAX_BODY,
    maxtrailer=DEFAULT_MAX_TRAILER,
    keepcomments=true,
    strict=false)
    
    readrequestline!(connection; maxuri=maxuri, maxmethod=maxmethod, maxversion=maxversion, strict=strict)
    readheaders!(connection; maxheader=maxheader, strict=strict)
    createbodystream!(connection; maxbody=maxbody, maxtrailer=maxtrailer)
    
    connection
end

function writeresponse!(connection::Connection, statusCode::Integer, statusReason::AbstractString, headers::Headers, body::IO)
    if connection.responsesent
        warn("Response has already been sent")
        return connection
    end
    statusCode = UInt16(statusCode)
    socket = connection.socket
    write(socket, "HTTP/1.1")
    write(socket, SP)
    write(socket, string(statusCode))
    write(socket, SP)
    write(socket, string(statusReason))
    write(socket, CRLF)
    
    for (name,value) in headers
        write(socket, name)
        write(socket, COLON)
        write(socket, SP)
        write(socket, value)
        write(socket, CRLF)
    end
    
    write(socket, CRLF)
    
    while !eof(body)
        write(socket, read(body, UInt8))
    end
    
    connection.responsesent = true
    
    connection
end
