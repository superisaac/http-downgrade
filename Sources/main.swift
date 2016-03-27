import CUv

let loop = uv_default_loop()
uv_run(loop, UV_RUN_DEFAULT)
print("Event loop: \(loop)")


