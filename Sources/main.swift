func main() {
    let loop = EventLoop()
    /*loop.serve("0.0.0.0", port:9999){() -> Protocol in
        print("get protocol")
        return HTTPServerProtocol()
    }*/
    let proto = HTTPClientProtocol()
    loop.connect("127.0.0.1", port:8000, proto:proto)
    //loop.connect("whatismyip.org", port:80, proto:proto)
    loop.run()
}

main()
