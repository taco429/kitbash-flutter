# 🎉 Debugging Setup Complete!

Your Kitbash Go server now has comprehensive debugging and logging capabilities. Here's what has been implemented and how to use it.

## ✅ What Was Added

### 1. **Structured Logging System**
- JSON-formatted logs with request tracing
- Configurable log levels (DEBUG, INFO, WARN, ERROR)
- Context-aware logging with request IDs
- Performance timing for all operations

### 2. **Enhanced Error Handling**
- Comprehensive error logging in all API endpoints
- Repository-level operation tracking
- WebSocket connection monitoring
- HTTP request/response logging

### 3. **Missing Game Creation Endpoint**
- Added `POST /api/games` endpoint (was missing!)
- Flutter client now has `createGame()` method
- Better error reporting in the Flutter UI

### 4. **Debug Tools**
- Interactive debug script (`backend/scripts/debug-server.sh`)
- Docker Compose debug configuration
- Health check endpoints
- Network debugging utilities

### 5. **Log Collection Setup**
- Docker logging configuration
- Optional Grafana + Loki setup for log visualization
- Log rotation to prevent disk issues

## 🚀 Quick Start Guide

### Step 1: Update Server URL
In `lib/services/game_service.dart`, change line 9:
```dart
// Change this to your Proxmox container IP
static const String baseUrl = 'http://YOUR_PROXMOX_IP:8080';
```

### Step 2: Deploy with Debug Logging
```bash
# In your Proxmox container, enable debug logging:
docker run -d \
  --name kitbash-backend \
  -p 8080:8080 \
  -e LOG_LEVEL=DEBUG \
  -e LOG_FORMAT=json \
  your-registry/kitbash-backend:latest
```

### Step 3: Test the Setup
```bash
# Run the debug script
./backend/scripts/debug-server.sh

# Or test specific endpoints
curl http://YOUR_PROXMOX_IP:8080/healthz
curl http://YOUR_PROXMOX_IP:8080/api/games
```

## 🔍 Debugging Your Issues

### For Game Creation Errors:

1. **Check server logs:**
   ```bash
   docker logs kitbash-backend | grep '"api_method":"Create"'
   ```

2. **Test the endpoint directly:**
   ```bash
   curl -X POST http://YOUR_PROXMOX_IP:8080/api/games \
     -H "Content-Type: application/json" \
     -d '{"name":"Test Game","hostName":"TestHost"}'
   ```

3. **Use the debug script:**
   ```bash
   ./backend/scripts/debug-server.sh test
   ```

### For Connection Issues:

1. **Check network connectivity:**
   ```bash
   ./backend/scripts/debug-server.sh network
   ```

2. **Monitor logs in real-time:**
   ```bash
   ./backend/scripts/debug-server.sh monitor
   ```

3. **Verify server health:**
   ```bash
   ./backend/scripts/debug-server.sh health
   ```

## 📊 Log Analysis

### Key Log Patterns to Look For:

**Successful Game Creation:**
```json
{"level":"INFO","msg":"API call started","api_method":"Create","name":"Quick Match"}
{"level":"INFO","msg":"API call completed","api_method":"Create","duration_ms":45}
{"level":"INFO","msg":"Successfully created game (compatibility)","game_id":"abc123"}
```

**Error Patterns:**
```json
{"level":"ERROR","msg":"Failed to create game","error":"...","name":"..."}
{"level":"ERROR","msg":"API call failed","api_method":"Create","error":"..."}
```

**HTTP Request Tracking:**
```json
{"level":"INFO","msg":"HTTP request","method":"POST","path":"/api/games","status_code":201,"duration_ms":50}
```

## 🛠️ Available Debug Commands

```bash
./backend/scripts/debug-server.sh health    # Check server health
./backend/scripts/debug-server.sh test      # Test all API endpoints  
./backend/scripts/debug-server.sh logs      # Show recent logs
./backend/scripts/debug-server.sh monitor   # Real-time log monitoring
./backend/scripts/debug-server.sh network   # Network debugging
./backend/scripts/debug-server.sh load      # Generate test load
./backend/scripts/debug-server.sh report    # Full debug report
```

## 🏥 Enhanced Flutter Client

The Flutter client now provides:
- Detailed debug logging for all API calls
- Better error messages with specific failure reasons
- Create Game button that actually works
- Timeout handling for network requests
- Visual error feedback in the UI

## 📋 Environment Variables

Configure your server with these environment variables:

```bash
# Logging
LOG_LEVEL=DEBUG          # DEBUG, INFO, WARN, ERROR
LOG_FORMAT=json          # json or text
LOG_OUTPUT=stdout        # stdout, stderr, or file path

# Server
HTTP_PORT=8080          # Server port
CORS_ORIGINS=*          # CORS configuration
```

## 🎯 Next Steps

1. **Update the Flutter client** with your Proxmox IP address
2. **Deploy the updated server** with debug logging enabled
3. **Test game creation** using the Flutter app or debug script
4. **Check the logs** to see exactly what's happening
5. **Use the debug script** for ongoing troubleshooting

## 📚 Documentation

- **Full Debug Guide:** `backend/DEBUG_GUIDE.md`
- **Interactive Debug Script:** `backend/scripts/debug-server.sh`
- **Docker Debug Setup:** `docker-compose.debug.yml`

## 🆘 Still Having Issues?

1. Run: `./backend/scripts/debug-server.sh report`
2. Check the structured logs for error patterns
3. Verify network connectivity between Flutter client and Proxmox server
4. Ensure Docker port 8080 is properly exposed and accessible

The new logging system will show you exactly what's happening at every step, making it much easier to identify and fix any remaining issues!

---

**Happy Debugging! 🐛➡️✨**
