import CLibUv

class ByteBuffer {
    var buffer:[Int8]

    init() {
        self.buffer = [Int8]()
    }

    func push(chunk:[Int8]) {
        self.buffer += chunk
    }

    func size() -> Int {
        return self.buffer.count
    }

    func shift(count:Int) {
        let bufferCount = self.buffer.count
        if bufferCount < 1024 {
            for i in count..<bufferCount {
                self.buffer[i-count] = self.buffer[i]
            }
            for _ in 1...count {
                self.buffer.removeLast()
            }
        } else {
            self.buffer = [Int8](self.buffer[count..<bufferCount])
        }
    }

    func find(sub:[Int8]) -> Int {
        //for (c, index) in self.buffer.enumerate() {
        var index = 0;
        let count = self.buffer.count
        let slen = sub.count
        //self.buffer.count()
        while index <= count - slen {
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
