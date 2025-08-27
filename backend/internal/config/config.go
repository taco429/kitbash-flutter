package config

import (
    "log"
    "os"
)

// Config holds runtime configuration parsed from environment variables.
type Config struct {
    HTTPPort string
    CORSOrigins []string
}

// Load reads configuration from environment variables with sensible defaults.
func Load() Config {
    port := getenvDefault("HTTP_PORT", "8080")
    cors := getenvDefault("CORS_ORIGINS", "*")
    cfg := Config{
        HTTPPort: port,
        CORSOrigins: []string{cors},
    }
    log.Printf("config: port=%s cors=%v", cfg.HTTPPort, cfg.CORSOrigins)
    return cfg
}

func getenvDefault(key, def string) string {
    v := os.Getenv(key)
    if v == "" {
        return def
    }
    return v
}

