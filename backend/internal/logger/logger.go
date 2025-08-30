package logger

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5/middleware"
)

// LogLevel represents different log levels
type LogLevel string

const (
	LevelDebug LogLevel = "DEBUG"
	LevelInfo  LogLevel = "INFO"
	LevelWarn  LogLevel = "WARN"
	LevelError LogLevel = "ERROR"
)

// Logger wraps slog.Logger with additional context and methods
type Logger struct {
	*slog.Logger
}

// New creates a new logger with structured JSON output
func New(level LogLevel, output io.Writer) *Logger {
	if output == nil {
		output = os.Stdout
	}

	var slogLevel slog.Level
	switch level {
	case LevelDebug:
		slogLevel = slog.LevelDebug
	case LevelInfo:
		slogLevel = slog.LevelInfo
	case LevelWarn:
		slogLevel = slog.LevelWarn
	case LevelError:
		slogLevel = slog.LevelError
	default:
		slogLevel = slog.LevelInfo
	}

	opts := &slog.HandlerOptions{
		Level:     slogLevel,
		AddSource: true,
	}

	handler := slog.NewJSONHandler(output, opts)
	logger := slog.New(handler)

	return &Logger{Logger: logger}
}

// NewDefault creates a logger with INFO level and stdout output
func NewDefault() *Logger {
	return New(LevelInfo, os.Stdout)
}

// WithContext adds context fields to the logger
func (l *Logger) WithContext(ctx context.Context) *Logger {
	if reqID := middleware.GetReqID(ctx); reqID != "" {
		return &Logger{Logger: l.Logger.With("request_id", reqID)}
	}
	return l
}

// WithFields adds structured fields to the logger
func (l *Logger) WithFields(fields map[string]interface{}) *Logger {
	args := make([]interface{}, 0, len(fields)*2)
	for k, v := range fields {
		args = append(args, k, v)
	}
	return &Logger{Logger: l.Logger.With(args...)}
}

// LogRequest logs HTTP request details
func (l *Logger) LogRequest(r *http.Request, statusCode int, duration time.Duration) {
	l.WithContext(r.Context()).Info("HTTP request",
		"method", r.Method,
		"path", r.URL.Path,
		"query", r.URL.RawQuery,
		"status_code", statusCode,
		"duration_ms", duration.Milliseconds(),
		"user_agent", r.UserAgent(),
		"remote_addr", r.RemoteAddr,
	)
}

// LogError logs an error with context
func (l *Logger) LogError(ctx context.Context, err error, msg string, fields ...interface{}) {
	args := []interface{}{"error", err.Error()}
	args = append(args, fields...)
	l.WithContext(ctx).Error(msg, args...)
}

// LogAPICall logs API method calls with parameters
func (l *Logger) LogAPICall(ctx context.Context, method string, params map[string]interface{}) {
	fields := map[string]interface{}{
		"api_method": method,
		"params":     params,
	}
	l.WithContext(ctx).WithFields(fields).Info("API call started")
}

// LogAPIResult logs API method results
func (l *Logger) LogAPIResult(ctx context.Context, method string, result interface{}, err error, duration time.Duration) {
	fields := map[string]interface{}{
		"api_method":  method,
		"duration_ms": duration.Milliseconds(),
	}

	if err != nil {
		fields["error"] = err.Error()
		l.WithContext(ctx).WithFields(fields).Error("API call failed")
	} else {
		if result != nil {
			// Only log result if it's not too large
			if resultBytes, marshalErr := json.Marshal(result); marshalErr == nil && len(resultBytes) < 1000 {
				fields["result"] = result
			} else {
				fields["result_size"] = len(resultBytes)
			}
		}
		l.WithContext(ctx).WithFields(fields).Info("API call completed")
	}
}

// LogWebSocketEvent logs WebSocket events
func (l *Logger) LogWebSocketEvent(ctx context.Context, event string, fields map[string]interface{}) {
	if fields == nil {
		fields = make(map[string]interface{})
	}
	fields["ws_event"] = event
	l.WithContext(ctx).WithFields(fields).Info("WebSocket event")
}

// LogRepositoryOperation logs database/repository operations
func (l *Logger) LogRepositoryOperation(ctx context.Context, operation string, entity string, id interface{}, err error, duration time.Duration) {
	fields := map[string]interface{}{
		"repo_operation": operation,
		"entity":         entity,
		"duration_ms":    duration.Milliseconds(),
	}

	if id != nil {
		fields["entity_id"] = id
	}

	if err != nil {
		fields["error"] = err.Error()
		l.WithContext(ctx).WithFields(fields).Error("Repository operation failed")
	} else {
		l.WithContext(ctx).WithFields(fields).Debug("Repository operation completed")
	}
}

// Global logger instance
var defaultLogger *Logger

func init() {
	defaultLogger = NewDefault()
}

// SetDefault sets the default logger instance
func SetDefault(logger *Logger) {
	defaultLogger = logger
}

// Default returns the default logger instance
func Default() *Logger {
	return defaultLogger
}

// Convenience functions using the default logger
func Info(msg string, args ...interface{}) {
	defaultLogger.Info(msg, args...)
}

func Debug(msg string, args ...interface{}) {
	defaultLogger.Debug(msg, args...)
}

func Warn(msg string, args ...interface{}) {
	defaultLogger.Warn(msg, args...)
}

func Error(msg string, args ...interface{}) {
	defaultLogger.Error(msg, args...)
}

func WithFields(fields map[string]interface{}) *Logger {
	return defaultLogger.WithFields(fields)
}

func WithContext(ctx context.Context) *Logger {
	return defaultLogger.WithContext(ctx)
}
