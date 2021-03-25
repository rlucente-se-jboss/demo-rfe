package main

import (
	"log"
	"net/http"
)

func main() {
	fs := http.FileServer(http.Dir("./"))
	logFileServer := func(w http.ResponseWriter, req *http.Request) {
		log.Println(req.URL.Path)
		fs.ServeHTTP(w, req)
	}

	http.HandleFunc("/", logFileServer)

	log.Println("Serving on :8000...")
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Fatal(err)
	}
}
