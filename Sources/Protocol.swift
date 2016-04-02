import CUv

internal func alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>(allocatingCapacity:size), UInt32(size))
}

class Protocol {
    var pin:Protocol? = nil
    var stream:UnsafeMutablePointer<uv_stream_t>? = nil
    var writer:UnsafeMutablePointer<uv_write_t>? = nil
    
    init(_ stream:UnsafeMutablePointer<uv_stream_t>) {
        self.stream = stream
        self.writer = UnsafeMutablePointer<uv_write_t>(allocatingCapacity:1)
        self.writer!.pointee.data =  unsafeBitCast(self, to:UnsafeMutablePointer<Void>.self)
    }

    deinit {
        if self.writer != nil {
            self.writer?.deallocateCapacity(1);
        }
    }
    
    func onRead(buf:UnsafePointer<uv_buf_t>, size: Int32) {
        guard size >= 0 else { return }
        self.writeData(buf, size: size)
    }
    
    func writeData(buf: UnsafePointer<uv_buf_t>, size: Int32) {
        var wbuffer = uv_buf_init(buf.pointee.base, UInt32(size))
        uv_write(self.writer!, self.stream!, &wbuffer, 1, Protocol_write_cb)
    }

    func onClose() {
        self.pin = nil
    }

    func onWrite(size: Int32) {
        
    }
}

internal func Protocol_write_cb(handle: UnsafeMutablePointer<uv_write_t>, size: Int32) {
    let proto = unsafeBitCast(handle.pointee.data, to: Protocol.self)
    proto.onWrite(size)
}

internal func Protocol_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
    let proto = unsafeBitCast(stream.pointee.data, to: Protocol.self)
    if size >= 0 {
        proto.onRead(buf, size: Int32(size))
    } else {
        proto.onClose()
    }
}

internal func Protocol_connect_cb(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let loop = uv_default_loop()

    
    let connect = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
    var stream: UnsafeMutablePointer<uv_stream_t> {
        return UnsafeMutablePointer<uv_stream_t>(connect)
    }
    //proto.stream = stream
    let proto = Protocol(stream)
    proto.pin = proto
    
    let _ = uv_tcp_init(loop, connect)
    uv_accept(req, stream)
    uv_read_start(stream, alloc_cb, Protocol_read_cb)
    let unsafeP = unsafeBitCast(proto, to:UnsafeMutablePointer<Void>.self)
    stream.pointee.data = unsafeP
}
