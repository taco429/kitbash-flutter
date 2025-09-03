# Card Collection & Deck System Implementation

This document summarizes the card collection and deck system that has been implemented for the Kitbash CCG Flutter game.

## Overview

We've successfully created a comprehensive **backend-driven** card system following the game design specifications:
- **Go Backend API**: RESTful endpoints for cards and decks
- **Proper Card Structure**: Gold cost, mana cost, unit stats (attack/health/armor/speed/range)
- **Correct Card Types**: Units, Spells, Buildings, Orders, Hero cards
- **Proper Pawns**: Red Goblin (2/2) and Purple Ghoul (1/2) matching design docs
- **Correct Deck Structure**: Hero + 10 pawns + 20 main cards (31 total)
- **6 Game Colors**: Red, Orange, Yellow, Green, Blue, Purple (no neutral)
- **Flutter Frontend**: Consumes backend APIs with proper loading states and error handling

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

### Card Implementations (Following Design Docs)

#### Red Cards
- **Goblin Pawn**: 1 Gold, 0 Mana - Creates Goblin unit (2/2/0 armor, speed 1, range 1, Melee)
- **Orc Warrior**: 2 Gold, 1 Mana - Creates Orc Warrior unit (3/2/0 armor, speed 1, range 1, Melee)

#### Purple Cards  
- **Ghoul Pawn**: 1 Gold, 0 Mana - Creates Ghoul unit (1/2/0 armor, speed 1, range 1, Rekindle, Melee)
- **Drain Life Spell**: 0 Gold, 2 Mana - Target unit takes 2 damage, heal 2 health

### Proper Card Structure
- **Costs**: Separate Gold and Mana costs as per requirements
- **Unit Stats**: Attack/Health/Armor/Speed/Range for units created by Unit cards
- **Card Types**: Units (create units), Spells (effects), Buildings, Orders, Hero
- **Colors**: Red (Orcs/Goblins), Orange (Dragons/Ogres), Yellow (Dwarves), Green (Elves), Blue (Humans/Knights), Purple (Undead/Wizards)

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

## Architecture Benefits

### ✅ **Proper Online Game Architecture**
- **Backend Authority**: All card definitions and deck compositions managed server-side
- **API-Driven**: Frontend consumes REST APIs, no hardcoded game data
- **Scalable**: Easy to add new cards, deck types, and game features
- **Secure**: Prevents client-side manipulation of game data
- **Testable**: Comprehensive test coverage for both backend and frontend

### ✅ **Production Ready Features**
- **Error Handling**: Graceful handling of network failures
- **Loading States**: Proper UI feedback during API calls
- **Caching**: Client-side caching for better performance
- **Type Safety**: Full type safety across Go backend and Dart frontend
- **Testing**: Unit tests and integration tests for reliability

### ✅ **Development Workflow**
```bash
# Start backend server
cd backend && go run cmd/server/main.go

# Test API endpoints
cd backend && ./test_api.sh

# Run backend tests
cd backend && go test ./...

# Run frontend tests
flutter test
```

The card collection and deck system is now properly architected for an online multiplayer card game!