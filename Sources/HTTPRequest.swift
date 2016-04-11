
class HTTPRequest {
    var method:String
    var path:String
    var version:String
    var headers: [String:String]

    init() {
        self.method = ""
        self.path = ""
        self.version = ""
        self.headers = [String:String]()
    }
}
