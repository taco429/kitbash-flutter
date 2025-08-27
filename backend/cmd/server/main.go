package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "kitbash/backend/internal/config"
    "kitbash/backend/internal/httpapi"
)

func main() {
    cfg := config.Load()

    router := httpapi.NewRouter(cfg)

    srv := &http.Server{
        Addr:              ":" + cfg.HTTPPort,
        Handler:           router,
        ReadHeaderTimeout: 10 * time.Second,
    }

    go func() {
        log.Printf("backend listening on :%s", cfg.HTTPPort)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("server error: %v", err)
        }
    }()

    // graceful shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    if err := srv.Shutdown(ctx); err != nil {
        log.Printf("graceful shutdown failed: %v", err)
    }
}

