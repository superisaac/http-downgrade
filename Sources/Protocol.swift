import CLibUv

typealias DataCallback = (chunk:[Int8]) -> Void

internal func alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>(allocatingCapacity:size), UInt32(size))
}

class Protocol {
    var pin:Protocol? = nil
    var stream:UnsafeMutablePointer<uv_stream_t>? = nil

    var received:ByteBuffer
    var terminator:[Int8]? = nil
    var dataCallback:DataCallback? = nil
    
    init() {
        self.received = ByteBuffer()
    }

    func onRead(buf:UnsafePointer<uv_buf_t>, size: Int32) {
        guard size >= 0 else { return }
        let chunk = [Int8](repeating:0, count:Int(size))
        memcpy(UnsafeMutablePointer<Int8>(chunk), buf.pointee.base, Int(size))
        self.received.push(chunk)
        self.testReceived()
    }

    func testReceived() {
        guard self.received.size() > 0 else { return }
        
        if self.terminator != nil {
            let terminator = self.terminator!
            let idx = self.received.find(terminator)
            if idx >= 0 {
                let chunk = [Int8](self.received.buffer[0..<idx+terminator.count])
                self.received.shift(idx + terminator.count)
                self.dataCallback?(chunk:chunk)
            }
        }
    }
    
    func writeData(chunk:[Int8], size: Int32 = -1) {
        var sz = size
        if size < 0 {
            sz = (Int32)(chunk.count)
        }
        var wbuffer = uv_buf_init(UnsafeMutablePointer<Int8>(chunk), UInt32(sz))
        let writer = UnsafeMutablePointer<uv_write_t>(allocatingCapacity:1)
        writer.pointee.data =  unsafeBitCast(self, to:UnsafeMutablePointer<Void>.self)

        let r = uv_write(writer, self.stream!, &wbuffer, 1, Protocol_write_cb)
        dieOnUVError(r)
    }

    func writeString(str:String) {
        let arr = stringToArray(str)
        self.writeData(arr)
    }

    func onClose() {
        print("closed")
        self.pin = nil
    }

    func onWrite(writer: UnsafeMutablePointer<uv_write_t>, size: Int32) {
        writer.deallocateCapacity(1);
    }

    func readUntil(terminator:[Int8], _ callback: DataCallback) {
        self.terminator = terminator
        self.dataCallback = callback
        self.testReceived()
    }    
}

internal func Protocol_write_cb(writer: UnsafeMutablePointer<uv_write_t>, size: Int32) {
    let proto = unsafeBitCast(writer.pointee.data, to: Protocol.self)
    proto.onWrite(writer, size: size)
}

internal func Protocol_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
    let proto = unsafeBitCast(stream.pointee.data, to: Protocol.self)
    if size >= 0 {
        proto.onRead(buf, size: Int32(size))
    } else {
        proto.onClose()
    }
}

