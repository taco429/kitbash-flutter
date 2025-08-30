package middleware

import (
	"context"
	"net/http"
	"time"

	"kitbash/backend/internal/logger"

	"github.com/go-chi/chi/v5/middleware"
)

// LoggingMiddleware provides structured request logging with timing
func LoggingMiddleware(log *logger.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()

			// Add request ID to context if not present
			ctx := r.Context()
			if middleware.GetReqID(ctx) == "" {
				ctx = context.WithValue(ctx, middleware.RequestIDKey, middleware.NextRequestID())
				r = r.WithContext(ctx)
			}

			// Create a wrapped response writer to capture status code
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

			// Log request start
			log.WithContext(ctx).Debug("Request started",
				"method", r.Method,
				"path", r.URL.Path,
				"query", r.URL.RawQuery,
				"remote_addr", r.RemoteAddr,
				"user_agent", r.UserAgent(),
			)

			// Process request
			next.ServeHTTP(ww, r)

			// Log request completion
			duration := time.Since(start)
			log.LogRequest(r, ww.Status(), duration)

			// Log errors for 4xx and 5xx responses
			if ww.Status() >= 400 {
				log.WithContext(ctx).Warn("HTTP error response",
					"method", r.Method,
					"path", r.URL.Path,
					"status_code", ww.Status(),
					"bytes_written", ww.BytesWritten(),
				)
			}
		})
	}
}

// RecoveryMiddleware provides panic recovery with logging
func RecoveryMiddleware(log *logger.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					log.WithContext(r.Context()).Error("Panic recovered",
						"error", err,
						"method", r.Method,
						"path", r.URL.Path,
						"remote_addr", r.RemoteAddr,
					)

					http.Error(w, "Internal Server Error", http.StatusInternalServerError)
				}
			}()

			next.ServeHTTP(w, r)
		})
	}
}
