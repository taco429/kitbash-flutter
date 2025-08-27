package domain

import (
    "time"
)

// LobbyID uniquely identifies a lobby.
type LobbyID string
// PlayerID uniquely identifies a player.
type PlayerID string

// Player is a user participating in a lobby.
type Player struct {
    ID   PlayerID `json:"id"`
    Name string   `json:"name"`
}

// Lobby groups players before starting a game.
type Lobby struct {
    ID         LobbyID   `json:"id"`
    Name       string    `json:"name"`
    HostID     PlayerID  `json:"hostId"`
    Players    []Player  `json:"players"`
    MaxPlayers int       `json:"maxPlayers"`
    CreatedAt  time.Time `json:"createdAt"`
}

