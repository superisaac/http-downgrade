class HTTPResponse {
    var statusCode: Int
    var headers: [String:String]
    var body: [UInt8]

    init() {
        self.statusCode = 0
        self.body = [UInt8]()
        self.headers = [String:String]()
    }
}
    
    

