package main

import (
	"net/http"
)

func main() {
	http.Handle("/a", http.FileServer(http.Dir("/tmp/static/")))
	http.ListenAndServe("127.0.0.1:8090", nil)
}
