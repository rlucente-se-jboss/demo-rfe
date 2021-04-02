package main

import (
	"log"
	"net/http"
	"os"
)

const MiB = 1024 * 1024

func main() {
	var count int
	var total float64

	fs := http.FileServer(http.Dir("./"))
	logFileServer := func(w http.ResponseWriter, req *http.Request) {
		count += 1

		fileInfo, err := os.Stat("." + req.URL.Path)
		if err == nil {
			total += float64(fileInfo.Size()) / MiB
		}

		log.Printf("%5d  %7.3f MiB  %s\n", count, total, req.URL.Path)
		fs.ServeHTTP(w, req)
	}

	http.HandleFunc("/", logFileServer)

	log.Println("Serving on :8000...")
	err := http.ListenAndServe(":8000", nil)
	if err != nil {
		log.Fatal(err)
	}
}
