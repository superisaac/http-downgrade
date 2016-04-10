
class HTTPRequest {
    var method:String?
    var path:String?
    var headers: [String:String]

    init() {
        self.headers = [String:String]()
    }
}
