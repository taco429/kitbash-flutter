#!/bin/bash

# Test script to verify deck and discard pile viewing functionality

echo "Testing Deck and Discard Pile Viewing Feature"
echo "============================================="
echo ""

# 1. Create a test lobby first
echo "1. Creating a test lobby..."
LOBBY_RESPONSE=$(curl -s -X POST http://localhost:8080/api/lobbies \
  -H "Content-Type: application/json" \
  -d '{
    "hostId": "test-host",
    "hostName": "Test Host",
    "name": "Test Lobby"
  }')
LOBBY_ID=$(echo $LOBBY_RESPONSE | grep -o '"id":"[^"]*' | sed 's/"id":"//')
echo "Lobby created with ID: $LOBBY_ID"
echo ""

# 2. Join the lobby with another player
echo "2. Joining lobby with second player..."
curl -s -X POST http://localhost:8080/api/lobbies/$LOBBY_ID/join \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "test-player",
    "playerName": "Test Player"
  }' > /dev/null
echo "Second player joined"
echo ""

# 3. Start the game
echo "3. Starting the game..."
START_RESPONSE=$(curl -s -X POST http://localhost:8080/api/lobbies/$LOBBY_ID/start \
  -H "Content-Type: application/json" \
  -d '{
    "playerId": "test-host"
  }')
GAME_ID=$(echo $START_RESPONSE | grep -o '"gameId":"[^"]*' | sed 's/"gameId":"//')
echo "Game started with ID: $GAME_ID"
echo ""

if [ -z "$GAME_ID" ]; then
  echo "Failed to start game. Response: $START_RESPONSE"
  exit 1
fi

# 4. Get game state
echo "4. Getting game state..."
GAME_STATE=$(curl -s http://localhost:8080/api/games/$GAME_ID)
echo ""

# 5. Check if player states include drawPile and discardPile
echo "5. Checking for deck (drawPile) and discard pile data..."
echo "Raw game state (first 500 chars):"
echo $GAME_STATE | head -c 500
echo ""
echo ""

# Check for drawPile field
if echo "$GAME_STATE" | grep -q '"drawPile"'; then
  echo "✓ Draw pile data is exposed in the API"
  # Extract first draw pile card
  FIRST_DRAW_CARD=$(echo $GAME_STATE | grep -o '"drawPile":\[[^]]*' | head -1 | grep -o '"cardId":"[^"]*' | head -1 | sed 's/"cardId":"//')
  if [ ! -z "$FIRST_DRAW_CARD" ]; then
    echo "  - First card in draw pile: $FIRST_DRAW_CARD"
  fi
else
  echo "✗ Draw pile data is NOT exposed in the API"
fi
echo ""

# Check for discardPile field
if echo "$GAME_STATE" | grep -q '"discardPile"'; then
  echo "✓ Discard pile data is exposed in the API"
  # Extract discard pile count
  DISCARD_COUNT=$(echo $GAME_STATE | grep -o '"discardPile":\[[^]]*' | head -1 | grep -o '"cardId"' | wc -l)
  echo "  - Cards in discard pile: $DISCARD_COUNT"
else
  echo "✗ Discard pile data is NOT exposed in the API"
fi
echo ""

# Check deck count
DECK_COUNT=$(echo $GAME_STATE | grep -o '"deckCount":[0-9]*' | head -1 | sed 's/"deckCount"://')
if [ ! -z "$DECK_COUNT" ]; then
  echo "✓ Deck count: $DECK_COUNT cards remaining"
fi
echo ""

echo "Test complete!"
echo ""
echo "Summary:"
echo "- Game created successfully: $([ ! -z "$GAME_ID" ] && echo "✓" || echo "✗")"
echo "- Draw pile data exposed: $(echo $GAME_STATE | grep -q '"drawPile"' && echo "✓" || echo "✗")"
echo "- Discard pile data exposed: $(echo $GAME_STATE | grep -q '"discardPile"' && echo "✓" || echo "✗")"