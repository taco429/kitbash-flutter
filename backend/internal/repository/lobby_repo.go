package repository

import (
    "errors"
    "sync"
    "time"

    "github.com/google/uuid"
    "kitbash/backend/internal/domain"
)

var (
    ErrLobbyNotFound = errors.New("lobby not found")
)

// LobbyRepository defines operations to manage lobbies.
type LobbyRepository interface {
    Create(name string, host domain.Player) (domain.Lobby, error)
    Get(id domain.LobbyID) (domain.Lobby, error)
    List() ([]domain.Lobby, error)
    Join(id domain.LobbyID, player domain.Player) (domain.Lobby, error)
    Leave(id domain.LobbyID, playerID domain.PlayerID) (domain.Lobby, error)
    Delete(id domain.LobbyID) error
}

// InMemoryLobbyRepository is a concurrency-safe in-memory implementation.
type InMemoryLobbyRepository struct {
    mu      sync.RWMutex
    storage map[domain.LobbyID]domain.Lobby
}

func NewInMemoryLobbyRepository() *InMemoryLobbyRepository {
    return &InMemoryLobbyRepository{storage: make(map[domain.LobbyID]domain.Lobby)}
}

func (r *InMemoryLobbyRepository) Create(name string, host domain.Player) (domain.Lobby, error) {
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
    return lobby, nil
}

func (r *InMemoryLobbyRepository) Get(id domain.LobbyID) (domain.Lobby, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    lobby, ok := r.storage[id]
    if !ok {
        return domain.Lobby{}, ErrLobbyNotFound
    }
    return lobby, nil
}

func (r *InMemoryLobbyRepository) List() ([]domain.Lobby, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    result := make([]domain.Lobby, 0, len(r.storage))
    for _, l := range r.storage {
        result = append(result, l)
    }
    return result, nil
}

func (r *InMemoryLobbyRepository) Join(id domain.LobbyID, player domain.Player) (domain.Lobby, error) {
    r.mu.Lock()
    defer r.mu.Unlock()
    lobby, ok := r.storage[id]
    if !ok {
        return domain.Lobby{}, ErrLobbyNotFound
    }
    if len(lobby.Players) >= lobby.MaxPlayers {
        return lobby, errors.New("lobby full")
    }
    // check duplicate
    for _, p := range lobby.Players {
        if p.ID == player.ID {
            return lobby, nil
        }
    }
    lobby.Players = append(lobby.Players, player)
    r.storage[id] = lobby
    return lobby, nil
}

func (r *InMemoryLobbyRepository) Leave(id domain.LobbyID, playerID domain.PlayerID) (domain.Lobby, error) {
    r.mu.Lock()
    defer r.mu.Unlock()
    lobby, ok := r.storage[id]
    if !ok {
        return domain.Lobby{}, ErrLobbyNotFound
    }
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
        return domain.Lobby{}, nil
    }
    r.storage[id] = lobby
    return lobby, nil
}

func (r *InMemoryLobbyRepository) Delete(id domain.LobbyID) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    if _, ok := r.storage[id]; !ok {
        return ErrLobbyNotFound
    }
    delete(r.storage, id)
    return nil
}

