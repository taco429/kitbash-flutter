package httpapi

import (
	"context"
	"encoding/json"
	"io"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"kitbash/backend/internal/config"
	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"
	custommiddleware "kitbash/backend/internal/middleware"
	"kitbash/backend/internal/repository"
	"kitbash/backend/internal/ws"
)

type api struct {
	repo     *repository.InMemoryLobbyRepository
	gameRepo repository.GameRepository
	cardRepo domain.CardRepository
	deckRepo domain.DeckRepository
	cfg      config.Config
	log      *logger.Logger
}

// NewRouter constructs the HTTP router, wires routes/middleware, and returns it.
// Used by main() to start the HTTP server.
func NewRouter(cfg config.Config) http.Handler {
	// Initialize logger
	log := logger.NewDefault()

	r := chi.NewRouter()

	// Add request ID middleware first
	r.Use(middleware.RequestID)

	// Add custom logging middleware
	r.Use(custommiddleware.LoggingMiddleware(log))
	r.Use(custommiddleware.RecoveryMiddleware(log))
	r.Use(corsMiddleware())

	a := &api{
		repo:     repository.NewInMemoryLobbyRepository(log),
		gameRepo: repository.NewInMemoryGameRepository(log),
		cardRepo: repository.NewInMemoryCardRepository(log),
		deckRepo: repository.NewInMemoryDeckRepository(log),
		cfg:      cfg,
		log:      log,
	}

	// seed one lobby for initial testing
	ctx := context.Background()
	seedLobby, err := a.repo.Create(ctx, "Quick Match", domain.Player{ID: "host", Name: "Host"})
	if err != nil {
		log.Error("Failed to create seed lobby", "error", err)
	} else {
		log.Info("Created seed lobby", "lobby_id", seedLobby.ID, "lobby_name", seedLobby.Name)
	}

	hub := ws.NewHub(log, cfg)
	gameHub := ws.NewGameHubWithRepos(a.gameRepo, a.deckRepo, log, cfg)

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
		// POST /api/games: create a new game (alias for lobby creation).
		r.Post("/games", a.handleCreateGameCompat)
		// POST /api/games/cpu: create a new game with a CPU opponent and return it.
		r.Post("/games/cpu", a.handleCreateCpuGameCompat)
		// POST /api/games/{id}/join: join without request body.
		r.Post("/games/{id}/join", a.handleJoinGameCompat)
		
		// Game action endpoints
		r.Route("/games/{id}", func(r chi.Router) {
			// POST /api/games/{id}/damage: deal damage to a command center
			r.Post("/damage", a.handleDealDamage)
			// GET /api/games/{id}/state: get current game state
			r.Get("/state", a.handleGetGameState)
		})

		// Card endpoints
		r.Route("/cards", func(r chi.Router) {
			// GET /api/cards: get all cards
			r.Get("/", a.GetAllCards)
			// GET /api/cards/{cardId}: get specific card
			r.Get("/{cardId}", a.GetCard)
			// GET /api/cards/color/{color}: get cards by color
			r.Get("/color/{color}", a.GetCardsByColor)
			// GET /api/cards/type/{type}: get cards by type
			r.Get("/type/{type}", a.GetCardsByType)
		})

		// Deck endpoints
		r.Route("/decks", func(r chi.Router) {
			// GET /api/decks: get all decks
			r.Get("/", a.GetAllDecks)
			// GET /api/decks/prebuilt: get prebuilt decks
			r.Get("/prebuilt", a.GetPrebuiltDecks)
			// GET /api/decks/{deckId}: get specific deck with card details
			r.Get("/{deckId}", a.GetDeck)
			// GET /api/decks/color/{color}: get decks by color
			r.Get("/color/{color}", a.GetDecksByColor)
		})
	})

	// WebSocket endpoints for real-time events
	r.Get("/ws", hub.HandleWS)
	r.Get("/ws/game/{id}", func(w http.ResponseWriter, r *http.Request) {
		gameID := chi.URLParam(r, "id")
		gameHub.HandleGameWS(w, r, gameID)
	})

	return r
}

// writeJSON writes JSON responses with status code; used by handlers.
func (a *api) writeJSON(w http.ResponseWriter, r *http.Request, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		a.log.LogError(r.Context(), err, "Failed to encode JSON response", "status_code", status)
	}
}

// handleListLobbies returns all active lobbies.
func (a *api) handleListLobbies(w http.ResponseWriter, r *http.Request) {
	a.log.WithContext(r.Context()).Info("Listing lobbies")

	lobbies, err := a.repo.List(r.Context())
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to list lobbies")
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	a.log.WithContext(r.Context()).Info("Successfully listed lobbies", "count", len(lobbies))
	a.writeJSON(w, r, http.StatusOK, lobbies)
}

type createLobbyRequest struct {
	Name     string `json:"name"`
	HostName string `json:"hostName"`
}

// handleCreateLobby creates a new lobby from request body.
// Body: { name, hostName }
func (a *api) handleCreateLobby(w http.ResponseWriter, r *http.Request) {
	a.log.WithContext(r.Context()).Info("Creating new lobby")

	var req createLobbyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.log.LogError(r.Context(), err, "Failed to decode create lobby request")
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.Name == "" || req.HostName == "" {
		a.log.WithContext(r.Context()).Warn("Invalid create lobby request", "name", req.Name, "host_name", req.HostName)
		http.Error(w, "name and hostName are required", http.StatusBadRequest)
		return
	}

	host := domain.Player{ID: domain.PlayerID(req.HostName), Name: req.HostName}
	lobby, err := a.repo.Create(r.Context(), req.Name, host)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to create lobby", "name", req.Name, "host", req.HostName)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	a.log.WithContext(r.Context()).Info("Successfully created lobby", "lobby_id", lobby.ID, "name", lobby.Name)
	a.writeJSON(w, r, http.StatusCreated, lobby)
}

// handleGetLobby fetches a lobby by ID in the URL.
func (a *api) handleGetLobby(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Getting lobby", "lobby_id", id)

	lobby, err := a.repo.Get(r.Context(), domain.LobbyID(id))
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to get lobby", "lobby_id", id)
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}

	a.log.WithContext(r.Context()).Info("Successfully retrieved lobby", "lobby_id", lobby.ID)
	a.writeJSON(w, r, http.StatusOK, lobby)
}

type joinLobbyRequest struct {
	PlayerID   string `json:"playerId"`
	PlayerName string `json:"playerName"`
}

// handleJoinLobby joins the specified lobby.
// Accepts empty body (ephemeral player) or { playerId, playerName }.
func (a *api) handleJoinLobby(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Player joining lobby", "lobby_id", id)

	var req joinLobbyRequest
	// Accept empty body: create ephemeral player
	body, err := io.ReadAll(r.Body)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to read request body")
		http.Error(w, "failed to read request", http.StatusBadRequest)
		return
	}

	if len(body) > 0 {
		if err := json.Unmarshal(body, &req); err != nil {
			a.log.LogError(r.Context(), err, "Failed to parse join lobby request")
			http.Error(w, "invalid request body", http.StatusBadRequest)
			return
		}
		if req.PlayerID == "" || req.PlayerName == "" {
			a.log.WithContext(r.Context()).Warn("Invalid join request - missing fields", "player_id", req.PlayerID, "player_name", req.PlayerName)
			http.Error(w, "playerId and playerName are required", http.StatusBadRequest)
			return
		}
	} else {
		req.PlayerID = "player"
		req.PlayerName = "Player"
		a.log.WithContext(r.Context()).Debug("Using default player for join", "lobby_id", id)
	}

	player := domain.Player{ID: domain.PlayerID(req.PlayerID), Name: req.PlayerName}
	lobby, err := a.repo.Join(r.Context(), domain.LobbyID(id), player)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to join lobby", "lobby_id", id, "player_id", req.PlayerID)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	a.log.WithContext(r.Context()).Info("Player successfully joined lobby", "lobby_id", lobby.ID, "player_id", player.ID, "players_count", len(lobby.Players))
	a.writeJSON(w, r, http.StatusOK, lobby)
}

type leaveLobbyRequest struct {
	PlayerID string `json:"playerId"`
}

// handleLeaveLobby removes a player from the lobby.
// Body: { playerId }
func (a *api) handleLeaveLobby(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Player leaving lobby", "lobby_id", id)

	var req leaveLobbyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.log.LogError(r.Context(), err, "Failed to decode leave lobby request")
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.PlayerID == "" {
		a.log.WithContext(r.Context()).Warn("Leave lobby request missing player ID", "lobby_id", id)
		http.Error(w, "playerId is required", http.StatusBadRequest)
		return
	}

	lobby, err := a.repo.Leave(r.Context(), domain.LobbyID(id), domain.PlayerID(req.PlayerID))
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to leave lobby", "lobby_id", id, "player_id", req.PlayerID)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if lobby.ID == "" {
		a.log.WithContext(r.Context()).Info("Lobby was deleted after player left", "lobby_id", id, "player_id", req.PlayerID)
		w.WriteHeader(http.StatusNoContent)
		return
	}

	a.log.WithContext(r.Context()).Info("Player successfully left lobby", "lobby_id", lobby.ID, "player_id", req.PlayerID, "remaining_players", len(lobby.Players))
	a.writeJSON(w, r, http.StatusOK, lobby)
}

// handleDeleteLobby deletes the lobby by ID.
func (a *api) handleDeleteLobby(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Deleting lobby", "lobby_id", id)

	if err := a.repo.Delete(r.Context(), domain.LobbyID(id)); err != nil {
		a.log.LogError(r.Context(), err, "Failed to delete lobby", "lobby_id", id)
		http.Error(w, "lobby not found", http.StatusNotFound)
		return
	}

	a.log.WithContext(r.Context()).Info("Successfully deleted lobby", "lobby_id", id)
	w.WriteHeader(http.StatusNoContent)
}

// handleJoinGameCompat joins a lobby using the legacy /api/games route.
// Used by the current Flutter client; no body required.
func (a *api) handleJoinGameCompat(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Player joining game (compatibility endpoint)", "game_id", id)

	// Reuse join without requiring body
	player := domain.Player{ID: "player", Name: "Player"}
	lobby, err := a.repo.Join(r.Context(), domain.LobbyID(id), player)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to join game (compatibility)", "game_id", id)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	a.log.WithContext(r.Context()).Info("Player successfully joined game (compatibility)", "game_id", lobby.ID, "players_count", len(lobby.Players))
	a.writeJSON(w, r, http.StatusOK, lobby)
}

// handleCreateGameCompat creates a new game using the legacy /api/games route.
// Used by the current Flutter client; accepts empty body (creates default game).
func (a *api) handleCreateGameCompat(w http.ResponseWriter, r *http.Request) {
	a.log.WithContext(r.Context()).Info("Creating new game (compatibility endpoint)")

	// Create a default game lobby
	gameName := "Quick Match"
	hostName := "Host"

	// Try to read body if provided
	body, err := io.ReadAll(r.Body)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to read create game request body")
		http.Error(w, "failed to read request", http.StatusBadRequest)
		return
	}

	if len(body) > 0 {
		var req createLobbyRequest
		if err := json.Unmarshal(body, &req); err != nil {
			a.log.LogError(r.Context(), err, "Failed to parse create game request")
			// Don't fail, just use defaults
			a.log.WithContext(r.Context()).Debug("Using default game settings due to parse error")
		} else {
			if req.Name != "" {
				gameName = req.Name
			}
			if req.HostName != "" {
				hostName = req.HostName
			}
		}
	}

	host := domain.Player{ID: domain.PlayerID(hostName), Name: hostName}
	lobby, err := a.repo.Create(r.Context(), gameName, host)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to create game", "name", gameName, "host", hostName)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	a.log.WithContext(r.Context()).Info("Successfully created game (compatibility)", "game_id", lobby.ID, "name", lobby.Name)
	a.writeJSON(w, r, http.StatusCreated, lobby)
}

// handleCreateCpuGameCompat creates a new 1v1 game and auto-adds a CPU opponent.
// Route: POST /api/games/cpu
func (a *api) handleCreateCpuGameCompat(w http.ResponseWriter, r *http.Request) {
	a.log.WithContext(r.Context()).Info("Creating new CPU game (compatibility endpoint)")

	// Create lobby with human player as host
	gameName := "CPU Match"
	hostName := "Player"

	host := domain.Player{ID: domain.PlayerID(hostName), Name: hostName}
	lobby, err := a.repo.Create(r.Context(), gameName, host)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to create CPU game", "name", gameName, "host", hostName)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Auto-join a CPU opponent
	cpu := domain.Player{ID: "cpu", Name: "CPU"}
	lobby, err = a.repo.Join(r.Context(), lobby.ID, cpu)
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to add CPU to game", "lobby_id", lobby.ID)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	a.log.WithContext(r.Context()).Info("Successfully created CPU game", "game_id", lobby.ID, "players_count", len(lobby.Players))
	a.writeJSON(w, r, http.StatusCreated, lobby)
}

// handleDealDamage deals damage to a command center.
func (a *api) handleDealDamage(w http.ResponseWriter, r *http.Request) {
	gameID := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Dealing damage to command center", "game_id", gameID)

	var req struct {
		PlayerIndex int `json:"playerIndex"`
		Damage      int `json:"damage"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.log.LogError(r.Context(), err, "Failed to decode damage request")
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	if req.Damage <= 0 {
		req.Damage = 10 // Default damage
	}

	gameState, err := a.gameRepo.Get(r.Context(), domain.GameID(gameID))
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to get game state", "game_id", gameID)
		http.Error(w, "game not found", http.StatusNotFound)
		return
	}

	destroyed := gameState.DealDamageToCommandCenter(req.PlayerIndex, req.Damage)

	if err := a.gameRepo.Update(r.Context(), gameState); err != nil {
		a.log.LogError(r.Context(), err, "Failed to update game state")
		http.Error(w, "failed to update game state", http.StatusInternalServerError)
		return
	}

	a.log.WithContext(r.Context()).Info("Damage dealt successfully",
		"game_id", gameID,
		"player_index", req.PlayerIndex,
		"damage", req.Damage,
		"destroyed", destroyed)

	response := map[string]interface{}{
		"success":   true,
		"destroyed": destroyed,
		"gameState": gameState,
	}

	a.writeJSON(w, r, http.StatusOK, response)
}

// handleGetGameState returns the current game state.
func (a *api) handleGetGameState(w http.ResponseWriter, r *http.Request) {
	gameID := chi.URLParam(r, "id")
	a.log.WithContext(r.Context()).Info("Getting game state", "game_id", gameID)

	gameState, err := a.gameRepo.Get(r.Context(), domain.GameID(gameID))
	if err != nil {
		a.log.LogError(r.Context(), err, "Failed to get game state", "game_id", gameID)
		http.Error(w, "game not found", http.StatusNotFound)
		return
	}

	a.writeJSON(w, r, http.StatusOK, gameState)
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
