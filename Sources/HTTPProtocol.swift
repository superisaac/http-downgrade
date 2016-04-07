class HTTPProtocol: Protocol {
    override init() {
        super.init()
        weak var wself = self
        self.readUntil([UInt8]("\r\n".utf8)) {
            (chunk:[UInt8]) in
            //wself?.writeData([69, 99, 104, 111, 58])
            wself?.writeString("ECHO: ")
            //wself?.writeData(([UInt8])(Array("ECHO: ".utf8)) + chunk)
            wself?.writeData(chunk)
        }
    }
}
