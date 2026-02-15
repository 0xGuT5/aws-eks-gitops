package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthz(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()

	newMux("test", "box").ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rr.Code)
	}
}

func TestRoot(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()

	newMux("dev", "box-1").ServeHTTP(rr, req)

	body := rr.Body.String()
	if !strings.Contains(body, "box-1") || !strings.Contains(body, "dev") {
		t.Fatalf("unexpected body: %q", body)
	}
}
