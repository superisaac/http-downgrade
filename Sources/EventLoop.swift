import CUv

typealias GetProtocolFn = () -> Protocol

internal class ProtocolFactory {
    var getProtocol:GetProtocolFn
    var server:UnsafeMutablePointer<uv_tcp_t>
    
    init(_ getProtocolFn:GetProtocolFn) {
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

class EventLoop {
    var factories:[ProtocolFactory]
    var loop:UnsafeMutablePointer<uv_loop_t>
    
    init(_ loop:UnsafeMutablePointer<uv_loop_t>?=nil) {
        if loop == nil {
            self.loop = uv_default_loop()
        } else {
            self.loop = loop!
        }
        self.factories = [ProtocolFactory]()
    }

    func serve(host:String, port:Int32, _ getProto: GetProtocolFn) {
        let protoFactory = ProtocolFactory(getProto)

        let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity:1)
        defer { addr.deallocateCapacity(1) }
    
        let _ = uv_ip4_addr(host, port, addr)
        let _ = uv_tcp_init(self.loop, protoFactory.server)
        let _ = uv_tcp_bind(protoFactory.server, UnsafePointer<sockaddr>(addr), 0)
        let _ = uv_listen(UnsafeMutablePointer<uv_stream_t>(protoFactory.server), 1000, Protocol_connect_cb)

        self.factories.append(protoFactory)
    }

    func run() {
        uv_run(self.loop, UV_RUN_DEFAULT)
    }
}

