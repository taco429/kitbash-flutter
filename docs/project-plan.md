# Kitbash CCG - Project Plan & TODOs

## Project Overview

Building a cross-platform collectible card game client using Flutter and Flame that connects to a Go backend for multiplayer functionality.

## Current Status

- ✅ Basic Flutter project structure
- ✅ Flame game engine integration
- ✅ REST API service foundation
- ✅ WebSocket connection handling
- ✅ Basic menu and game screens
- ⏳ Game mechanics implementation
- ⏳ Card rendering system
- ⏳ Multiplayer synchronization

## Development Phases

### Phase 1: Foundation (Current)
- [x] Initialize Flutter project
- [x] Add Flame dependency
- [x] Create basic project structure
- [x] Set up REST/WebSocket services
- [x] Create navigation flow
- [ ] Add error handling and retry logic
- [ ] Implement connection state management
- [ ] Create loading states and indicators

### Phase 2: Core Game Engine
- [ ] Design card component system
- [ ] Implement game board layout
- [ ] Create drag-and-drop mechanics
- [ ] Add card animation system
- [ ] Implement game state management
- [ ] Create turn-based logic
- [ ] Add game rules engine

### Phase 3: Multiplayer Integration
- [ ] Sync game state via WebSocket
- [ ] Handle player actions
- [ ] Implement conflict resolution
- [ ] Add reconnection logic
- [ ] Create spectator mode
- [ ] Handle disconnections gracefully

### Phase 4: User Interface
- [ ] Design card layouts
- [ ] Create deck builder UI
- [ ] Implement collection browser
- [ ] Add player profile screen
- [ ] Create settings screen
- [ ] Design match history view
- [ ] Add friend list functionality

### Phase 5: Game Features
- [ ] Implement card abilities
- [ ] Add visual effects
- [ ] Create sound system
- [ ] Implement card rarity system
- [ ] Add deck validation
- [ ] Create tutorial mode
- [ ] Implement AI opponents

### Phase 6: Polish & Optimization
- [ ] Optimize rendering performance
- [ ] Add particle effects
- [ ] Implement caching strategy
- [ ] Create offline mode
- [ ] Add analytics
- [ ] Implement crash reporting
- [ ] Performance profiling

## Technical TODOs

### Immediate Priority
1. **Asset Management**
   - [ ] Create asset loading system
   - [ ] Design card template structure
   - [ ] Implement sprite caching

2. **Network Layer**
   - [ ] Add request interceptors
   - [ ] Implement token-based auth
   - [ ] Create message queue for WebSocket

3. **State Management**
   - [ ] Implement game state provider
   - [ ] Create match state handling
   - [ ] Add persistent storage

### Code Quality
- [ ] Add unit tests for services
- [ ] Create widget tests
- [ ] Implement integration tests
- [ ] Set up code coverage reporting
- [ ] Add linting rules
- [ ] Create pre-commit hooks

### Documentation
- [ ] API documentation
- [ ] Component documentation
- [ ] Architecture diagrams
- [ ] Deployment guide
- [ ] Contributing guidelines

## Backend Integration Points

### REST Endpoints Needed
- [x] GET /api/games - List available games
- [x] POST /api/games/:id/join - Join a game
- [ ] GET /api/player/profile - Get player info
- [ ] GET /api/player/collection - Get card collection
- [ ] GET /api/player/decks - Get player decks
- [ ] POST /api/player/decks - Create/update deck
- [ ] GET /api/leaderboard - Get rankings

### WebSocket Events
- [ ] game.start - Game begins
- [ ] game.state - Full state sync
- [ ] player.action - Player performs action
- [ ] turn.start - Turn begins
- [ ] turn.end - Turn ends
- [ ] game.end - Game concludes
- [ ] player.disconnect - Handle disconnection
- [ ] player.reconnect - Handle reconnection

## Platform-Specific Tasks

### Mobile (iOS/Android)
- [ ] Configure app icons
- [ ] Set up splash screens
- [ ] Handle device orientation
- [ ] Implement haptic feedback
- [ ] Add push notifications
- [ ] Configure deep linking

### Desktop (Windows/macOS/Linux)
- [ ] Configure window sizing
- [ ] Add menu bar integration
- [ ] Implement keyboard shortcuts
- [ ] Handle multi-window support

### Web
- [ ] Optimize bundle size
- [ ] Configure PWA manifest
- [ ] Add service worker
- [ ] Implement social sharing
- [ ] Handle browser compatibility

## Performance Targets

- Frame rate: 60 FPS on all platforms
- Load time: < 3 seconds
- Memory usage: < 200MB active
- Network latency handling: up to 200ms
- Offline capability: Basic deck building

## Security Considerations

- [ ] Implement certificate pinning
- [ ] Add request signing
- [ ] Encrypt local storage
- [ ] Validate all server responses
- [ ] Implement rate limiting
- [ ] Add anti-cheat measures

## Future Enhancements

1. **Social Features**
   - Guild/clan system
   - Tournament mode
   - Replay system
   - Streaming integration

2. **Monetization**
   - In-app purchases
   - Season pass
   - Cosmetic items
   - Premium currency

3. **Advanced Features**
   - Draft mode
   - Custom game modes
   - Mod support
   - Level editor

## Timeline Estimates

- Phase 1: 1 week (Foundation) ✅
- Phase 2: 3 weeks (Core Game)
- Phase 3: 2 weeks (Multiplayer)
- Phase 4: 2 weeks (UI)
- Phase 5: 3 weeks (Features)
- Phase 6: 2 weeks (Polish)

**Total estimate**: 13 weeks for MVP

## Risk Mitigation

1. **Technical Risks**
   - WebSocket stability
   - Cross-platform compatibility
   - Performance on low-end devices

2. **Mitigation Strategies**
   - Implement fallback mechanisms
   - Progressive enhancement
   - Extensive device testing

## Success Metrics

- User retention: > 30% after 7 days
- Match completion rate: > 80%
- Average session length: > 15 minutes
- Crash rate: < 1%
- User rating: > 4.0 stars 