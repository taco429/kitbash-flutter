package config

import (
    "log"
    "os"
    "strconv"
)

// Config holds runtime configuration parsed from environment variables.
type Config struct {
    HTTPPort    string
    CORSOrigins []string
    BoardRows   int
    BoardCols   int
}

// Load reads configuration from environment variables with sensible defaults.
func Load() Config {
    port := getenvDefault("HTTP_PORT", "8080")
    cors := getenvDefault("CORS_ORIGINS", "*")
    rowsStr := getenvDefault("BOARD_ROWS", "12")
    colsStr := getenvDefault("BOARD_COLS", "12")

    rows, err := strconv.Atoi(rowsStr)
    if err != nil {
        rows = 12
    }
    cols, err := strconv.Atoi(colsStr)
    if err != nil {
        cols = 12
    }

    cfg := Config{
        HTTPPort:    port,
        CORSOrigins: []string{cors},
        BoardRows:   rows,
        BoardCols:   cols,
    }
    log.Printf("config: port=%s cors=%v board_rows=%d board_cols=%d", cfg.HTTPPort, cfg.CORSOrigins, cfg.BoardRows, cfg.BoardCols)
    return cfg
}

// getenvDefault returns the env value or the provided default when empty.
func getenvDefault(key, def string) string {
    v := os.Getenv(key)
    if v == "" {
        return def
    }
    return v
}

