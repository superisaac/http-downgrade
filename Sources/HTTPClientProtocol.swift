/*class HTTPClientResponse {
    var 
}*/

class HTTPClientProtocol: Protocol {
    override func onConnected() {
        super.onConnected()
        print("connected")
        self.wait() {
            (chunk: [UInt8]) in
            //print("= \(chunk)")
            let data = bytes2String(chunk)
            print("< \(data)")
        }
        self.writeString("GET / HTTP/1.1\r\n")
        self.writeString("Host: localhost:9999\r\n\r\n")
    }    
}
