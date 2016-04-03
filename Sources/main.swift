import CUv

func main() {
    let loop = EventLoop()
    loop.serve("0.0.0.0", port:9999){() -> Protocol in
        print("get protocol")
        return HTTPProtocol()
    }
    loop.run()
}

main()
