package httpapi

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"kitbash/backend/internal/domain"
)

// GetAllCards handles GET /api/cards - returns all available cards
func (a *api) GetAllCards(w http.ResponseWriter, r *http.Request) {
	cards, err := a.cardRepo.GetAllCards(r.Context())
	if err != nil {
		a.log.Error("Failed to get all cards", "error", err)
		http.Error(w, "Failed to retrieve cards", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"cards": cards,
		"count": len(cards),
	}); err != nil {
		a.log.Error("Failed to encode cards response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// GetCard handles GET /api/cards/{cardId} - returns a specific card
func (a *api) GetCard(w http.ResponseWriter, r *http.Request) {
	cardID := domain.CardID(chi.URLParam(r, "cardId"))
	if cardID == "" {
		http.Error(w, "Card ID is required", http.StatusBadRequest)
		return
	}

	card, err := a.cardRepo.GetCard(r.Context(), cardID)
	if err != nil {
		a.log.Error("Failed to get card", "cardID", cardID, "error", err)
		http.Error(w, "Card not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(card); err != nil {
		a.log.Error("Failed to encode card response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// GetCardsByColor handles GET /api/cards/color/{color} - returns cards of a specific color
func (a *api) GetCardsByColor(w http.ResponseWriter, r *http.Request) {
	colorStr := chi.URLParam(r, "color")
	if colorStr == "" {
		http.Error(w, "Color is required", http.StatusBadRequest)
		return
	}

	color := domain.CardColor(colorStr)
	cards, err := a.cardRepo.GetCardsByColor(r.Context(), color)
	if err != nil {
		a.log.Error("Failed to get cards by color", "color", color, "error", err)
		http.Error(w, "Failed to retrieve cards", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"cards": cards,
		"color": color,
		"count": len(cards),
	}); err != nil {
		a.log.Error("Failed to encode cards by color response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// GetCardsByType handles GET /api/cards/type/{type} - returns cards of a specific type
func (a *api) GetCardsByType(w http.ResponseWriter, r *http.Request) {
	typeStr := chi.URLParam(r, "type")
	if typeStr == "" {
		http.Error(w, "Type is required", http.StatusBadRequest)
		return
	}

	cardType := domain.CardType(typeStr)
	cards, err := a.cardRepo.GetCardsByType(r.Context(), cardType)
	if err != nil {
		a.log.Error("Failed to get cards by type", "type", cardType, "error", err)
		http.Error(w, "Failed to retrieve cards", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"cards": cards,
		"type":  cardType,
		"count": len(cards),
	}); err != nil {
		a.log.Error("Failed to encode cards by type response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}