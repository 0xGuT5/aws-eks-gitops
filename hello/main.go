package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func newMux(env, host string) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "hello from %s (%s)\n", host, env)
	})

	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	return mux
}

func main() {
	env := os.Getenv("APP_ENV")
	if env == "" {
		env = "local"
	}
	host, _ := os.Hostname()

	log.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", newMux(env, host)))
}
