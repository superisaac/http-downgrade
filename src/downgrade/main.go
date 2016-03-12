package main

import (
	"fmt"
	"net/http"
)

func main() {
	//http.Handle("/a/", http.FileServer(http.Dir("/tmp/static/")))
	http.HandleFunc("/bar", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query()
		fmt.Fprintf(w, "hello foo %s", q["who"])
	})
	http.ListenAndServe("127.0.0.1:8090", nil)
}
