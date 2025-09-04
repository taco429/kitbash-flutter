#!/bin/bash

echo "Testing Kitbash Backend API Endpoints"
echo "======================================="

BASE_URL="http://192.168.4.156:8080/api"

echo
echo "1. Testing Health Check..."
curl -s http://192.168.4.156:8080/healthz
echo

echo
echo "2. Testing Get All Cards..."
curl -s "$BASE_URL/cards" | head -c 200
echo "..."

echo
echo "3. Testing Get Specific Card (Skeleton)..."
curl -s "$BASE_URL/cards/skeleton_001" | head -c 200
echo "..."

echo
echo "4. Testing Get Cards by Color (Red)..."
curl -s "$BASE_URL/cards/color/red" | head -c 200
echo "..."

echo
echo "5. Testing Get Cards by Type (Creature)..."
curl -s "$BASE_URL/cards/type/creature" | head -c 200
echo "..."

echo
echo "6. Testing Get All Decks..."
curl -s "$BASE_URL/decks" | head -c 200
echo "..."

echo
echo "7. Testing Get Prebuilt Decks..."
curl -s "$BASE_URL/decks/prebuilt" | head -c 200
echo "..."

echo
echo "8. Testing Get Specific Deck (Red Goblin)..."
curl -s "$BASE_URL/decks/red_deck_001" | head -c 200
echo "..."

echo
echo "API Test Complete!"