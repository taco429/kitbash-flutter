package repository

import (
	"context"
	"errors"
	"sync"
	"time"

	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"

	"github.com/google/uuid"
)

var (
	// ErrLobbyNotFound indicates the requested lobby doesn't exist.
	ErrLobbyNotFound = errors.New("lobby not found")
)

// LobbyRepository defines operations to manage lobbies.
type LobbyRepository interface {
	Create(ctx context.Context, name string, host domain.Player) (domain.Lobby, error)
	Get(ctx context.Context, id domain.LobbyID) (domain.Lobby, error)
	List(ctx context.Context) ([]domain.Lobby, error)
	Join(ctx context.Context, id domain.LobbyID, player domain.Player) (domain.Lobby, error)
	Leave(ctx context.Context, id domain.LobbyID, playerID domain.PlayerID) (domain.Lobby, error)
	Delete(ctx context.Context, id domain.LobbyID) error
}

// InMemoryLobbyRepository is a concurrency-safe in-memory implementation.
type InMemoryLobbyRepository struct {
	mu      sync.RWMutex
	storage map[domain.LobbyID]domain.Lobby
	log     *logger.Logger
}

// NewInMemoryLobbyRepository returns an empty in-memory lobby store.
func NewInMemoryLobbyRepository(log *logger.Logger) *InMemoryLobbyRepository {
	if log == nil {
		log = logger.Default()
	}
	return &InMemoryLobbyRepository{
		storage: make(map[domain.LobbyID]domain.Lobby),
		log:     log,
	}
}

// Create creates a new lobby with the given host.
func (r *InMemoryLobbyRepository) Create(ctx context.Context, name string, host domain.Player) (domain.Lobby, error) {
	start := time.Now()
	r.log.LogAPICall(ctx, "Create", map[string]interface{}{
		"name":      name,
		"host_id":   host.ID,
		"host_name": host.Name,
	})

	r.mu.Lock()
	defer r.mu.Unlock()

	id := domain.LobbyID(uuid.NewString())
	lobby := domain.Lobby{
		ID:         id,
		Name:       name,
		HostID:     host.ID,
		Players:    []domain.Player{host},
		MaxPlayers: 2,
		CreatedAt:  time.Now().UTC(),
	}
	r.storage[id] = lobby

	r.log.LogRepositoryOperation(ctx, "create", "lobby", id, nil, time.Since(start))
	r.log.LogAPIResult(ctx, "Create", lobby, nil, time.Since(start))
	return lobby, nil
}

// Get retrieves a lobby by ID.
func (r *InMemoryLobbyRepository) Get(ctx context.Context, id domain.LobbyID) (domain.Lobby, error) {
	start := time.Now()
	r.log.LogAPICall(ctx, "Get", map[string]interface{}{"id": id})

	r.mu.RLock()
	defer r.mu.RUnlock()

	lobby, ok := r.storage[id]
	if !ok {
		r.log.LogRepositoryOperation(ctx, "get", "lobby", id, ErrLobbyNotFound, time.Since(start))
		r.log.LogAPIResult(ctx, "Get", nil, ErrLobbyNotFound, time.Since(start))
		return domain.Lobby{}, ErrLobbyNotFound
	}

	r.log.LogRepositoryOperation(ctx, "get", "lobby", id, nil, time.Since(start))
	r.log.LogAPIResult(ctx, "Get", lobby, nil, time.Since(start))
	return lobby, nil
}

// List returns all lobbies.
func (r *InMemoryLobbyRepository) List(ctx context.Context) ([]domain.Lobby, error) {
	start := time.Now()
	r.log.LogAPICall(ctx, "List", nil)

	r.mu.RLock()
	defer r.mu.RUnlock()

	result := make([]domain.Lobby, 0, len(r.storage))
	for _, l := range r.storage {
		result = append(result, l)
	}

	r.log.LogRepositoryOperation(ctx, "list", "lobby", nil, nil, time.Since(start))
	r.log.LogAPIResult(ctx, "List", map[string]interface{}{"count": len(result)}, nil, time.Since(start))
	return result, nil
}

// Join adds a player to a lobby, if capacity allows.
func (r *InMemoryLobbyRepository) Join(ctx context.Context, id domain.LobbyID, player domain.Player) (domain.Lobby, error) {
	start := time.Now()
	r.log.LogAPICall(ctx, "Join", map[string]interface{}{
		"lobby_id":    id,
		"player_id":   player.ID,
		"player_name": player.Name,
	})

	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.storage[id]
	if !ok {
		r.log.LogRepositoryOperation(ctx, "join", "lobby", id, ErrLobbyNotFound, time.Since(start))
		r.log.LogAPIResult(ctx, "Join", nil, ErrLobbyNotFound, time.Since(start))
		return domain.Lobby{}, ErrLobbyNotFound
	}

	if len(lobby.Players) >= lobby.MaxPlayers {
		err := errors.New("lobby full")
		r.log.LogRepositoryOperation(ctx, "join", "lobby", id, err, time.Since(start))
		r.log.LogAPIResult(ctx, "Join", lobby, err, time.Since(start))
		return lobby, err
	}

	// check duplicate
	for _, p := range lobby.Players {
		if p.ID == player.ID {
			r.log.WithContext(ctx).Debug("Player already in lobby", "player_id", player.ID, "lobby_id", id)
			r.log.LogRepositoryOperation(ctx, "join", "lobby", id, nil, time.Since(start))
			r.log.LogAPIResult(ctx, "Join", lobby, nil, time.Since(start))
			return lobby, nil
		}
	}

	lobby.Players = append(lobby.Players, player)
	r.storage[id] = lobby

	r.log.LogRepositoryOperation(ctx, "join", "lobby", id, nil, time.Since(start))
	r.log.LogAPIResult(ctx, "Join", lobby, nil, time.Since(start))
	return lobby, nil
}

// Leave removes a player from a lobby; deletes lobby if it becomes empty.
func (r *InMemoryLobbyRepository) Leave(ctx context.Context, id domain.LobbyID, playerID domain.PlayerID) (domain.Lobby, error) {
	start := time.Now()
	r.log.LogAPICall(ctx, "Leave", map[string]interface{}{
		"lobby_id":  id,
		"player_id": playerID,
	})

	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.storage[id]
	if !ok {
		r.log.LogRepositoryOperation(ctx, "leave", "lobby", id, ErrLobbyNotFound, time.Since(start))
		r.log.LogAPIResult(ctx, "Leave", nil, ErrLobbyNotFound, time.Since(start))
		return domain.Lobby{}, ErrLobbyNotFound
	}

	originalPlayerCount := len(lobby.Players)
	filtered := lobby.Players[:0]
	for _, p := range lobby.Players {
		if p.ID != playerID {
			filtered = append(filtered, p)
		}
	}
	lobby.Players = filtered

	// auto delete empty lobby
	if len(lobby.Players) == 0 {
		delete(r.storage, id)
		r.log.WithContext(ctx).Info("Empty lobby deleted", "lobby_id", id)
		r.log.LogRepositoryOperation(ctx, "leave_and_delete", "lobby", id, nil, time.Since(start))
		r.log.LogAPIResult(ctx, "Leave", map[string]interface{}{"deleted": true}, nil, time.Since(start))
		return domain.Lobby{}, nil
	}

	r.storage[id] = lobby
	r.log.WithContext(ctx).Debug("Player left lobby",
		"lobby_id", id,
		"player_id", playerID,
		"players_before", originalPlayerCount,
		"players_after", len(lobby.Players))

	r.log.LogRepositoryOperation(ctx, "leave", "lobby", id, nil, time.Since(start))
	r.log.LogAPIResult(ctx, "Leave", lobby, nil, time.Since(start))
	return lobby, nil
}

// Delete removes a lobby by ID.
func (r *InMemoryLobbyRepository) Delete(ctx context.Context, id domain.LobbyID) error {
	start := time.Now()
	r.log.LogAPICall(ctx, "Delete", map[string]interface{}{"id": id})

	r.mu.Lock()
	defer r.mu.Unlock()

	if _, ok := r.storage[id]; !ok {
		r.log.LogRepositoryOperation(ctx, "delete", "lobby", id, ErrLobbyNotFound, time.Since(start))
		r.log.LogAPIResult(ctx, "Delete", nil, ErrLobbyNotFound, time.Since(start))
		return ErrLobbyNotFound
	}

	delete(r.storage, id)
	r.log.LogRepositoryOperation(ctx, "delete", "lobby", id, nil, time.Since(start))
	r.log.LogAPIResult(ctx, "Delete", nil, nil, time.Since(start))
	return nil
}
