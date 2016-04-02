import CUv

func main() {
    let server = TCPServer()
    server.serve("0.0.0.0", port:9999){() -> Protocol in
        print("get protocol")
        return HTTPProtocol()
    }
    server.run()
}

main()
