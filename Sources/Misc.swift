import Glibc
import CLibUv

func dieOnUVError(err:Int32) {
    if err < 0 {
        let errname = String.init(validatingUTF8:uv_err_name(err))!
        let errmsg = String.init(validatingUTF8:uv_strerror(err))!
        print("ERROR/\(errname): \(errmsg)")
        exit(0)
    }
}

func initUVBuffer(buf: UnsafeMutablePointer<Void>, _ len: UInt32) -> uv_buf_t {
    let buffer = unsafeBitCast(buf, to: UnsafeMutablePointer<Int8>.self)
    return uv_buf_init(buffer, len)
}

func bytes2String(data: [UInt8]) -> String {
    var chars = data.map{ Int8(bitPattern:$0)}
    chars.append(0)
    return String(validatingUTF8:chars)!
}

func chomp(line:String) -> String {
    if String(line.utf8.suffix(2)) == "\r\n" {
        return String(line.utf8.dropLast(2))
    } else if (String(line.utf8.suffix(1)) == "\n") {
        return String(line.utf8.dropLast(1))
    } else {
        return line
    }
}
