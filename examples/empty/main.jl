push!(LOAD_PATH, pwd())
println(LOAD_PATH);

import Sockets
import Spirit

p = Spirit.pipe()
conn = Sockets.listen(5000)

server = Spirit.HTTPServer(conn, p)

f = @async run(server)

println("Server is running")

wait(f)
