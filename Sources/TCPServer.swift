import CUv

class TCPServer {
    func run(host:String, port:Int32) {
        let loop = uv_default_loop()
        var server = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
        defer { server.deallocateCapacity(1) }
        let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity:1)
        defer { addr.deallocateCapacity(1) }
    
        let _ = uv_ip4_addr(host, port, addr)
        let _ = uv_tcp_init(loop, server)
        let _ = uv_tcp_bind(server, UnsafePointer<sockaddr>(addr), 0)
        let _ = uv_listen(UnsafeMutablePointer<uv_stream_t>(server), 1000, Protocol_connect_cb)
        uv_run(loop, UV_RUN_DEFAULT)
    }
}
