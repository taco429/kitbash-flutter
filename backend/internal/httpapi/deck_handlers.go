package httpapi

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"kitbash/backend/internal/domain"
)

// DeckWithCards represents a deck with populated card details
type DeckWithCards struct {
	*domain.Deck
	PopulatedCards []PopulatedDeckCard `json:"populatedCards"`
}

// PopulatedDeckCard represents a deck card entry with full card details
type PopulatedDeckCard struct {
	Card     *domain.Card `json:"card"`
	Quantity int          `json:"quantity"`
}

// GetAllDecks handles GET /api/decks - returns all available decks
func (a *api) GetAllDecks(w http.ResponseWriter, r *http.Request) {
	decks, err := a.deckRepo.GetAllDecks(r.Context())
	if err != nil {
		a.log.Error("Failed to get all decks", "error", err)
		http.Error(w, "Failed to retrieve decks", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"decks": decks,
		"count": len(decks),
	}); err != nil {
		a.log.Error("Failed to encode decks response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// GetDeck handles GET /api/decks/{deckId} - returns a specific deck with populated card details
func (a *api) GetDeck(w http.ResponseWriter, r *http.Request) {
	deckID := domain.DeckID(chi.URLParam(r, "deckId"))
	if deckID == "" {
		http.Error(w, "Deck ID is required", http.StatusBadRequest)
		return
	}

	deck, err := a.deckRepo.GetDeck(r.Context(), deckID)
	if err != nil {
		a.log.Error("Failed to get deck", "deckID", deckID, "error", err)
		http.Error(w, "Deck not found", http.StatusNotFound)
		return
	}

	// Populate card details
	deckWithCards, err := a.populateDeckCards(r.Context(), deck)
	if err != nil {
		a.log.Error("Failed to populate deck cards", "deckID", deckID, "error", err)
		http.Error(w, "Failed to load deck details", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(deckWithCards); err != nil {
		a.log.Error("Failed to encode deck response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// GetPrebuiltDecks handles GET /api/decks/prebuilt - returns all prebuilt decks
func (a *api) GetPrebuiltDecks(w http.ResponseWriter, r *http.Request) {
	decks, err := a.deckRepo.GetPrebuiltDecks(r.Context())
	if err != nil {
		a.log.Error("Failed to get prebuilt decks", "error", err)
		http.Error(w, "Failed to retrieve prebuilt decks", http.StatusInternalServerError)
		return
	}

	// Populate card details for all prebuilt decks
	var decksWithCards []*DeckWithCards
	for _, deck := range decks {
		deckWithCards, err := a.populateDeckCards(r.Context(), deck)
		if err != nil {
			a.log.Error("Failed to populate cards for deck", "deckID", deck.ID, "error", err)
			continue // Skip this deck if we can't populate its cards
		}
		decksWithCards = append(decksWithCards, deckWithCards)
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"decks": decksWithCards,
		"count": len(decksWithCards),
	}); err != nil {
		a.log.Error("Failed to encode prebuilt decks response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// GetDecksByColor handles GET /api/decks/color/{color} - returns decks of a specific color
func (a *api) GetDecksByColor(w http.ResponseWriter, r *http.Request) {
	colorStr := chi.URLParam(r, "color")
	if colorStr == "" {
		http.Error(w, "Color is required", http.StatusBadRequest)
		return
	}

	color := domain.CardColor(colorStr)
	decks, err := a.deckRepo.GetDecksByColor(r.Context(), color)
	if err != nil {
		a.log.Error("Failed to get decks by color", "color", color, "error", err)
		http.Error(w, "Failed to retrieve decks", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(map[string]interface{}{
		"decks": decks,
		"color": color,
		"count": len(decks),
	}); err != nil {
		a.log.Error("Failed to encode decks by color response", "error", err)
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
	}
}

// populateDeckCards takes a deck and populates it with full card details
func (a *api) populateDeckCards(ctx context.Context, deck *domain.Deck) (*DeckWithCards, error) {
	var populatedCards []PopulatedDeckCard
	
	// Get all cards in the deck (hero + pawns + main cards)
	allCards := deck.GetAllCards()
	
	for _, entry := range allCards {
		card, err := a.cardRepo.GetCard(ctx, entry.CardID)
		if err != nil {
			a.log.Error("Failed to get card for deck", "cardID", entry.CardID, "deckID", deck.ID, "error", err)
			// For now, skip missing cards rather than failing the whole deck
			continue
		}
		
		populatedCards = append(populatedCards, PopulatedDeckCard{
			Card:     card,
			Quantity: entry.Quantity,
		})
	}
	
	return &DeckWithCards{
		Deck:           deck,
		PopulatedCards: populatedCards,
	}, nil
}