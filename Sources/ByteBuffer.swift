import CLibUv

class ByteBuffer {
    var buffer:[Int8]

    init() {
        self.buffer = [Int8]()
    }

    func push(chunk:[Int8]) {
        self.buffer += chunk
    }

    func pop(count:Int) {
        let len = self.buffer.count - count
        var newBuffer = [Int8](repeating:0, count:len)
        //self.buffer = self.buffer[count..<len]
        for i in count...(self.buffer.count) {
            newBuffer[i-count] = self.buffer[i]
        }
        self.buffer = newBuffer
    }

    func find(sub:[Int8]) -> Int {
        //for (c, index) in self.buffer.enumerate() {
        var index = 0;
        let count = self.buffer.count
        let slen = sub.count
        //self.buffer.count()
        while index < count - slen {
            var found = true
            for (j, c) in sub.enumerated() {
                if self.buffer[index+j] != c {
                    found = false
                    break
                }
            }
            if found {
                return index
            }
            index += 1
        }
        return -1
    }
}
