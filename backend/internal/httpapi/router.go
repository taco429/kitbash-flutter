package httpapi

import (
    "encoding/json"
    "io"
    "log"
    "net/http"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"

    "kitbash/backend/internal/config"
    "kitbash/backend/internal/domain"
    "kitbash/backend/internal/repository"
    "kitbash/backend/internal/ws"
)

type api struct {
    repo *repository.InMemoryLobbyRepository
    cfg  config.Config
}

// NewRouter constructs the HTTP router, wires routes/middleware, and returns it.
// Used by main() to start the HTTP server.
func NewRouter(cfg config.Config) http.Handler {
    r := chi.NewRouter()
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)
    r.Use(corsMiddleware())

    a := &api{repo: repository.NewInMemoryLobbyRepository(), cfg: cfg}
    // seed one lobby for initial testing
    a.repo.Create("Quick Match", domain.Player{ID: "host", Name: "Host"})
    hub := ws.NewHub()

    // GET /healthz: liveness probe for container/orchestrator.
    r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    })

    r.Route("/api", func(r chi.Router) {
        // GET /api/lobbies: list active lobbies.
        r.Get("/lobbies", a.handleListLobbies)
        // POST /api/lobbies: create a new lobby with a host.
        r.Post("/lobbies", a.handleCreateLobby)
        r.Route("/lobbies/{id}", func(r chi.Router) {
            // GET /api/lobbies/{id}/: fetch lobby details.
            r.Get("/", a.handleGetLobby)
            // POST /api/lobbies/{id}/join: add a player to the lobby.
            r.Post("/join", a.handleJoinLobby)
            // POST /api/lobbies/{id}/leave: remove a player from the lobby.
            r.Post("/leave", a.handleLeaveLobby)
            // DELETE /api/lobbies/{id}/: delete a lobby.
            r.Delete("/", a.handleDeleteLobby)
        })

        // Compatibility routes expected by current Flutter client
        // GET /api/games: alias for lobbies list.
        r.Get("/games", a.handleListLobbies)
        // POST /api/games/{id}/join: join without request body.
        r.Post("/games/{id}/join", a.handleJoinGameCompat)
    })

    // WebSocket endpoints for real-time events (currently echo)
    r.Get("/ws", hub.HandleWS)
    r.Get("/ws/game/{id}", hub.HandleWS)

    return r
}

// writeJSON writes JSON responses with status code; used by handlers.
func (a *api) writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    if err := json.NewEncoder(w).Encode(v); err != nil {
        log.Printf("json encode error: %v", err)
    }
}

// handleListLobbies returns all active lobbies.
func (a *api) handleListLobbies(w http.ResponseWriter, r *http.Request) {
    lobbies, _ := a.repo.List()
    a.writeJSON(w, http.StatusOK, lobbies)
}

type createLobbyRequest struct {
    Name     string `json:"name"`
    HostName string `json:"hostName"`
}

// handleCreateLobby creates a new lobby from request body.
// Body: { name, hostName }
func (a *api) handleCreateLobby(w http.ResponseWriter, r *http.Request) {
    var req createLobbyRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Name == "" || req.HostName == "" {
        http.Error(w, "invalid request", http.StatusBadRequest)
        return
    }
    host := domain.Player{ID: domain.PlayerID(req.HostName), Name: req.HostName}
    lobby, err := a.repo.Create(req.Name, host)
    if err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
    a.writeJSON(w, http.StatusCreated, lobby)
}

// handleGetLobby fetches a lobby by ID in the URL.
func (a *api) handleGetLobby(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    lobby, err := a.repo.Get(domain.LobbyID(id))
    if err != nil {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }
    a.writeJSON(w, http.StatusOK, lobby)
}

type joinLobbyRequest struct {
    PlayerID   string `json:"playerId"`
    PlayerName string `json:"playerName"`
}

// handleJoinLobby joins the specified lobby.
// Accepts empty body (ephemeral player) or { playerId, playerName }.
func (a *api) handleJoinLobby(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    var req joinLobbyRequest
    // Accept empty body: create ephemeral player
    body, _ := io.ReadAll(r.Body)
    if len(body) > 0 {
        if err := json.Unmarshal(body, &req); err != nil || req.PlayerID == "" || req.PlayerName == "" {
            http.Error(w, "invalid request", http.StatusBadRequest)
            return
        }
    } else {
        req.PlayerID = "player"
        req.PlayerName = "Player"
    }
    player := domain.Player{ID: domain.PlayerID(req.PlayerID), Name: req.PlayerName}
    lobby, err := a.repo.Join(domain.LobbyID(id), player)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    a.writeJSON(w, http.StatusOK, lobby)
}

type leaveLobbyRequest struct {
    PlayerID string `json:"playerId"`
}

// handleLeaveLobby removes a player from the lobby.
// Body: { playerId }
func (a *api) handleLeaveLobby(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    var req leaveLobbyRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.PlayerID == "" {
        http.Error(w, "invalid request", http.StatusBadRequest)
        return
    }
    lobby, err := a.repo.Leave(domain.LobbyID(id), domain.PlayerID(req.PlayerID))
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    if lobby.ID == "" {
        w.WriteHeader(http.StatusNoContent)
        return
    }
    a.writeJSON(w, http.StatusOK, lobby)
}

// handleDeleteLobby deletes the lobby by ID.
func (a *api) handleDeleteLobby(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    if err := a.repo.Delete(domain.LobbyID(id)); err != nil {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }
    w.WriteHeader(http.StatusNoContent)
}

// handleJoinGameCompat joins a lobby using the legacy /api/games route.
// Used by the current Flutter client; no body required.
func (a *api) handleJoinGameCompat(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    // Reuse join without requiring body
    player := domain.Player{ID: "player", Name: "Player"}
    lobby, err := a.repo.Join(domain.LobbyID(id), player)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    a.writeJSON(w, http.StatusOK, lobby)
}

// corsMiddleware allows cross-origin requests for local dev.
func corsMiddleware() func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            w.Header().Set("Access-Control-Allow-Origin", "*")
            w.Header().Set("Access-Control-Allow-Methods", "GET,POST,DELETE,OPTIONS")
            w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
            if r.Method == http.MethodOptions {
                w.WriteHeader(http.StatusNoContent)
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}

