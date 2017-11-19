import Spirit

p = Spirit.pipe()
conn = listen(5000)

server = Spirit.HTTPServer(conn, p)

f = @async run(server)

println("Server is running")

wait(f)
