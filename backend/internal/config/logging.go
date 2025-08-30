package config

import (
	"os"
	"strings"

	"kitbash/backend/internal/logger"
)

// LoggingConfig holds logging-specific configuration
type LoggingConfig struct {
	Level  logger.LogLevel
	Format string // "json" or "text"
	Output string // "stdout", "stderr", or file path
}

// LoadLoggingConfig reads logging configuration from environment variables
func LoadLoggingConfig() LoggingConfig {
	level := strings.ToUpper(getenvDefault("LOG_LEVEL", "INFO"))
	format := strings.ToLower(getenvDefault("LOG_FORMAT", "json"))
	output := getenvDefault("LOG_OUTPUT", "stdout")

	var logLevel logger.LogLevel
	switch level {
	case "DEBUG":
		logLevel = logger.LevelDebug
	case "INFO":
		logLevel = logger.LevelInfo
	case "WARN", "WARNING":
		logLevel = logger.LevelWarn
	case "ERROR":
		logLevel = logger.LevelError
	default:
		logLevel = logger.LevelInfo
	}

	return LoggingConfig{
		Level:  logLevel,
		Format: format,
		Output: output,
	}
}

// CreateLogger creates a logger instance based on the configuration
func (lc LoggingConfig) CreateLogger() *logger.Logger {
	var output *os.File
	switch lc.Output {
	case "stdout":
		output = os.Stdout
	case "stderr":
		output = os.Stderr
	default:
		// Try to open file, fall back to stdout on error
		if file, err := os.OpenFile(lc.Output, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666); err == nil {
			output = file
		} else {
			output = os.Stdout
		}
	}

	return logger.New(lc.Level, output)
}
