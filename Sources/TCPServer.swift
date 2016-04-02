import CUv

typealias GetProtoCallback = () -> Protocol

internal class ProtocolFactory {
    var getProtocol:GetProtoCallback
    var server:UnsafeMutablePointer<uv_tcp_t>
    
    init(_ getProtocolFn:GetProtoCallback) {
        self.getProtocol = getProtocolFn
        self.server = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
        self.server.pointee.data = unsafeBitCast(self, to:UnsafeMutablePointer<Void>.self)
    }

    deinit {
        self.server.deallocateCapacity(1)
    }
}

internal func Protocol_connect_cb(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let loop = uv_default_loop()
    
    let connect = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
    var stream: UnsafeMutablePointer<uv_stream_t> {
        return UnsafeMutablePointer<uv_stream_t>(connect)
    }
    let protoFactory = unsafeBitCast(req.pointee.data, to:ProtocolFactory.self)
    print("hihi \(protoFactory)")
    let proto = protoFactory.getProtocol()    
    
    proto.stream = stream
    proto.pin = proto
    
    let _ = uv_tcp_init(loop, connect)
    uv_accept(req, stream)
    uv_read_start(stream, alloc_cb, Protocol_read_cb)
    let unsafeP = unsafeBitCast(proto, to:UnsafeMutablePointer<Void>.self)
    stream.pointee.data = unsafeP
}

class TCPServer {
    var factories:[ProtocolFactory]
    init() {
        self.factories = [ProtocolFactory]()
        print("new tcp server")
    }
    
    func serve(host:String, port:Int32, _ getProto: GetProtoCallback) {
        let loop = uv_default_loop()
        let protoFactory = ProtocolFactory(getProto)

        let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity:1)
        defer { addr.deallocateCapacity(1) }
    
        let _ = uv_ip4_addr(host, port, addr)
        let _ = uv_tcp_init(loop, protoFactory.server)
        let _ = uv_tcp_bind(protoFactory.server, UnsafePointer<sockaddr>(addr), 0)
        let _ = uv_listen(UnsafeMutablePointer<uv_stream_t>(protoFactory.server), 1000, Protocol_connect_cb)

        self.factories.append(protoFactory)
    }

    func run() {
        let loop = uv_default_loop()
        uv_run(loop, UV_RUN_DEFAULT)        
    }
}

