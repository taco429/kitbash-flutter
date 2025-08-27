# Backend (Go) Development

## Requirements
- Go 1.22+
- Optional: Docker Desktop (or Docker Engine on Linux/Proxmox)

## Run Locally
```bash
cd backend
go run ./cmd/server
```

- Health: `http://localhost:8080/healthz`
- REST Endpoints:
  - List lobbies: `GET /api/lobbies`
  - Create lobby: `POST /api/lobbies` body: `{ "name": "Test", "hostName": "Alice" }`
  - Get lobby: `GET /api/lobbies/{id}`
  - Join lobby: `POST /api/lobbies/{id}/join`
  - Leave lobby: `POST /api/lobbies/{id}/leave` body: `{ "playerId": "Alice" }`
  - Delete lobby: `DELETE /api/lobbies/{id}`
- Compatibility routes for current client:
  - `GET /api/games` (alias of lobbies)
  - `POST /api/games/{id}/join` (no body required)
- WebSocket:
  - `GET /ws` (echo)
  - `GET /ws/game/{id}` (echo)

## Docker (Dev)
From repo root:
```bash
docker compose build
docker compose up
```
Services:
- Backend: `http://localhost:8080`
- Frontend (web build via nginx): `http://localhost:8081`

On Windows use WSL2 with Docker Desktop and run the above inside WSL.

## Proxmox Test Deploy
On a VM with Docker installed:
```bash
git clone <repo>
cd <repo>
docker compose -p kitbash up -d --build
```

Set env vars as needed, e.g. `HTTP_PORT=8080` for backend.