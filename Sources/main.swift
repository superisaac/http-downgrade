import CUv

internal func Caramel_uv_alloc_cb(handle: UnsafeMutablePointer<uv_handle_t>, size: size_t, buf: UnsafeMutablePointer<uv_buf_t>) {
    buf.pointee = uv_buf_init(UnsafeMutablePointer<Int8>(allocatingCapacity:size), UInt32(size))
}

// internal func uv_buf_init_d(buf: UnsafeMutablePointer<Void>, _ len: UInt32) -> uv_buf_t {
//     let buffer = unsafeBitCast(buf, to: UnsafeMutablePointer<Int8>.self)
//     return uv_buf_init(buffer, len)
// }

internal func TCPConnection_uv_write_cb(handle: UnsafeMutablePointer<uv_write_t>, size: Int32) {
    print("wrote \(size)")
}

internal func TCPConnection_uv_read_cb(stream: UnsafeMutablePointer<uv_stream_t>, size: Int, buf: UnsafePointer<uv_buf_t>) {
    //let ptr = stream.pointee.data
    //let cb = unsafeBitCast(ptr, TCPConnectionUVReadCallbackClosureBox.self).callback
    //cb(stream, size, buf)
    //let line = withUnsafePointer(buf.pointee.base, { (ptr) -> String? in
    let int8Ptr = unsafeBitCast(buf.pointee.base, to: UnsafeMutablePointer<Int8>.self)
    let line = String(validatingUTF8:int8Ptr)
    print("read \(size) \(line)")

    // echo 
    let currentWrite = UnsafeMutablePointer<uv_write_t>(allocatingCapacity:1)
    defer { currentWrite.deallocateCapacity(1) }
    //var wbuffer = uv_buf_init_d(buf.pointee.base, UInt32(size))
    var wbuffer = uv_buf_init(int8Ptr, UInt32(size))
    uv_write(currentWrite, stream, &wbuffer, 1, TCPConnection_uv_write_cb)
}


func on_new_connection(req: UnsafeMutablePointer<uv_stream_t>, status: Int32) {
    let loop = uv_default_loop()
    let client = UnsafeMutablePointer<uv_tcp_t>(allocatingCapacity:1)
    defer { client.deallocateCapacity(1) }
    var clientStream: UnsafeMutablePointer<uv_stream_t> {
                                         return UnsafeMutablePointer<uv_stream_t>(client)
                 }
                                      
    let _ = uv_tcp_init(loop, client)
    uv_accept(req, clientStream)
    uv_read_start(clientStream, Caramel_uv_alloc_cb, TCPConnection_uv_read_cb)
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
