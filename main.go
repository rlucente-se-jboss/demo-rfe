package main

import (
	"log"
	"net/http"
)

func main() {
	var count int

	fs := http.FileServer(http.Dir("./"))
	logFileServer := func(w http.ResponseWriter, req *http.Request) {
		count += 1
		log.Printf("%5d %s\n", count, req.URL.Path)
		fs.ServeHTTP(w, req)
	}

	http.HandleFunc("/", logFileServer)

	log.Println("Serving on :8000...")
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Fatal(err)
	}
}
