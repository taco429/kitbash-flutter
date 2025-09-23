# Kitbash Log Viewer

A powerful tool for viewing and formatting JSON logs from the Kitbash backend, making them human-readable and easy to analyze.

## Features

- **Color-coded output**: Different colors for log levels, fields, and values
- **Multiple viewing modes**: 
  - Detailed mode (default) - Shows all fields in a structured format
  - Compact mode - Single line per log entry for quick scanning
- **Powerful filtering**:
  - By log level (INFO, WARN, ERROR, DEBUG)
  - By game ID
  - By WebSocket event type
  - By any text pattern (grep)
- **Real-time following**: Like `tail -f` but with formatting
- **Source information**: Optionally show file, function, and line numbers

## Quick Start

### Using the Makefile (Recommended)

```bash
# View formatted logs from a file
make logs FILE=server.log

# View logs in compact mode
make logs-compact FILE=server.log

# Follow logs in real-time (like tail -f)
make logs-follow FILE=server.log

# View only ERROR level logs
make logs-errors FILE=server.log

# Filter by game ID
make logs-game FILE=server.log GAME=890b258c-c85e-4e29-86e5-3fb4d5c1efe2

# Pipe logs directly from the server
go run backend/cmd/server 2>&1 | make logs-pipe
```

### Using the Script Directly

```bash
# Basic usage
./backend/scripts/logs.sh server.log

# Compact mode
./backend/scripts/logs.sh -c server.log

# Follow mode
./backend/scripts/logs.sh -f server.log

# Filter by log level
./backend/scripts/logs.sh -l ERROR server.log

# Show source information
./backend/scripts/logs.sh -s server.log

# Combine options
./backend/scripts/logs.sh -c -l INFO --game 890b258c server.log
```

## Output Examples

### Detailed Mode (Default)

```
23:10:22.805 [INFO] Phase advanced
  game_id: 890b258c-c85e-4e29-86e5-3fb4d5c1efe2
  new_phase: reveal_resolve
  turn: 1
```

### Compact Mode

```
23:10:22.805 [INFO] Phase advanced | game_id=890b258c turn=1 new_phase=reveal_resolve
```

## All Available Options

| Option | Description |
|--------|-------------|
| `-c` | Compact mode - single line output |
| `-f` | Follow mode - continuously read new lines |
| `-l LEVEL` | Filter by log level (INFO, WARN, ERROR, DEBUG) |
| `-g PATTERN` | Grep filter - only show logs containing pattern |
| `--game ID` | Filter by game ID |
| `--event TYPE` | Filter by WebSocket event type |
| `-s` | Show source information (file, function, line) |
| `--no-color` | Disable color output |

## Real-Time Development Workflow

### Option 1: Run server with piped logs
```bash
go run backend/cmd/server 2>&1 | ./backend/scripts/logs.sh
```

### Option 2: Save logs and follow
```bash
# In terminal 1: Run server and save logs
go run backend/cmd/server 2>&1 | tee server.log

# In terminal 2: Follow and format logs
make logs-follow FILE=server.log
```

### Option 3: Filter specific events during debugging
```bash
# Only show WebSocket messages
go run backend/cmd/server 2>&1 | ./backend/scripts/logs.sh --event game_message_received

# Only show errors
go run backend/cmd/server 2>&1 | ./backend/scripts/logs.sh -l ERROR
```

## Tips

1. **Use compact mode for quick scanning**: When you need to see many log entries at once
2. **Use filters to reduce noise**: Focus on specific game IDs or event types
3. **Combine with standard Unix tools**: The formatter preserves colors when piping to `less -R`
4. **Real-time debugging**: Use follow mode to watch logs as they're generated

## Technical Details

The log viewer consists of:
- `/backend/scripts/logfmt/main.go` - Go program that parses and formats JSON logs
- `/backend/scripts/logs.sh` - Shell wrapper that builds and runs the formatter
- Makefile targets - Convenient shortcuts for common operations

The formatter automatically builds when needed and caches the binary for performance.
