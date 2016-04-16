typealias LineCallback = (line:String) -> Void

class HTTPServerProtocol: Protocol {
    var request: HTTPRequest

    override init() {
        self.request = HTTPRequest()
        super.init()
    }
    
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
    
    func onStatus(line:String) {
        var statusLine = chomp(line)
        print("status: \(statusLine)")
        let arr = statusLine.utf8.split(separator: 32, maxSplits: 2, omittingEmptySubsequences: true)
        if arr.count != 3 {
            print("Illegal input for http status")
            self.close()
            return
        }
        self.request.method = String(arr[0])!
        self.request.path = String(arr[1])!
        self.request.version = String(arr[2])!
        
        print("path \(self.request.method) \(self.request.path)")
        self.readLine() {
            (line: String) in
            self.onHeaderLine(line)
        }
    }

    func onHeaderLine(line:String) {
        var headerLine = chomp(line)
        print("header: \(headerLine.utf8) \(headerLine.utf8.count)")
        
        if headerLine == "" {
            print("headers \(self.request.headers)")
            self.onHeaders()
        } else {
            let arr = headerLine.utf8.split(separator: 32, maxSplits: 1, omittingEmptySubsequences: true)
            let k = String(arr[0])!
            let v = String(arr[1])!
            self.request.headers[k] = v
        }
    }

    func onHeaders() {
        if self.request.method == "GET" {
            self.writeString("HTTP/1.1 200 OK\r\n\r\nHello\r\n")
            self.close()
        } else {
            weak var wself = self
            self.readUntil(0) {
                (chunk:[UInt8]) in
                wself?.onData(chunk)
            }
        }
    }

    func onData(chunk:[UInt8]) {
        print("on Data \(chunk)")
    }
    
}
