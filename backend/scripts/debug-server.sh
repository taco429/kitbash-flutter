#!/bin/bash

# Debug script for Kitbash Go server
# This script helps with debugging server issues in development and production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="${CONTAINER_NAME:-kitbash-backend}"
LOG_LINES="${LOG_LINES:-100}"
SERVER_URL="${SERVER_URL:-http://localhost:8080}"

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if server is running
check_server_health() {
    print_header "Server Health Check"
    
    if curl -s -f "$SERVER_URL/healthz" > /dev/null; then
        print_success "Server is responding at $SERVER_URL"
        
        # Get server info
        echo -e "\n${BLUE}Server Response:${NC}"
        curl -s "$SERVER_URL/healthz" && echo
    else
        print_error "Server is not responding at $SERVER_URL"
        return 1
    fi
}

# Test API endpoints
test_api_endpoints() {
    print_header "API Endpoint Tests"
    
    # Test listing games/lobbies
    echo -e "${BLUE}Testing GET /api/games:${NC}"
    if response=$(curl -s -w "\nHTTP Status: %{http_code}\n" "$SERVER_URL/api/games"); then
        echo "$response"
        print_success "Games endpoint working"
    else
        print_error "Games endpoint failed"
    fi
    
    echo -e "\n${BLUE}Testing POST /api/games (create game):${NC}"
    if response=$(curl -s -w "\nHTTP Status: %{http_code}\n" -X POST \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Game","hostName":"TestHost"}' \
        "$SERVER_URL/api/games"); then
        echo "$response"
        print_success "Create game endpoint working"
        
        # Extract game ID for join test
        game_id=$(echo "$response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$game_id" ]; then
            echo -e "\n${BLUE}Testing POST /api/games/$game_id/join:${NC}"
            if join_response=$(curl -s -w "\nHTTP Status: %{http_code}\n" -X POST \
                -H "Content-Type: application/json" \
                "$SERVER_URL/api/games/$game_id/join"); then
                echo "$join_response"
                print_success "Join game endpoint working"
            else
                print_error "Join game endpoint failed"
            fi
        fi
    else
        print_error "Create game endpoint failed"
    fi
}

# Show recent logs
show_logs() {
    print_header "Recent Server Logs"
    
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_success "Found Docker container: $CONTAINER_NAME"
            echo -e "\n${BLUE}Last $LOG_LINES lines of logs:${NC}"
            docker logs --tail "$LOG_LINES" "$CONTAINER_NAME"
        else
            print_warning "Docker container '$CONTAINER_NAME' not found"
            echo "Available containers:"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        fi
    else
        print_warning "Docker not available, cannot show container logs"
    fi
}

# Monitor logs in real-time
monitor_logs() {
    print_header "Real-time Log Monitoring"
    
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_success "Monitoring logs for container: $CONTAINER_NAME"
            echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}\n"
            docker logs -f "$CONTAINER_NAME"
        else
            print_error "Docker container '$CONTAINER_NAME' not found"
            return 1
        fi
    else
        print_error "Docker not available"
        return 1
    fi
}

# Show container stats
show_container_stats() {
    print_header "Container Statistics"
    
    if command -v docker &> /dev/null; then
        if docker ps --format "table {{.Names}}" | grep -q "$CONTAINER_NAME"; then
            print_success "Container stats for: $CONTAINER_NAME"
            docker stats "$CONTAINER_NAME" --no-stream
        else
            print_error "Docker container '$CONTAINER_NAME' not found"
            return 1
        fi
    else
        print_error "Docker not available"
        return 1
    fi
}

# Network debugging
debug_network() {
    print_header "Network Debugging"
    
    echo -e "${BLUE}Testing connectivity to server:${NC}"
    if nc -z localhost 8080 2>/dev/null; then
        print_success "Port 8080 is open"
    else
        print_error "Port 8080 is not accessible"
    fi
    
    echo -e "\n${BLUE}Network interfaces:${NC}"
    ip addr show 2>/dev/null || ifconfig 2>/dev/null || print_warning "Cannot show network interfaces"
    
    echo -e "\n${BLUE}Listening ports:${NC}"
    ss -tlnp 2>/dev/null | grep :8080 || netstat -tlnp 2>/dev/null | grep :8080 || print_warning "Port 8080 not found in listening ports"
}

# Generate test load
generate_load() {
    print_header "Load Testing"
    
    local requests=${1:-10}
    local concurrent=${2:-2}
    
    print_warning "Generating $requests requests with $concurrent concurrent connections"
    
    for i in $(seq 1 $requests); do
        (
            if response=$(curl -s -w "Time: %{time_total}s, Status: %{http_code}" "$SERVER_URL/api/games"); then
                echo "Request $i: $response"
            else
                echo "Request $i: FAILED"
            fi
        ) &
        
        # Limit concurrent requests
        if (( i % concurrent == 0 )); then
            wait
        fi
    done
    wait
    
    print_success "Load test completed"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}Kitbash Server Debug Tool${NC}"
    echo "========================"
    echo "1. Health Check"
    echo "2. Test API Endpoints"
    echo "3. Show Recent Logs"
    echo "4. Monitor Logs (real-time)"
    echo "5. Container Statistics"
    echo "6. Network Debugging"
    echo "7. Generate Test Load"
    echo "8. Full Debug Report"
    echo "9. Exit"
    echo
}

# Full debug report
full_debug_report() {
    print_header "Full Debug Report"
    
    check_server_health
    test_api_endpoints
    show_container_stats
    debug_network
    show_logs
    
    print_success "Debug report completed"
}

# Handle command line arguments
case "${1:-}" in
    "health")
        check_server_health
        ;;
    "test")
        test_api_endpoints
        ;;
    "logs")
        show_logs
        ;;
    "monitor")
        monitor_logs
        ;;
    "stats")
        show_container_stats
        ;;
    "network")
        debug_network
        ;;
    "load")
        generate_load "${2:-10}" "${3:-2}"
        ;;
    "report")
        full_debug_report
        ;;
    "")
        # Interactive mode
        while true; do
            show_menu
            read -p "Select an option (1-9): " choice
            
            case $choice in
                1) check_server_health ;;
                2) test_api_endpoints ;;
                3) show_logs ;;
                4) monitor_logs ;;
                5) show_container_stats ;;
                6) debug_network ;;
                7) 
                    read -p "Number of requests (default 10): " requests
                    read -p "Concurrent connections (default 2): " concurrent
                    generate_load "${requests:-10}" "${concurrent:-2}"
                    ;;
                8) full_debug_report ;;
                9) 
                    print_success "Goodbye!"
                    exit 0
                    ;;
                *)
                    print_error "Invalid option. Please select 1-9."
                    ;;
            esac
            
            echo -e "\n${YELLOW}Press Enter to continue...${NC}"
            read
        done
        ;;
    *)
        echo "Usage: $0 [health|test|logs|monitor|stats|network|load|report]"
        echo "  health  - Check server health"
        echo "  test    - Test API endpoints"
        echo "  logs    - Show recent logs"
        echo "  monitor - Monitor logs in real-time"
        echo "  stats   - Show container statistics"
        echo "  network - Debug network connectivity"
        echo "  load    - Generate test load"
        echo "  report  - Full debug report"
        echo "  (no args) - Interactive mode"
        exit 1
        ;;
esac
