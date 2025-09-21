#!/bin/bash

# Test script for unit mechanics
echo "Testing Unit Mechanics in Kitbash Game"
echo "======================================"

# Check if server is running
if ! curl -s http://localhost:8080/api/cards > /dev/null 2>&1; then
    echo "Backend server is not running. Please start it first."
    exit 1
fi

echo "✓ Backend server is running"

# Create a test game
echo ""
echo "Creating test game..."
GAME_RESPONSE=$(curl -s -X POST http://localhost:8080/api/games \
    -H "Content-Type: application/json" \
    -d '{
        "player1": {"id": "test1", "name": "Player 1"},
        "player2": {"id": "test2", "name": "Player 2"},
        "boardRows": 13,
        "boardCols": 11
    }')

GAME_ID=$(echo $GAME_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "$GAME_ID" ]; then
    echo "Failed to create game"
    exit 1
fi

echo "✓ Created game with ID: $GAME_ID"

# Connect to WebSocket and simulate playing unit cards
echo ""
echo "Testing unit card plays..."
echo ""
echo "To test units:"
echo "1. Open two browser windows"
echo "2. Navigate to http://localhost:3000 (or your Flutter web port)"
echo "3. Join the game with ID: $GAME_ID"
echo "4. Play goblin or ghoul cards to spawn units"
echo "5. Watch units move and attack automatically"
echo ""
echo "Unit behaviors to observe:"
echo "- Units spawn at the played position"
echo "- Units move towards enemy command center each turn"
echo "- Units attack enemies in range"
echo "- Units show health bars and direction indicators"
echo "- Gold is refunded if spawn position is blocked"
echo ""
echo "Game ID: $GAME_ID"