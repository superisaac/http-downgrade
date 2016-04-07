import CLibUv

internal func alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>(allocatingCapacity:size), UInt32(size))
}

class Protocol {
    var pin:Protocol? = nil
    var stream:UnsafeMutablePointer<uv_stream_t>? = nil
    var writer:UnsafeMutablePointer<uv_write_t>? = nil

    var received:ByteBuffer
    
    init() {
        self.received = ByteBuffer()
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
        let chunk = [Int8](repeating:0, count:Int(size))
        memcpy(UnsafeMutablePointer<Int8>(chunk), buf.pointee.base, Int(size))
        self.writeData(chunk, size: size)
        self.received.push(chunk)
        print("sss \(self.received.buffer)")
        let idx = self.received.find([13, 10])
        if idx >= 0 {
            print("find \(idx)")
            self.received.shift(idx + 2)
        }
    }
    
    func writeData(chunk:[Int8], size: Int32) {
        var wbuffer = uv_buf_init(UnsafeMutablePointer<Int8>(chunk), UInt32(size))
        uv_write(self.writer!, self.stream!, &wbuffer, 1, Protocol_write_cb)
    }

    func onClose() {
        print("closed")
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

