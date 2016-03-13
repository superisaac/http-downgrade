package main

import (
	"fmt"
	"net/http"
)

func main() {
	//http.Handle("/a/", http.FileServer(http.Dir("/tmp/static/")))
	http.HandleFunc("/bar", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		buf := make([]byte, 0, 10240)
		r.Body.Read(buf)
		fmt.Fprintf(w, "hello foo %s %s %v", q["who"], r.Method, buf)
	})
	http.ListenAndServe("127.0.0.1:8090", nil)
}
