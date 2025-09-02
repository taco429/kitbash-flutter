package repository

import (
	"context"
	"fmt"
	"sync"

	"kitbash/backend/internal/domain"
	"kitbash/backend/internal/logger"
)

// GameRepository defines the interface for game state management.
type GameRepository interface {
	Create(ctx context.Context, gameID domain.GameID, players []domain.Player, boardRows, boardCols int) (*domain.GameState, error)
	Get(ctx context.Context, gameID domain.GameID) (*domain.GameState, error)
	Update(ctx context.Context, gameState *domain.GameState) error
	Delete(ctx context.Context, gameID domain.GameID) error
	List(ctx context.Context) ([]*domain.GameState, error)
}

// InMemoryGameRepository implements GameRepository using in-memory storage.
type InMemoryGameRepository struct {
	mu    sync.RWMutex
	games map[domain.GameID]*domain.GameState
	log   *logger.Logger
}

// NewInMemoryGameRepository creates a new in-memory game repository.
func NewInMemoryGameRepository(log *logger.Logger) *InMemoryGameRepository {
	return &InMemoryGameRepository{
		games: make(map[domain.GameID]*domain.GameState),
		log:   log,
	}
}

// Create creates a new game state.
func (r *InMemoryGameRepository) Create(ctx context.Context, gameID domain.GameID, players []domain.Player, boardRows, boardCols int) (*domain.GameState, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.games[gameID]; exists {
		return nil, fmt.Errorf("game with ID %s already exists", gameID)
	}

	gameState := domain.NewGameState(gameID, players, boardRows, boardCols)
	r.games[gameID] = gameState

	r.log.WithContext(ctx).Info("Created new game state", 
		"game_id", gameID, 
		"players", len(players),
		"board_size", fmt.Sprintf("%dx%d", boardRows, boardCols))

	return gameState, nil
}

// Get retrieves a game state by ID.
func (r *InMemoryGameRepository) Get(ctx context.Context, gameID domain.GameID) (*domain.GameState, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	gameState, exists := r.games[gameID]
	if !exists {
		return nil, fmt.Errorf("game with ID %s not found", gameID)
	}

	return gameState, nil
}

// Update updates an existing game state.
func (r *InMemoryGameRepository) Update(ctx context.Context, gameState *domain.GameState) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.games[gameState.ID]; !exists {
		return fmt.Errorf("game with ID %s not found", gameState.ID)
	}

	r.games[gameState.ID] = gameState

	r.log.WithContext(ctx).Debug("Updated game state", 
		"game_id", gameState.ID, 
		"status", gameState.Status,
		"turn_count", gameState.TurnCount)

	return nil
}

// Delete removes a game state.
func (r *InMemoryGameRepository) Delete(ctx context.Context, gameID domain.GameID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.games[gameID]; !exists {
		return fmt.Errorf("game with ID %s not found", gameID)
	}

	delete(r.games, gameID)

	r.log.WithContext(ctx).Info("Deleted game state", "game_id", gameID)

	return nil
}

// List returns all game states.
func (r *InMemoryGameRepository) List(ctx context.Context) ([]*domain.GameState, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	games := make([]*domain.GameState, 0, len(r.games))
	for _, gameState := range r.games {
		games = append(games, gameState)
	}

	return games, nil
}