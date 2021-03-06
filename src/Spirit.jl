module Spirit
using Sockets
using Distributed

const Nullable{T} = Union{T,Nothing}
include("./constants.jl")
include("./HTTPError.jl")
include("./URI.jl")
include("./Headers.jl")
include("./SizedStream.jl")
include("./ChunkedTransferDecodeStream.jl")
include("./Connection.jl")
include("./Continuation.jl")
include("./Pipeline.jl")
include("./Request.jl")
# include("./Response.jl")
include("./Util.jl")
include("./HTTPServer.jl")
end # module Spirit
