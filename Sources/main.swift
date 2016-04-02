import CUv

func main() {
    let server = TCPServer()
    server.run("0.0.0.0", port:9999)
}

main()
