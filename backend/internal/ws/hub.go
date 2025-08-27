package ws

import (
    "log"
    "net/http"
    "sync"

    "github.com/gorilla/websocket"
)

// Hub tracks active WebSocket connections and handles basic echo I/O.
// It will later broadcast lobby/game events to subscribed clients.
type Hub struct {
    mu       sync.RWMutex
    clients  map[*websocket.Conn]struct{}
    upgrader websocket.Upgrader
}

// NewHub creates a Hub with an open-origin upgrader (dev-friendly).
func NewHub() *Hub {
    return &Hub{
        clients: make(map[*websocket.Conn]struct{}),
        upgrader: websocket.Upgrader{
            CheckOrigin: func(r *http.Request) bool { return true },
        },
    }
}

// HandleWS upgrades HTTP to WebSocket and echoes messages back.
// Used by /ws and /ws/game/{id} endpoints for quick connectivity checks.
func (h *Hub) HandleWS(w http.ResponseWriter, r *http.Request) {
    conn, err := h.upgrader.Upgrade(w, r, nil)
    if err != nil {
        http.Error(w, "upgrade failed", http.StatusBadRequest)
        return
    }
    h.mu.Lock()
    h.clients[conn] = struct{}{}
    h.mu.Unlock()
    defer func() {
        h.mu.Lock()
        delete(h.clients, conn)
        h.mu.Unlock()
        conn.Close()
    }()

    for {
        _, msg, err := conn.ReadMessage()
        if err != nil {
            break
        }
        // Echo back for now
        if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
            log.Printf("ws write error: %v", err)
            break
        }
    }
}

