import CUv

class Protocol {
    var pin:Protocol? = nil
    var stream:UnsafeMutablePointer<uv_stream_t>? = nil
    
    init() {
        print("haha")
    }

    deinit {
        print("protocol deinit")
    }
    
    func didRead(size: Int, buffer buf: UnsafePointer<uv_buf_t>) {
        guard size >= 0 else { return }
        let int8Ptr = unsafeBitCast(buf.pointee.base, to: UnsafeMutablePointer<Int8>.self)
        let line = String(validatingUTF8:int8Ptr)
        print("read \(size) \(line)")
        // echo 
        let currentWrite = UnsafeMutablePointer<uv_write_t>(allocatingCapacity:1)
        defer { currentWrite.deallocateCapacity(1) }
        //var wbuffer = uv_buf_init_d(buf.pointee.base, UInt32(size))
        var wbuffer = uv_buf_init(int8Ptr, UInt32(size))
        uv_write(currentWrite, self.stream!, &wbuffer, 1, TCPConnection_uv_write_cb)
    }

}

internal func alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>(allocatingCapacity:size), UInt32(size))
}

internal func TCPConnection_uv_write_cb(handle: UnsafeMutablePointer<uv_write_t>, size: Int32) {
    //print("wrote \(size)")
}

internal func TCPConnection_uv_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
    let p = unsafeBitCast(stream.pointee.data, to: Protocol.self)
    p.didRead(size, buffer: buf)
}


func on_new_connection(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let loop = uv_default_loop()

    let proto = Protocol()
    proto.pin = proto
    
    let connect = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
    //defer { connect.deallocateCapacity(1) }
    var stream: UnsafeMutablePointer<uv_stream_t> {
        return UnsafeMutablePointer<uv_stream_t>(connect)
    }
    proto.stream = stream
    
    let _ = uv_tcp_init(loop, connect)
    uv_accept(req, stream)
    uv_read_start(stream, alloc_cb, TCPConnection_uv_read_cb)
    let unsafeP = unsafeBitCast(proto, to:UnsafeMutablePointer<Void>.self)
    stream.pointee.data = unsafeP
}

func main() {
    let loop = uv_default_loop()
    var server = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
    defer { server.deallocateCapacity(1) }
    let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity:1)
    defer { addr.deallocateCapacity(1) }
    
    let _ = uv_ip4_addr([Int8(0),Int8(0),Int8(0),Int8(0)], Int32(9999), addr)
    let _ = uv_tcp_init(loop, server)
    let _ = uv_tcp_bind(server, UnsafePointer<sockaddr>(addr), 0)
    let _ = uv_listen(UnsafeMutablePointer<uv_stream_t>(server), 1000, on_new_connection)
    
    uv_run(loop, UV_RUN_DEFAULT)
    print("Event loop: \(loop)")
}

main()
