# Kitbash Backend Debugging Guide

This guide provides comprehensive debugging tools and techniques for the Kitbash Go backend server, especially when deployed in a Proxmox container.

## Quick Start

### 1. Use the Debug Script

The easiest way to debug your server is using the provided debug script:

```bash
# Make script executable (if not already)
chmod +x backend/scripts/debug-server.sh

# Run interactive debug menu
./backend/scripts/debug-server.sh

# Or run specific commands
./backend/scripts/debug-server.sh health    # Check server health
./backend/scripts/debug-server.sh test      # Test API endpoints
./backend/scripts/debug-server.sh logs      # Show recent logs
./backend/scripts/debug-server.sh monitor   # Real-time log monitoring
./backend/scripts/debug-server.sh report    # Full debug report
```

### 2. Check Server Health

First, verify your server is responding:

```bash
curl http://your-proxmox-ip:8080/healthz
```

Should return `ok` with HTTP 200 status.

## Logging Configuration

### Environment Variables

Configure logging behavior with these environment variables:

```bash
# Log levels: DEBUG, INFO, WARN, ERROR
LOG_LEVEL=DEBUG

# Output format: json (recommended) or text
LOG_FORMAT=json

# Output destination: stdout, stderr, or file path
LOG_OUTPUT=stdout

# CORS for development
CORS_ORIGINS=*
```

### Docker Logging

When running in Docker/Proxmox, logs are captured by Docker's logging driver:

```bash
# View logs
docker logs kitbash-backend

# Follow logs in real-time
docker logs -f kitbash-backend

# Show last 100 lines
docker logs --tail 100 kitbash-backend

# Show logs since timestamp
docker logs --since 2024-01-01T00:00:00 kitbash-backend
```

## Common Issues and Solutions

### 1. Game Creation Fails

**Symptoms:**
- Flutter client shows "Failed to create game"
- HTTP 400/500 responses to POST /api/games

**Debug Steps:**
1. Check server logs for errors:
   ```bash
   ./backend/scripts/debug-server.sh logs
   ```

2. Test the endpoint directly:
   ```bash
   curl -X POST http://your-server:8080/api/games \
     -H "Content-Type: application/json" \
     -d '{"name":"Test Game","hostName":"TestHost"}'
   ```

3. Look for these log entries:
   - `"api_method":"Create"` - API call started
   - `"repo_operation":"create"` - Database operation
   - `"error"` field if something failed

### 2. Connection Issues

**Symptoms:**
- "Connection refused" errors
- Timeouts from Flutter client

**Debug Steps:**
1. Verify server is listening:
   ```bash
   ./backend/scripts/debug-server.sh network
   ```

2. Check if port 8080 is accessible from your network:
   ```bash
   # From another machine
   telnet your-proxmox-ip 8080
   ```

3. Check Proxmox firewall rules
4. Verify Docker port mapping

### 3. WebSocket Issues

**Symptoms:**
- WebSocket connection fails
- Real-time features not working

**Debug Steps:**
1. Test WebSocket endpoint:
   ```bash
   # Using websocat (install: cargo install websocat)
   websocat ws://your-server:8080/ws
   ```

2. Check logs for WebSocket events:
   ```bash
   docker logs kitbash-backend | grep ws_event
   ```

## Log Analysis

### Structured Logging

All logs are in JSON format with these common fields:

```json
{
  "time": "2024-01-15T10:30:00Z",
  "level": "INFO",
  "msg": "HTTP request",
  "request_id": "abc123",
  "method": "POST",
  "path": "/api/games",
  "status_code": 201,
  "duration_ms": 45
}
```

### Key Log Patterns

**HTTP Requests:**
```bash
# Filter HTTP requests
docker logs kitbash-backend | grep '"msg":"HTTP request"'

# Filter errors (4xx/5xx)
docker logs kitbash-backend | grep '"status_code":[45]'
```

**API Operations:**
```bash
# Filter API calls
docker logs kitbash-backend | grep '"api_method"'

# Filter repository operations
docker logs kitbash-backend | grep '"repo_operation"'
```

**Errors:**
```bash
# All errors
docker logs kitbash-backend | grep '"level":"ERROR"'

# Specific error types
docker logs kitbash-backend | grep '"error"'
```

## Development Debugging

### Enhanced Logging Mode

For development, use the debug Docker Compose:

```bash
# Start with debug configuration
docker-compose -f docker-compose.yml -f docker-compose.debug.yml up

# This enables:
# - DEBUG level logging
# - Enhanced log collection
# - Optional Grafana dashboard at http://localhost:3000
```

### Local Development

Run server locally with debug logging:

```bash
cd backend
LOG_LEVEL=DEBUG LOG_FORMAT=json go run ./cmd/server
```

## Production Debugging

### Container Inspection

```bash
# Get container details
docker inspect kitbash-backend

# Check resource usage
docker stats kitbash-backend

# Execute commands in container
docker exec -it kitbash-backend /bin/sh
```

### Log Rotation

Configure log rotation to prevent disk space issues:

```bash
# In docker-compose.yml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

### Monitoring

Set up monitoring with the provided Grafana configuration:

1. Start debug compose: `docker-compose -f docker-compose.yml -f docker-compose.debug.yml up`
2. Access Grafana at http://your-server:3000 (admin/admin)
3. Import dashboard for Kitbash logs

## Request Tracing

Every HTTP request gets a unique request ID for tracing:

```bash
# Find all log entries for a specific request
docker logs kitbash-backend | grep '"request_id":"abc123"'
```

This helps trace a request through:
1. HTTP middleware (request start/end)
2. API handler (parameter validation, business logic)
3. Repository layer (database operations)
4. Response generation

## Performance Debugging

### Load Testing

Use the debug script to generate test load:

```bash
./backend/scripts/debug-server.sh load 50 5
# 50 requests with 5 concurrent connections
```

### Timing Analysis

Look for slow operations in logs:

```bash
# Find slow HTTP requests (>1000ms)
docker logs kitbash-backend | jq 'select(.duration_ms > 1000)'

# Find slow repository operations
docker logs kitbash-backend | jq 'select(.repo_operation and .duration_ms > 100)'
```

## Troubleshooting Checklist

1. **Server Health**
   - [ ] `/healthz` endpoint responds
   - [ ] Server logs show startup messages
   - [ ] No error logs during startup

2. **Network Connectivity**
   - [ ] Port 8080 accessible from client
   - [ ] Firewall rules allow traffic
   - [ ] CORS configured for client domain

3. **API Functionality**
   - [ ] GET /api/games returns lobby list
   - [ ] POST /api/games creates new game
   - [ ] POST /api/games/{id}/join works

4. **Logging**
   - [ ] Structured JSON logs present
   - [ ] Request IDs in all related log entries
   - [ ] Error details captured in logs

5. **Container Health**
   - [ ] Container running and healthy
   - [ ] Adequate memory/CPU resources
   - [ ] Log rotation configured

## Getting Help

If you're still experiencing issues:

1. Run the full debug report: `./backend/scripts/debug-server.sh report`
2. Check the logs for error patterns
3. Verify your Proxmox network configuration
4. Test with the Flutter client in debug mode

The structured logging system provides detailed information about every operation, making it much easier to identify and resolve issues.
