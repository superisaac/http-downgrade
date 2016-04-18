class HTTPClientProtocol: Protocol {
    var response: HTTPResponse
    var host:String
    var port:Int
    var path:String

    init(host:String, port:Int, path:String) {
        self.response = HTTPResponse()
        self.host = host
        self.port = port
        self.path = path
        super.init()
    }

    override func onConnected() {
        super.onConnected()
        print("connected")
        self.writeString("GET \(self.path) HTTP/1.1\r\n")
        self.writeString("Host: (self.host):(self.port)\r\n\r\n")

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
        //self.response.method = String(arr[0])!
        self.response.statusCode = Int(String(arr[1])!)!
        //self.response.version = String(arr[2])!
        
        self.readLine() {
            (line: String) in
            self.onHeaderLine(line)
        }
    }

    func onHeaderLine(line:String) {
        var headerLine = chomp(line)
        print("header: \(headerLine.utf8) \(headerLine.utf8.count)")
        
        if headerLine == "" {
            print("headers \(self.response.headers)")
            self.onHeaders()
        } else {
            let arr = headerLine.utf8.split(separator: 32, maxSplits: 1, omittingEmptySubsequences: true)
            let k = String(arr[0])!
            let v = String(arr[1])!
            self.response.headers[k] = v
        }
    }

    func onHeaders() {
        weak var wself = self
        self.readUntil(0) {
            (chunk:[UInt8]) in
            wself?.onData(chunk)
        }
    }

    func onData(chunk:[UInt8]) {
        self.response.body += chunk
    }

    override func onClose() {
        let data = bytes2String(self.response.body)
        print("closed \(data)")
        super.onClose()
    }
}
