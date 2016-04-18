func main() {
    let loop = EventLoop()
    /*loop.serve("0.0.0.0", port:9999){() -> Protocol in
        print("get protocol")
        return HTTPServerProtocol()
    }*/
    let proto = HTTPClientProtocol(host:"localhost", port:9999, path:"/")
    loop.connect("127.0.0.1", port:9999, proto:proto)

    loop.run()
}

main()
