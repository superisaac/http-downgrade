
class HTTPClientProtocol: Protocol {
    override func onConnected() {
        super.onConnected()
        print("connected")
        self.waitFor(1) {
            (chunk: [UInt8]) in
            print("= \(chunk)")
        }
        self.writeString("GET / HTTP/1.1\r\nHost: localhost:8000\r\n\r\n")
    }    
}
