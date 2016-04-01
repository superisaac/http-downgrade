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

    
    func didRead(buf:UnsafePointer<uv_buf_t>, size: Int32) {
        guard size >= 0 else { return }
        //let int8Ptr = unsafeBitCast(buf.pointee.base, to: UnsafeMutablePointer<Int8>.self)
        //let line = String(validatingUTF8:int8Ptr)
        //print("read \(size) \(line)")
        // echo
        self.writeData(buf, size: size)
    }
    
    func writeData(buf: UnsafePointer<uv_buf_t>, size: Int32) {
        let currentWrite = UnsafeMutablePointer<uv_write_t>(allocatingCapacity:1)
        defer { currentWrite.deallocateCapacity(1) }
        var wbuffer = uv_buf_init(buf.pointee.base, UInt32(size))
        uv_write(currentWrite, self.stream!, &wbuffer, 1, Protocol_write_cb)
        
        let unsafeP = unsafeBitCast(self, to:UnsafeMutablePointer<Void>.self)
        currentWrite.pointee.data = unsafeP
    }

    func didClose() {
        print("did close")
        self.pin = nil
    }

    func didWrite(size: Int32) {
        print("wrote size \(size)")
    }
}

internal func alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>(allocatingCapacity:size), UInt32(size))
}

internal func Protocol_write_cb(handle: UnsafeMutablePointer<uv_write_t>, size: Int32) {
    //print("wrote \(handle)")
    let proto = unsafeBitCast(handle.pointee.data, to: Protocol.self)
    proto.didWrite(size)
}

internal func Protocol_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
    let proto = unsafeBitCast(stream.pointee.data, to: Protocol.self)
    if size >= 0 {
        proto.didRead(buf, size: Int32(size))
    } else {
        proto.didClose()
    }
}

internal func Protocol_connect_cb(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
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
    uv_read_start(stream, alloc_cb, Protocol_read_cb)
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
    let _ = uv_listen(UnsafeMutablePointer<uv_stream_t>(server), 1000, Protocol_connect_cb)
    
    uv_run(loop, UV_RUN_DEFAULT)
    print("Event loop: \(loop)")
}

main()
