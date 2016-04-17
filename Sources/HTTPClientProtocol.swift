
class HTTPClientProtocol: Protocol {
    override func onConnected() {
        super.onConnected()
        print("connected")
        self.waitFor(1) {
            (chunk: [UInt8]) in
            print("= \(chunk)")
        }
        self.writeString("GET / HTTP/1.1\r\n")
        self.writeString("Host: localhost:9999\r\n\r\n")
    }    
}
