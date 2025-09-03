package httpapi

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"kitbash/backend/internal/config"
	"kitbash/backend/internal/logger"
	"kitbash/backend/internal/repository"
)

func setupTestAPI() *api {
	log := logger.NewDefault()
	return &api{
		repo:     repository.NewInMemoryLobbyRepository(log),
		gameRepo: repository.NewInMemoryGameRepository(log),
		cardRepo: repository.NewInMemoryCardRepository(log),
		deckRepo: repository.NewInMemoryDeckRepository(log),
		cfg:      config.Config{},
		log:      log,
	}
}

func TestGetAllCards(t *testing.T) {
	api := setupTestAPI()
	
	req := httptest.NewRequest("GET", "/api/cards", nil)
	w := httptest.NewRecorder()
	
	api.GetAllCards(w, req)
	
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "application/json", w.Header().Get("Content-Type"))
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)
	
	cards, ok := response["cards"].([]interface{})
	require.True(t, ok)
	assert.Len(t, cards, 4) // Should have 4 default cards
	
	count, ok := response["count"].(float64)
	require.True(t, ok)
	assert.Equal(t, float64(4), count)
}

func TestGetCard(t *testing.T) {
	api := setupTestAPI()
	
	req := httptest.NewRequest("GET", "/api/cards/skeleton_001", nil)
	w := httptest.NewRecorder()
	
	// Set up chi URL params
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("cardId", "skeleton_001")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
	
	api.GetCard(w, req)
	
	assert.Equal(t, http.StatusOK, w.Code)
	assert.Equal(t, "application/json", w.Header().Get("Content-Type"))
	
	var card map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &card)
	require.NoError(t, err)
	
	assert.Equal(t, "skeleton_001", card["id"])
	assert.Equal(t, "Skeleton Warrior", card["name"])
	assert.Equal(t, "purple", card["color"])
}

func TestGetCardsByColor(t *testing.T) {
	api := setupTestAPI()
	
	req := httptest.NewRequest("GET", "/api/cards/color/red", nil)
	w := httptest.NewRecorder()
	
	// Set up chi URL params
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("color", "red")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
	
	api.GetCardsByColor(w, req)
	
	assert.Equal(t, http.StatusOK, w.Code)
	
	var response map[string]interface{}
	err := json.Unmarshal(w.Body.Bytes(), &response)
	require.NoError(t, err)
	
	cards, ok := response["cards"].([]interface{})
	require.True(t, ok)
	assert.Len(t, cards, 2) // Should have 2 red cards (goblins)
	
	// Verify all cards are red
	for _, cardInterface := range cards {
		card := cardInterface.(map[string]interface{})
		assert.Equal(t, "red", card["color"])
	}
}

func TestGetCardNotFound(t *testing.T) {
	api := setupTestAPI()
	
	req := httptest.NewRequest("GET", "/api/cards/nonexistent", nil)
	w := httptest.NewRecorder()
	
	// Set up chi URL params
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("cardId", "nonexistent")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))
	
	api.GetCard(w, req)
	
	assert.Equal(t, http.StatusNotFound, w.Code)
}