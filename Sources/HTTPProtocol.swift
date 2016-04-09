typealias LineCallback = (line:String) -> Void

class HTTPProtocol: Protocol {
    func readLine(callback:LineCallback) {
        self.readUntil([UInt8]("\r\n".utf8)) {
            (chunk:[UInt8]) in
            let line = bytes2String(chunk)
            callback(line:line)
        }
    }
    
    override func onConnected() {
        super.onConnected()
        weak var wself = self
        self.readLine() {
            (line: String) in
            wself?.onStatus(line)
        }
    }

    func onStatus(statusLine:String) {
        print("status: \(statusLine)")
        self.readLine() {
            (line: String) in
            self.onHeaderLine(line)
        }
    }

    func onHeaderLine(headerLine:String) {
        print("header: \(headerLine.utf8) \(headerLine.utf8.count) \(headerLine.characters.count)")
        if headerLine.utf8.count == 2 {
            self.writeString("HTTP/1.1 200 OK\r\n\r\nHello\r\n")
            self.close()
        }
    }
}
