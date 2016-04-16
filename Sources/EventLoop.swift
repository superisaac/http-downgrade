import CLibUv

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
internal func Protocol_connect_cb(conn: UnsafeMutablePointer<uv_connect_t>, status: Int32) { 
    let proto = unsafeBitCast(conn.pointee.data, to:Protocol.self)
    proto.onConnected()
}

internal func Protocol_connection_cb(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let loop = uv_default_loop()
    
    let connect = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
    var stream: UnsafeMutablePointer<uv_stream_t> {
        return UnsafeMutablePointer<uv_stream_t>(connect)
    }
    let protoFactory = unsafeBitCast(req.pointee.data, to:ProtocolFactory.self)
    let proto = protoFactory.getProtocol()

    proto.server = protoFactory.server
    proto.stream = stream
    proto.pin = proto

    proto.onConnected()
    
    let _ = uv_tcp_init(loop, connect)
    uv_accept(req, stream)
    uv_read_start(stream, alloc_cb, Protocol_read_cb)
    let unsafeP = unsafeBitCast(proto, to:UnsafeMutablePointer<Void>.self)
    stream.pointee.data = unsafeP
}

class EventLoop {
    var protoFactories:[ProtocolFactory]
    var loop:UnsafeMutablePointer<uv_loop_t>
    
    init(_ loop:UnsafeMutablePointer<uv_loop_t>?=nil) {
        if loop == nil {
            self.loop = uv_default_loop()
        } else {
            self.loop = loop!
        }
        self.protoFactories = [ProtocolFactory]()
    }

    func serve(host:String, port:Int32, _ getProto: GetProtocolFn) {
        let protoFactory = ProtocolFactory(getProto)

        let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity:1)
        defer { addr.deallocateCapacity(1) }
    
        var r = uv_ip4_addr(host, port, addr)
        dieOnUVError(r)
        
        r = uv_tcp_init(self.loop, protoFactory.server)
        dieOnUVError(r)

        r = uv_tcp_bind(protoFactory.server, UnsafePointer<sockaddr>(addr), 0)
        dieOnUVError(r)
        
        r = uv_listen(UnsafeMutablePointer<uv_stream_t>(protoFactory.server), 1000, Protocol_connection_cb)
        dieOnUVError(r)
        
        self.protoFactories.append(protoFactory)
    }

    func connect(host:String, port:Int32, proto:Protocol) {
        let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity:1)
        defer { addr.deallocateCapacity(1) }
    
        var r = uv_ip4_addr(host, port, addr)
        dieOnUVError(r)

        let client = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
        //client.pointee.data = unsafeBitCast(self, to:UnsafeMutablePointer<Void>.self)

        r = uv_tcp_init(self.loop, client)
        dieOnUVError(r)

        let conn = UnsafeMutablePointer<uv_connect_t>(allocatingCapacity:1)
        r = uv_tcp_connect(conn, client, UnsafePointer<sockaddr>(addr), Protocol_connect_cb)
        dieOnUVError(r)
        var stream: UnsafeMutablePointer<uv_stream_t> {
            return UnsafeMutablePointer<uv_stream_t>(client)
        }
        proto.stream = stream
        proto.pin = proto
        conn.pointee.data = unsafeBitCast(proto, to:UnsafeMutablePointer<Void>.self)
    }

    func run() {
        uv_run(self.loop, UV_RUN_DEFAULT)
    }
}


