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
