# Card Collection & Deck System Implementation

This document summarizes the card collection and deck system that has been implemented for the Kitbash CCG Flutter game.

## Overview

We've successfully created a comprehensive **backend-driven** card system with:
- **Go Backend API**: RESTful endpoints for cards and decks
- **4 Creature Cards**: Skeleton Warrior, Skeleton Archer (purple) and Goblin Raider, Goblin Chieftain (red)
- **2 Pre-built Decks**: Red Goblin Swarm and Purple Undead Legion served from backend
- **Flutter Frontend**: Consumes backend APIs with proper loading states and error handling
- **Complete Architecture**: Proper separation between client and server

## Architecture Overview

### Backend (Go)

1. **Domain Models** (`backend/internal/domain/card.go`)
   - `Card`: Core card definition with cost, attack, health, abilities
   - `Deck`: Collection of cards with metadata
   - `DeckCardEntry`: Card instances in decks with quantities
   - Support for card types (Creature, Spell, Artifact) and colors (Red, Purple, etc.)

2. **Repositories** (`backend/internal/repository/`)
   - `InMemoryCardRepository`: Manages card data with thread-safe operations
   - `InMemoryDeckRepository`: Manages deck data with prebuilt deck seeding
   - Both implement proper interfaces for future database integration

3. **API Handlers** (`backend/internal/httpapi/`)
   - RESTful endpoints for cards and decks
   - Proper error handling and JSON responses
   - Card population for deck details

### Frontend (Flutter)

1. **Models** (`lib/models/`)
   - `GameCard`: Flutter representation matching backend Card structure
   - `DeckCard`: Card instances with quantities
   - `Deck`: Frontend deck model

2. **Services** (`lib/services/`)
   - `CardService`: HTTP client for card API endpoints
   - `DeckService`: HTTP client for deck API endpoints
   - Both include loading states, error handling, and caching

### Card Implementations

#### Skeleton Cards (Purple)
- **Skeleton Warrior**: Cost 2, 2/1 creature with Undead ability
- **Skeleton Archer**: Cost 3, 2/2 creature with Undead and Ranged abilities

#### Goblin Cards (Red)
- **Goblin Raider**: Cost 1, 2/1 creature with Haste ability
- **Goblin Chieftain**: Cost 3, 3/2 creature with Haste and Rally abilities

## API Endpoints

### Card Endpoints
- `GET /api/cards` - Get all available cards
- `GET /api/cards/{cardId}` - Get specific card by ID
- `GET /api/cards/color/{color}` - Get cards by color (red, purple, etc.)
- `GET /api/cards/type/{type}` - Get cards by type (creature, spell, artifact)

### Deck Endpoints
- `GET /api/decks` - Get all decks
- `GET /api/decks/prebuilt` - Get prebuilt decks with populated card details
- `GET /api/decks/{deckId}` - Get specific deck with full card information
- `GET /api/decks/color/{color}` - Get decks by color

### Health Check
- `GET /healthz` - Server health check endpoint

## Data Flow

1. **Backend**: Serves card definitions and prebuilt decks via REST API
2. **Frontend**: Fetches data on startup and caches it locally
3. **Real-time**: Ready for WebSocket integration for live deck updates
4. **Persistence**: In-memory storage (easily replaceable with database)

## User Interface

### CardWidget (`lib/widgets/card_widget.dart`)
- Visual representation of game cards
- Supports both full and compact display modes
- Color-coded by card faction
- Shows all card stats (cost, attack, health, abilities)
- Interactive with tap handling

### CollectionScreen (`lib/screens/collection_screen.dart`)
- Three-tab interface:
  1. **All Cards**: Grid view of entire collection with statistics
  2. **Red Deck**: Detailed view of the Goblin Swarm deck
  3. **Purple Deck**: Detailed view of the Undead Legion deck
- Card detail dialogs with full information
- Deck composition analysis

### Menu Integration
- Added "View Collection" button to main menu
- Seamless navigation to collection screen

## Test Coverage

Comprehensive test suites included:
- **Card Model Tests** (`test/models/card_test.dart`)
  - Card property validation
  - JSON serialization/deserialization
  - Power level calculations
  - Collection filtering

- **Deck Service Tests** (`test/services/deck_service_test.dart`)
  - Deck initialization
  - Card composition validation
  - Deck selection functionality
  - Error handling for invalid deck IDs

## Deck Compositions

### Red Goblin Swarm Deck (30 cards)
- 23x Goblin Raider (1 cost, 2/1, Haste)
- 7x Goblin Chieftain (3 cost, 3/2, Haste + Rally)
- **Strategy**: Aggressive, low-cost creatures for quick attacks

### Purple Undead Legion Deck (30 cards)
- 15x Skeleton Warrior (2 cost, 2/1, Undead)
- 15x Skeleton Archer (3 cost, 2/2, Undead + Ranged)
- **Strategy**: Balanced mix of melee and ranged undead units

## Integration Points

The card system is fully integrated with:
- **Provider State Management**: CardService and updated DeckService
- **Main App**: Services registered in main.dart
- **Navigation**: Accessible from main menu
- **Game Logic**: Ready for integration with game mechanics

## Future Expansion

The system is designed for easy expansion:
- Add new card types (Spells, Artifacts)
- Implement more factions/colors
- Create deck building functionality
- Add card rarity system
- Implement card effects and abilities system

## Files Created/Modified

### Backend Files (New)
- `backend/internal/domain/card.go` - Card and deck domain models with repositories interfaces
- `backend/internal/repository/card_repository.go` - In-memory card repository with default cards
- `backend/internal/repository/deck_repository.go` - In-memory deck repository with prebuilt decks
- `backend/internal/httpapi/card_handlers.go` - REST API handlers for card endpoints
- `backend/internal/httpapi/deck_handlers.go` - REST API handlers for deck endpoints
- `backend/internal/httpapi/card_handlers_test.go` - API endpoint tests
- `backend/test_api.sh` - API testing script

### Frontend Files (New)
- `lib/models/card.dart` - Frontend card models matching backend structure
- `lib/widgets/card_widget.dart` - Card display widget
- `lib/screens/collection_screen.dart` - Collection viewer with API integration
- `test/models/card_test.dart` - Card model tests
- `test/services/deck_service_test.dart` - Deck service tests

### Frontend Files (Modified)
- `lib/models/deck.dart` - Updated to use DeckCard instances
- `lib/services/card_service.dart` - HTTP client for backend card API
- `lib/services/deck_service.dart` - HTTP client for backend deck API with loading states
- `lib/main.dart` - Added CardService provider
- `lib/screens/menu_screen.dart` - Added collection screen navigation

### Backend Files (Modified)
- `backend/internal/httpapi/router.go` - Added card and deck API routes and repositories

The card collection and deck system is now fully functional and ready for gameplay integration!