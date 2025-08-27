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

func NewRouter(cfg config.Config) http.Handler {
    r := chi.NewRouter()
    r.Use(middleware.Logger)
    r.Use(middleware.Recoverer)
    r.Use(corsMiddleware())

    a := &api{repo: repository.NewInMemoryLobbyRepository(), cfg: cfg}
    // seed one lobby for initial testing
    a.repo.Create("Quick Match", domain.Player{ID: "host", Name: "Host"})
    hub := ws.NewHub()

    r.Get("/healthz", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("ok"))
    })

    r.Route("/api", func(r chi.Router) {
        r.Get("/lobbies", a.handleListLobbies)
        r.Post("/lobbies", a.handleCreateLobby)
        r.Route("/lobbies/{id}", func(r chi.Router) {
            r.Get("/", a.handleGetLobby)
            r.Post("/join", a.handleJoinLobby)
            r.Post("/leave", a.handleLeaveLobby)
            r.Delete("/", a.handleDeleteLobby)
        })

        // Compatibility routes expected by current Flutter client
        r.Get("/games", a.handleListLobbies)
        r.Post("/games/{id}/join", a.handleJoinGameCompat)
    })

    // WebSocket endpoints for real-time events (currently echo)
    r.Get("/ws", hub.HandleWS)
    r.Get("/ws/game/{id}", hub.HandleWS)

    return r
}

func (a *api) writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    if err := json.NewEncoder(w).Encode(v); err != nil {
        log.Printf("json encode error: %v", err)
    }
}

func (a *api) handleListLobbies(w http.ResponseWriter, r *http.Request) {
    lobbies, _ := a.repo.List()
    a.writeJSON(w, http.StatusOK, lobbies)
}

type createLobbyRequest struct {
    Name     string `json:"name"`
    HostName string `json:"hostName"`
}

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

func (a *api) handleDeleteLobby(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    if err := a.repo.Delete(domain.LobbyID(id)); err != nil {
        http.Error(w, "not found", http.StatusNotFound)
        return
    }
    w.WriteHeader(http.StatusNoContent)
}

// handleJoinGameCompat matches the Flutter client's expected route
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

// corsMiddleware is a minimal CORS handler for dev
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

