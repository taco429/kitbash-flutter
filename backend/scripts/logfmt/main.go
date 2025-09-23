package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// LogEntry represents the structure of your JSON logs
type LogEntry struct {
	Time   string                 `json:"time"`
	Level  string                 `json:"level"`
	Source Source                 `json:"source"`
	Msg    string                 `json:"msg"`
	Fields map[string]interface{} `json:"-"` // Capture all other fields
}

type Source struct {
	Function string `json:"function"`
	File     string `json:"file"`
	Line     int    `json:"line"`
}

// UnmarshalJSON custom unmarshaler to capture extra fields
func (l *LogEntry) UnmarshalJSON(data []byte) error {
	type Alias LogEntry
	aux := &struct {
		*Alias
	}{
		Alias: (*Alias)(l),
	}

	if err := json.Unmarshal(data, aux); err != nil {
		return err
	}

	// Capture all fields into a map
	var allFields map[string]interface{}
	if err := json.Unmarshal(data, &allFields); err != nil {
		return err
	}

	// Remove known fields
	delete(allFields, "time")
	delete(allFields, "level")
	delete(allFields, "source")
	delete(allFields, "msg")

	l.Fields = allFields
	return nil
}

// Color codes for terminal output
const (
	Reset   = "\033[0m"
	Red     = "\033[31m"
	Green   = "\033[32m"
	Yellow  = "\033[33m"
	Blue    = "\033[34m"
	Magenta = "\033[35m"
	Cyan    = "\033[36m"
	Gray    = "\033[90m"
	White   = "\033[97m"
	Bold    = "\033[1m"
	Dim     = "\033[2m"
)

var (
	compact       bool
	follow        bool
	levelFilter   string
	noColor       bool
	showSource    bool
	grepFilter    string
	gameIDFilter  string
	wsEventFilter string
)

func init() {
	flag.BoolVar(&compact, "c", false, "Compact mode - single line output")
	flag.BoolVar(&follow, "f", false, "Follow mode - continuously read new lines (like tail -f)")
	flag.StringVar(&levelFilter, "l", "", "Filter by log level (INFO, WARN, ERROR, DEBUG)")
	flag.BoolVar(&noColor, "no-color", false, "Disable color output")
	flag.BoolVar(&showSource, "s", false, "Show source information (file, function, line)")
	flag.StringVar(&grepFilter, "g", "", "Grep filter - only show logs containing this string")
	flag.StringVar(&gameIDFilter, "game", "", "Filter by game ID")
	flag.StringVar(&wsEventFilter, "event", "", "Filter by WebSocket event type")
}

func main() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [options] [logfile]\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\nLog Formatter - Makes JSON logs human-readable\n\n")
		fmt.Fprintf(os.Stderr, "Examples:\n")
		fmt.Fprintf(os.Stderr, "  %s server.log              # Format logs from file\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -c server.log           # Compact mode\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -f server.log           # Follow mode (tail -f)\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  %s -l ERROR                # Show only ERROR logs\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "  go run server 2>&1 | %s    # Pipe logs directly\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\nOptions:\n")
		flag.PrintDefaults()
	}

	flag.Parse()

	var input io.Reader = os.Stdin

	// If a file is provided, open it
	if flag.NArg() > 0 {
		file, err := os.Open(flag.Arg(0))
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error opening file: %v\n", err)
			os.Exit(1)
		}
		defer file.Close()

		if follow {
			// For follow mode, we need to handle file reading differently
			followFile(flag.Arg(0))
			return
		}
		input = file
	}

	scanner := bufio.NewScanner(input)
	for scanner.Scan() {
		line := scanner.Text()
		processLine(line)
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input: %v\n", err)
	}
}

func followFile(filename string) {
	file, err := os.Open(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Move to end of file
	file.Seek(0, io.SeekEnd)

	scanner := bufio.NewScanner(file)
	for {
		for scanner.Scan() {
			processLine(scanner.Text())
		}
		time.Sleep(100 * time.Millisecond)
		file.Seek(0, io.SeekCurrent) // Reset EOF
	}
}

func processLine(line string) {
	// Skip empty lines
	if strings.TrimSpace(line) == "" {
		return
	}

	// Try to parse as JSON log entry
	var entry LogEntry
	if err := json.Unmarshal([]byte(line), &entry); err != nil {
		// If not JSON, print as-is
		fmt.Println(line)
		return
	}

	// Apply filters
	if levelFilter != "" && entry.Level != levelFilter {
		return
	}

	if grepFilter != "" && !strings.Contains(line, grepFilter) {
		return
	}

	if gameIDFilter != "" {
		if gameID, ok := entry.Fields["game_id"].(string); ok {
			if gameID != gameIDFilter {
				return
			}
		} else {
			return // No game_id field, skip
		}
	}

	if wsEventFilter != "" {
		if wsEvent, ok := entry.Fields["ws_event"].(string); ok {
			if wsEvent != wsEventFilter {
				return
			}
		} else {
			return // No ws_event field, skip
		}
	}

	// Format and print the entry
	if compact {
		printCompact(entry)
	} else {
		printDetailed(entry)
	}
}

func printCompact(entry LogEntry) {
	timestamp := formatTime(entry.Time)
	level := formatLevel(entry.Level)

	// Build fields string
	var fields []string
	for k, v := range entry.Fields {
		fields = append(fields, fmt.Sprintf("%s=%v", k, formatValue(v)))
	}

	fieldsStr := ""
	if len(fields) > 0 {
		fieldsStr = " | " + strings.Join(fields, " ")
	}

	fmt.Printf("%s %s %s%s\n", timestamp, level, entry.Msg, fieldsStr)
}

func printDetailed(entry LogEntry) {
	timestamp := formatTime(entry.Time)
	level := formatLevel(entry.Level)

	// Main log line
	fmt.Printf("%s %s %s%s%s\n", timestamp, level, color(Bold), entry.Msg, color(Reset))

	// Source information (if enabled)
	if showSource && entry.Source.Function != "" {
		funcName := filepath.Base(entry.Source.Function)
		fileName := filepath.Base(entry.Source.File)
		fmt.Printf("  %s↳ %s:%d in %s%s\n",
			color(Gray), fileName, entry.Source.Line, funcName, color(Reset))
	}

	// Additional fields
	if len(entry.Fields) > 0 {
		for k, v := range entry.Fields {
			fmt.Printf("  %s%s:%s %s\n",
				color(Cyan), k, color(Reset), formatDetailedValue(k, v))
		}
	}

	fmt.Println() // Empty line for separation
}

func formatTime(timeStr string) string {
	t, err := time.Parse(time.RFC3339Nano, timeStr)
	if err != nil {
		return timeStr[:19] // Fallback to first 19 chars
	}
	return color(Gray) + t.Format("15:04:05.000") + color(Reset)
}

func formatLevel(level string) string {
	switch level {
	case "ERROR":
		return color(Red) + "[ERROR]" + color(Reset)
	case "WARN":
		return color(Yellow) + "[WARN] " + color(Reset)
	case "INFO":
		return color(Green) + "[INFO] " + color(Reset)
	case "DEBUG":
		return color(Blue) + "[DEBUG]" + color(Reset)
	default:
		return "[" + level + "]"
	}
}

func formatValue(v interface{}) string {
	switch val := v.(type) {
	case string:
		// Truncate long strings in compact mode
		if len(val) > 50 {
			return val[:47] + "..."
		}
		return val
	case []interface{}:
		// Format arrays nicely
		items := make([]string, len(val))
		for i, item := range val {
			items[i] = fmt.Sprintf("%v", item)
		}
		return "[" + strings.Join(items, ", ") + "]"
	default:
		return fmt.Sprintf("%v", v)
	}
}

func formatDetailedValue(key string, v interface{}) string {
	switch val := v.(type) {
	case string:
		// Special formatting for certain fields
		if key == "game_id" || key == "request_id" {
			return color(Yellow) + val + color(Reset)
		}
		if key == "message" && strings.Contains(val, "\"type\"") {
			// Try to pretty-print JSON messages
			var msgData map[string]interface{}
			if err := json.Unmarshal([]byte(val), &msgData); err == nil {
				formatted, _ := json.Marshal(msgData)
				return color(Magenta) + string(formatted) + color(Reset)
			}
		}
		return val
	case []interface{}:
		// Format arrays nicely
		if len(val) == 0 {
			return "[]"
		}
		items := make([]string, len(val))
		for i, item := range val {
			items[i] = fmt.Sprintf("%v", item)
		}
		return color(Yellow) + "[" + strings.Join(items, ", ") + "]" + color(Reset)
	case float64:
		// Format numbers
		if float64(int(val)) == val {
			return color(Blue) + fmt.Sprintf("%d", int(val)) + color(Reset)
		}
		return color(Blue) + fmt.Sprintf("%.2f", val) + color(Reset)
	case bool:
		if val {
			return color(Green) + "true" + color(Reset)
		}
		return color(Red) + "false" + color(Reset)
	case nil:
		return color(Gray) + "null" + color(Reset)
	default:
		return fmt.Sprintf("%v", v)
	}
}

func color(code string) string {
	if noColor {
		return ""
	}
	return code
}
