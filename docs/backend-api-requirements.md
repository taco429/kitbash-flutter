# Kitbash CCG - Backend API Requirements

## Scope

Defines the backend service APIs required to facilitate Kitbash CCG across meta systems and real-time matches. Aligned with `docs/game-design.md`, `docs/card-design.md`, `docs/meta-features.md`, and current client service expectations in `lib/services/game_service.dart`.

- Platforms: mobile/desktop/web clients
- Transport: HTTPS for REST; WSS for real-time match channels
- Auth: JWT bearer tokens unless otherwise noted
- Versioning: Prefix REST with `/api/v1`; WebSocket message schema with `schema: v1`

## High-Level Domains

- Identity & Auth
- Player Profile & Progression
- Card Catalog & Collection
- Deck Management & Validation
- Matchmaking & Lobby
- Private Matches (custom/spectate)
- Real-Time Match Service (WebSocket)
- Leaderboards, Match History, Telemetry
- Admin & Live Ops (non-player)

---

## Identity & Auth

- POST /api/v1/auth/register
  - Request: { email, password, displayName }
  - Response: { playerId, token, refreshToken }
- POST /api/v1/auth/login
  - Request: { email, password }
  - Response: { playerId, token, refreshToken }
- POST /api/v1/auth/refresh
  - Request: { refreshToken }
  - Response: { token, refreshToken }
- POST /api/v1/auth/logout
  - Invalidate refresh token

Requirements:
- JWT in Authorization: Bearer <token>
- Rate limiting and brute-force protection
- Email/password are placeholder; support SSO providers later

---

## Player Profile & Progression

- GET /api/v1/player/profile
  - Response: { playerId, displayName, mmr: { ranked, casual }, cosmetics, settings }
- PATCH /api/v1/player/profile
  - Update displayName, settings
- GET /api/v1/player/progress
  - Response: { mapProgress, quests, achievements }

---

## Card Catalog & Collection

- GET /api/v1/cards/catalog
  - Response: full static catalog for the client (ids, names, types, colors, rules text, base stats, rarity). Server-authoritative; omit hidden/internal knobs.
- GET /api/v1/cards/:cardId
- GET /api/v1/player/collection
  - Response: { cards: [{ cardId, ownedCopies }], currencies: { essence, goldCosmetic }, blueprints: [{ cardId, fragments }] }
- POST /api/v1/player/craft
  - Request: { cardId, useFragments: boolean }
  - Response: updated collection snapshot
- POST /api/v1/player/rewards/claim
  - Request: { rewardId, source }
  - Response: delta changes (cards, fragments, currencies)

Requirements:
- Duplicate handling and essence conversion per meta rules
- Server validates crafting costs and pity/fragment rules

---

## Deck Management & Validation

- GET /api/v1/player/decks
  - Response: [{ deckId, name, heroId, cardEntries: [{ cardId, count }], lastUpdated }]
- POST /api/v1/player/decks
  - Create deck; body mirrors deck shape
- PUT /api/v1/player/decks/:deckId
- DELETE /api/v1/player/decks/:deckId
- POST /api/v1/player/decks/:deckId/validate
  - Response: { isValid, errors: [ { code, message, field } ], computed: { size, rarityCounts, colorIdentity } }
- POST /api/v1/player/decks/import
  - Request: { importCode }
  - Response: deck representation after server validation
- GET /api/v1/player/decks/:deckId/export
  - Response: { importCode }

Validation rules (server-enforced):
- Deck size 30–40
- Exactly one Hero and color identity constraints
- Copy limits by rarity/type (tunable)
- Signature cards excluded from counts and provided by hero at runtime

---

## Matchmaking & Lobby

- POST /api/v1/matchmaking/queue
  - Request: { mode: 'casual'|'ranked', deckId, region?, latency?, heroId? }
  - Response: { ticketId, estimatedWaitMs }
- DELETE /api/v1/matchmaking/queue
  - Cancel queued ticket
- GET /api/v1/matchmaking/status?ticketId=...
  - Response: { status: 'searching'|'matched'|'cancelled'|'expired',
               matchId?, serverWsUrl?, wsAuthToken? }

Server behavior:
- Hidden MMR per mode, expanding search window
- Region and latency-aware server selection
- On match: create match record, return secured WebSocket URL and a one-time wsAuthToken (short-lived)

---

## Private Matches & Lobbies

- GET /api/v1/games
  - List available public lobbies (aligns with current client)
- POST /api/v1/games
  - Create lobby (private or public): { visibility: 'public'|'private', deckId, heroId }
  - Response: { gameId, inviteCode }
- POST /api/v1/games/:gameId/join
  - Join lobby (matches existing client call)
- POST /api/v1/games/:gameId/leave
- POST /api/v1/games/:gameId/start
  - Host-only; returns wsAuthToken and ws URL
- POST /api/v1/games/:gameId/spectate
  - Response: { serverWsUrl, wsAuthToken, permissions: 'readOnly' }

---

## Real-Time Match Service (WebSocket)

Endpoint:
- wss://<host>/ws/game/:matchId (requires `wsAuthToken` as header or query)

Connection & Handshake:
- Client sends { type: 'hello', schema: 'v1', token: <jwt or wsAuthToken>, clientBuild: <semver> }
- Server replies { type: 'welcome', matchId, playerId, role: 'player'|'spectator', seqStart, seed, boardConfig }
- Heartbeats: client->server `ping` every 5s; server responds `pong` or vice versa

Message Envelope (all messages):
```json
{
  "type": "string",
  "seq": 123,           // server-issued sequence for server->client; client supplies clientSeq for idempotency
  "ack": 120,           // highest remote seq this sender has processed (for loss recovery)
  "ts": 1731972000000,  // ms since epoch
  "payload": { }
}
```

Authoritative State & Determinism:
- Server is authoritative over board, hands, decks, resources
- Shuffle/draws driven by a server seed stored on match; random events reproducible
- Priority token alternates each round per rules; server communicates holder

Core Server->Client Events:
- match.start { players, heroes, startingStructures, priorityHolder, roundNumber: 1, resources, handSizes }
- round.start { roundNumber, priorityHolder, timers: { planningEndAt }, resourcesDelta, draws: { counts } }
- planning.timer { remainingMs }
- planning.locked_in { playerId }
- state.full { state, checksum }
- state.patch { diff, baseSeq }
- resolution.timeline { roundNumber, steps: [ { kind, data } ... ] }
  - steps kinds include: spellsResolved, summons, startOfRound, movements, onMoveTriggers, combats, deaths, endOfRound
- round.end { summary: { deaths, damageToCC, resourceChanges } }
- match.end { result: { winnerPlayerId, reason }, stats }
- player.disconnect { playerId }
- player.reconnect { playerId }
- error { code, message, details }

Core Client->Server Events:
- lobby.ready { deckId, heroId } // pre-start, optional in private lobbies
- planning.submit_orders {
    "roundNumber": 3,
    "orders": [
      { "type": "play_card", "handInstanceId": "h123", "cardId": "c_red_breach_runner", "placement": { "x": 5, "y": 1 } },
      { "type": "cast_spell", "handInstanceId": "h999", "cardId": "c_blue_phase_shift", "targets": [{"unitId": "u_ally_7"}], "params": {"distance": 2} },
      { "type": "activate_ability", "unitId": "u_ally_3", "abilityId": "hold_position", "params": {"hold": true} },
      { "type": "discard_cards", "handInstanceIds": ["h777", "h778"] }
    ],
    "clientSeq": 45,
    "actionId": "uuid-1" // idempotency key
  }
- planning.lock_in { roundNumber, clientSeq, actionId }
- planning.unlock { roundNumber } // if allowed before both locked or timer
- request.state_full {}
- request.resync { fromSeq }
- client.ping { nonce }

Server Validation Rules (non-exhaustive, enforced on submit):
- Resource checks (Mana ephemeral, Gold persistent)
- Placement legality (deployment zone, base restrictions, neutral allowances per card text)
- Hand limits (draw to limit, hard cap 10)
- Deck exhaustion penalty (-25 CC HP and reshuffle discard)
- Signature card cooldowns
- Activated ability timing windows and per-round limits
- Simultaneous resolution ordering and tie-breaking with priority token

Reconnection & Resync:
- Client may reconnect with wsAuthToken or match-scoped JWT; server restores role and sends `state.full` and missed `state.patch` based on `fromSeq`
- Grace period and AFK policies configurable; disconnections reported via events

Spectator Mode:
- Read-only; receives `state.full`, `state.patch`, `resolution.timeline`, timers; hidden private info (hands) unless authorized for replays

Error Handling:
- Consistent `error` messages with `code` enums (e.g., INVALID_ORDER, OUT_OF_RESOURCES, ILLEGAL_PLACEMENT, STALE_ROUND)
- Include `retriable: true|false` and optional `suggestedAction`

Security & Anti-Cheat:
- All client inputs validated; server authoritative on randomness and resolution
- Action idempotency via `actionId`
- Rate limiting per connection and per action type
- Optional message signing of critical actions (later)

---

## Match State Model (Overview)

Entity IDs:
- playerId, matchId, unitId, structureId, cardInstanceId, handInstanceId are opaque server-generated strings

Board & Grid:
- Default 11 columns × 13 rows; 0-indexed
- Base zones: rows 0–2 (Player A) and 10–12 (Player B); columns 2–8 are base; columns 0–1 and 9–10 are side buffers (not base)

State Shape (illustrative):
```json
{
  "matchId": "m_abc",
  "roundNumber": 4,
  "priorityHolder": "p2",
  "board": { "cols": 11, "rows": 13, "tiles": [{"x":5,"y":0,"occupant": {"type":"structure","id":"cc_p1"}}] },
  "players": [
    {
      "playerId": "p1",
      "heroId": "h_red_kael",
      "ccHp": 100,
      "resources": { "mana": 3, "gold": 2 },
      "hand": [{"handInstanceId":"h1","cardId":"c_red_breach_runner","revealed":false}],
      "deckCount": 26,
      "discard": ["c_red_burnout"],
      "cooldowns": { "signature": 1 }
    },
    { "playerId": "p2", "heroId": "h_blue_ione", "ccHp": 100, "resources": { "mana": 2, "gold": 3 }, "deckCount": 28 }
  ],
  "units": [{ "id":"u1","owner":"p1","cardId":"c_red_breach_runner","pos":{"x":5,"y":1},"atk":3,"hp":1,"rng":1,"spd":2,"keywords":["charge","siege_1"] }],
  "structures": [{ "id":"cc_p1","owner":"p1","kind":"command_center","pos":{"x":5,"y":0},"stats": {"manaGen":1,"goldGen":1}}],
  "effects": [{ "id":"e1","type":"aura","targets":["u1"],"expiresAtRound":4 }],
  "timers": { "planningEndAt": 1731972005000 }
}
```

---

## Leaderboards & Match History

- GET /api/v1/leaderboard?mode=ranked&season=current&limit=100
  - Response: { season, entries: [{ playerId, rank, rating, wins, losses }] }
- GET /api/v1/matches/recent?playerId=me&limit=20
  - Response: [{ matchId, time, mode, opponent, result, duration }]
- GET /api/v1/matches/:matchId
  - Response: { header, redactedStates?, summary, telemetry? }

---

## Telemetry (Server-side)

- Ingest match outcomes, deck usage, encounter rates, performance metrics
- A/B flags for drop rates, matchmaking windows, timers

---

## Admin & Live Ops (Out of scope for client)

- Card balance toggles, drop tables, seasons, rewards
- Ban tools, moderation, economy controls

---

## Non-Functional Requirements

- Latency: WebSocket designed for 50–200ms round-trip; timers tolerant of drift
- Scalability: Stateless REST, stateful match shards; horizontal scale
- Reliability: At-least-once delivery semantics with seq/ack; idempotent actions
- Observability: Structured logs, metrics, tracing; per-match logs
- Security: TLS everywhere; JWT validation; CORS for web; rate limiting
- Compatibility: Schema versioning; graceful client downgrade messages

---

## Mapping to Current Client (Flutter)

- Implemented REST:
  - GET /api/games
  - POST /api/games/:id/join
- Implemented WS path:
  - ws://localhost:8080/ws/game/:id (handshake and message types above)

Backwards-compatible Plan:
- Keep existing endpoints, add versioned `/api/v1` alongside; redirect legacy paths until clients migrate
- Add `game.state` full and patch messages; implement `planning.submit_orders` and `resolution.timeline` to support simultaneous resolution

---

## OpenAPI & Event Schema

- Provide OpenAPI 3.1 spec for REST
- Provide JSON Schemas for WebSocket events and state payloads with `schema: v1`