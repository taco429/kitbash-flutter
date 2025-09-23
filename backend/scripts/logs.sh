#!/bin/bash

# Log viewer script for Kitbash backend
# This script provides an easy way to view and format backend logs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
LOGFMT_DIR="$SCRIPT_DIR/logfmt"
LOGFMT_BIN="$LOGFMT_DIR/logfmt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build the log formatter if it doesn't exist or source is newer
build_logfmt() {
    if [ ! -f "$LOGFMT_BIN" ] || [ "$LOGFMT_DIR/main.go" -nt "$LOGFMT_BIN" ]; then
        echo -e "${YELLOW}Building log formatter...${NC}"
        (cd "$LOGFMT_DIR" && go build -o logfmt main.go)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Log formatter built successfully${NC}"
        else
            echo -e "${RED}Failed to build log formatter${NC}"
            exit 1
        fi
    fi
}

# Show help message
show_help() {
    echo "Kitbash Log Viewer"
    echo "=================="
    echo ""
    echo "Usage: $0 [options] [logfile]"
    echo ""
    echo "If no logfile is specified, reads from stdin (useful for piping)"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -c                 Compact mode - single line output"
    echo "  -f                 Follow mode - continuously read new lines"
    echo "  -l LEVEL          Filter by log level (INFO, WARN, ERROR, DEBUG)"
    echo "  -g PATTERN        Grep filter - only show logs containing pattern"
    echo "  --game ID         Filter by game ID"
    echo "  --event TYPE      Filter by WebSocket event type"
    echo "  -s                Show source information (file, function, line)"
    echo "  --no-color        Disable color output"
    echo "  --raw             Show raw JSON logs (bypass formatter)"
    echo ""
    echo "Examples:"
    echo "  # View logs from file"
    echo "  $0 server.log"
    echo ""
    echo "  # View logs in compact mode"
    echo "  $0 -c server.log"
    echo ""
    echo "  # Follow logs in real-time"
    echo "  $0 -f server.log"
    echo ""
    echo "  # Filter by log level"
    echo "  $0 -l ERROR server.log"
    echo ""
    echo "  # Pipe server output directly"
    echo "  go run $BACKEND_DIR/cmd/server 2>&1 | $0"
    echo ""
    echo "  # Filter by game ID"
    echo "  $0 --game 890b258c-c85e-4e29-86e5-3fb4d5c1efe2 server.log"
    echo ""
    echo "  # Show only WebSocket events"
    echo "  $0 --event game_message_received server.log"
}

# Parse command line arguments
LOGFMT_ARGS=()
RAW_MODE=false
SHOW_HELP=false
LOGFILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        --raw)
            RAW_MODE=true
            shift
            ;;
        -c|-f|-s|--no-color)
            LOGFMT_ARGS+=("$1")
            shift
            ;;
        -l|-g)
            LOGFMT_ARGS+=("$1")
            LOGFMT_ARGS+=("$2")
            shift 2
            ;;
        --game)
            LOGFMT_ARGS+=("-game")
            LOGFMT_ARGS+=("$2")
            shift 2
            ;;
        --event)
            LOGFMT_ARGS+=("-event")
            LOGFMT_ARGS+=("$2")
            shift 2
            ;;
        *)
            if [ -z "$LOGFILE" ]; then
                LOGFILE="$1"
            fi
            shift
            ;;
    esac
done

# Show help if requested
if [ "$SHOW_HELP" = true ]; then
    show_help
    exit 0
fi

# If raw mode, just use cat/tail
if [ "$RAW_MODE" = true ]; then
    if [ -n "$LOGFILE" ]; then
        if [[ " ${LOGFMT_ARGS[@]} " =~ " -f " ]]; then
            tail -f "$LOGFILE"
        else
            cat "$LOGFILE"
        fi
    else
        cat
    fi
    exit 0
fi

# Build the log formatter
build_logfmt

# Run the log formatter
if [ -n "$LOGFILE" ]; then
    "$LOGFMT_BIN" "${LOGFMT_ARGS[@]}" "$LOGFILE"
else
    "$LOGFMT_BIN" "${LOGFMT_ARGS[@]}"
fi
