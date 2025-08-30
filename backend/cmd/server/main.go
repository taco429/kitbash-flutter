package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"kitbash/backend/internal/config"
	"kitbash/backend/internal/httpapi"
	"kitbash/backend/internal/logger"
)

// main loads config, constructs the router, and starts the HTTP server
// with graceful shutdown on SIGINT/SIGTERM.
func main() {
	// Load configuration
	cfg := config.Load()
	logCfg := config.LoadLoggingConfig()

	// Create logger and set as default
	log := logCfg.CreateLogger()
	logger.SetDefault(log)

	log.Info("Starting Kitbash backend server",
		"http_port", cfg.HTTPPort,
		"log_level", logCfg.Level,
		"log_format", logCfg.Format,
		"log_output", logCfg.Output)

	router := httpapi.NewRouter(cfg)

	srv := &http.Server{
		Addr:              ":" + cfg.HTTPPort,
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
	}

	// Start server in goroutine
	go func() {
		log.Info("HTTP server starting", "address", ":"+cfg.HTTPPort)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Error("Server startup failed", "error", err)
			os.Exit(1)
		}
	}()

	log.Info("Server started successfully", "address", ":"+cfg.HTTPPort)

	// Wait for interrupt signal for graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	sig := <-quit

	log.Info("Shutdown signal received", "signal", sig.String())

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	log.Info("Shutting down server...")
	if err := srv.Shutdown(ctx); err != nil {
		log.Error("Graceful shutdown failed", "error", err)
		os.Exit(1)
	}

	log.Info("Server shutdown complete")
}
