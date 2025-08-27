package domain

import (
    "time"
)

type LobbyID string
type PlayerID string

type Player struct {
    ID   PlayerID `json:"id"`
    Name string   `json:"name"`
}

type Lobby struct {
    ID         LobbyID   `json:"id"`
    Name       string    `json:"name"`
    HostID     PlayerID  `json:"hostId"`
    Players    []Player  `json:"players"`
    MaxPlayers int       `json:"maxPlayers"`
    CreatedAt  time.Time `json:"createdAt"`
}

