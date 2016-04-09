import CLibUv

typealias DataCallback = (chunk:[UInt8]) -> Void

internal func alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = initUVBuffer(UnsafeMutablePointer<UInt8>(allocatingCapacity:size), UInt32(size))
}

enum WaitMethod {
case Terminator
case Size     
}

struct WaitSt {
    var method:WaitMethod
    var terminator:[UInt8]?
    var size:Int?
    var callback:DataCallback
}

class Protocol {
    var pin:Protocol? = nil
    var stream:UnsafeMutablePointer<uv_stream_t>? = nil
    var server:UnsafeMutablePointer<uv_tcp_t>? = nil

    var received:ByteBuffer
    var waiters:[WaitSt]
    
    init() {
        self.received = ByteBuffer()
        self.waiters = [WaitSt]()
    }

    func onConnected() {
        
    }
    
    func onRead(buf:UnsafePointer<uv_buf_t>, size: Int32) {
        guard size >= 0 else { return }
        let chunk = [UInt8](repeating:0, count:Int(size))
        memcpy(UnsafeMutablePointer<UInt8>(chunk), buf.pointee.base, Int(size))
        self.received.push(chunk)
        self.testReceived()
    }

    func testReceived() {
        guard self.received.size() > 0 else { return }
        guard self.waiters.count > 0 else { return }

        while self.received.size() >= 0 {
            var waited = false
            for waitst in self.waiters {
                //print("received \(self.received.buffer)")
                if waitst.method == WaitMethod.Terminator {
                    let terminator = waitst.terminator!
                    let idx = self.received.find(terminator)
                    if idx >= 0 {
                        let chunk = [UInt8](self.received.buffer[0..<idx+terminator.count])
                        self.received.shift(idx + terminator.count)
                        waitst.callback(chunk:chunk)
                        waited = true
                    }
                } else {   // .Size
                    if waitst.size! <= 0 {
                        let chunk = self.received.buffer
                        self.received.clean()
                        waitst.callback(chunk: chunk)
                        waited = true
                    } else if self.received.size() >= waitst.size! {
                        let chunk = [UInt8](self.received.buffer[0..<waitst.size!])
                        self.received.shift(waitst.size!)
                        waitst.callback(chunk: chunk)
                        waited = true
                    }
                }
            }
            if !waited {
                break
            }
        }
    }

    func writeData(chunk:[UInt8], size:Int32 = -1) {
        var sz = size
        if size < 0 {
            sz = (Int32)(chunk.count)
        }
        var wbuffer = initUVBuffer(UnsafeMutablePointer<UInt8>(chunk), UInt32(sz))
        let writer = UnsafeMutablePointer<uv_write_t>(allocatingCapacity:1)
        writer.pointee.data =  unsafeBitCast(self, to:UnsafeMutablePointer<Void>.self)

        let r = uv_write(writer, self.stream!, &wbuffer, 1, Protocol_write_cb)
        dieOnUVError(r)
    }

    func writeString(str:String) {
        self.writeData([UInt8](str.utf8))
    }

    func onClose() {
        print("closed")
        self.pin = nil
    }

    func onWrite(writer: UnsafeMutablePointer<uv_write_t>, size: Int32) {
        writer.deallocateCapacity(1);
    }

    func readUntil(terminator:[UInt8], _ callback: DataCallback) {
        self.clearWaiters()
        self.waitFor(terminator, callback)
        self.testReceived()
    }

    func readUntil(size: Int, _ callback: DataCallback) {
        self.clearWaiters()
        self.waitFor(size, callback)
        self.testReceived()
    }

    func clearWaiters() {
        self.waiters.removeAll()
    }
    
    func waitFor(terminator:[UInt8], _ callback:DataCallback) {
        let waitst = WaitSt(method: .Terminator, terminator: terminator, size: nil, callback: callback)
        self.waiters.append(waitst)
    }

    func waitFor(size:Int, _ callback:DataCallback) {
        let waitst = WaitSt(method: .Size, terminator: nil, size: size, callback: callback)
        self.waiters.append(waitst)
    }    


    func close() {
        if self.stream != nil {
            let handle = unsafeBitCast(self.stream!, to: UnsafeMutablePointer<uv_handle_t>.self)
            uv_close(handle, Protocol_close_cb)
        }
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

internal func Protocol_close_cb(handle: UnsafeMutablePointer<uv_handle_t>) {
    // closed
    print("protocol closed")
}
