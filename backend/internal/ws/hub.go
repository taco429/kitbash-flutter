package ws

import (
	"net/http"
	"sync"

	"kitbash/backend/internal/config"
	"kitbash/backend/internal/logger"

	"github.com/gorilla/websocket"
)

// Hub tracks active WebSocket connections and handles basic echo I/O.
// It will later broadcast lobby/game events to subscribed clients.
type Hub struct {
	mu       sync.RWMutex
	clients  map[*websocket.Conn]struct{}
	upgrader websocket.Upgrader
	log      *logger.Logger
	cfg      config.Config
}

// NewHub creates a Hub with an open-origin upgrader (dev-friendly).
func NewHub(log *logger.Logger, cfg config.Config) *Hub {
	if log == nil {
		log = logger.Default()
	}
	return &Hub{
		clients: make(map[*websocket.Conn]struct{}),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
		log: log,
		cfg: cfg,
	}
}

// HandleWS upgrades HTTP to WebSocket and echoes messages back.
// Used by /ws and /ws/game/{id} endpoints for quick connectivity checks.
func (h *Hub) HandleWS(w http.ResponseWriter, r *http.Request) {
	h.log.WithContext(r.Context()).Info("WebSocket upgrade requested",
		"path", r.URL.Path,
		"remote_addr", r.RemoteAddr,
		"user_agent", r.UserAgent())

	conn, err := h.upgrader.Upgrade(w, r, nil)
	if err != nil {
		h.log.LogError(r.Context(), err, "WebSocket upgrade failed")
		http.Error(w, "upgrade failed", http.StatusBadRequest)
		return
	}

	h.mu.Lock()
	h.clients[conn] = struct{}{}
	clientCount := len(h.clients)
	h.mu.Unlock()

	h.log.WithContext(r.Context()).Info("WebSocket connection established",
		"remote_addr", conn.RemoteAddr().String(),
		"total_clients", clientCount)

	// Send a minimal welcome with board configuration
	welcome := map[string]interface{}{
		"type": "welcome",
		"boardConfig": map[string]int{
			"rows": h.cfg.BoardRows,
			"cols": h.cfg.BoardCols,
		},
	}
	if err := conn.WriteJSON(welcome); err != nil {
		h.log.LogError(r.Context(), err, "Failed to send welcome message")
	}

	defer func() {
		h.mu.Lock()
		delete(h.clients, conn)
		remainingClients := len(h.clients)
		h.mu.Unlock()

		h.log.WithContext(r.Context()).Info("WebSocket connection closed",
			"remote_addr", conn.RemoteAddr().String(),
			"remaining_clients", remainingClients)

		conn.Close()
	}()

	for {
		messageType, msg, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				h.log.LogError(r.Context(), err, "WebSocket read error",
					"remote_addr", conn.RemoteAddr().String())
			} else {
				h.log.WithContext(r.Context()).Debug("WebSocket connection closed normally",
					"remote_addr", conn.RemoteAddr().String())
			}
			break
		}

		h.log.LogWebSocketEvent(r.Context(), "message_received", map[string]interface{}{
			"remote_addr":  conn.RemoteAddr().String(),
			"message_type": messageType,
			"message_size": len(msg),
			"message":      string(msg),
		})

		// Echo back for now
		if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
			h.log.LogError(r.Context(), err, "WebSocket write error",
				"remote_addr", conn.RemoteAddr().String())
			break
		}

		h.log.LogWebSocketEvent(r.Context(), "message_sent", map[string]interface{}{
			"remote_addr":  conn.RemoteAddr().String(),
			"message_type": websocket.TextMessage,
			"message_size": len(msg),
		})
	}
}
