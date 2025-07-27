# Flutter & Flame Development Best Practices

## Code Style Guidelines

### Widget Structure
- Prefer `const` constructors whenever possible for better performance
- Extract complex widgets into separate files
- Keep build methods concise (< 50 lines)
- Use meaningful widget names that describe their purpose

### State Management
- Use Provider for app-wide state management
- Keep state classes focused and single-purpose
- Always call `notifyListeners()` after state changes
- Dispose of resources properly in `dispose()` methods

### Async Operations
- Always handle errors in async operations
- Use `try-catch` blocks for network requests
- Show loading indicators during async operations
- Implement proper error states in UI

## Flutter-Specific Rules

### Performance
- Use `ListView.builder` for long lists instead of `ListView`
- Implement `const` constructors for stateless widgets
- Avoid rebuilding widgets unnecessarily
- Cache network images using `cached_network_image`

### Navigation
- Use named routes for better maintainability
- Pass data through constructor parameters, not through routes
- Handle back button behavior properly
- Implement proper deep linking support

### Testing
- Write widget tests for all screens
- Test state management logic separately
- Mock external dependencies
- Aim for >80% code coverage

## Flame Game Engine

### Game Architecture
- Separate game logic from rendering logic
- Use component-based architecture
- Implement object pooling for frequently created/destroyed objects
- Handle game lifecycle properly (pause, resume, dispose)

### Performance Optimization
- Use sprite batching when possible
- Implement viewport culling
- Optimize collision detection with spatial partitioning
- Profile regularly with Flutter DevTools

### Input Handling
- Implement both tap and drag gestures for mobile
- Add keyboard support for desktop platforms
- Provide visual feedback for all interactions
- Handle multi-touch properly

## Network & WebSocket

### Connection Management
- Implement automatic reconnection logic
- Handle connection state changes gracefully
- Queue messages when disconnected
- Implement exponential backoff for retries

### Error Handling
- Catch and handle all network errors
- Provide user-friendly error messages
- Implement offline mode capabilities
- Log errors for debugging

### Security
- Validate all data from server
- Use HTTPS for all REST calls
- Implement proper authentication
- Never store sensitive data in plain text

## Project Structure

### File Organization
```
lib/
├── game/          # Flame-specific code
├── models/        # Data models
├── screens/       # Full screen widgets
├── services/      # Business logic
├── utils/         # Helper functions
└── widgets/       # Reusable components
```

### Naming Conventions
- Files: `lowercase_with_underscores.dart`
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private members: `_prefixWithUnderscore`

## Platform-Specific Considerations

### Mobile (iOS/Android)
- Handle different screen sizes and orientations
- Implement platform-specific UI when needed
- Test on both iOS and Android devices
- Handle platform permissions properly

### Desktop (Windows/macOS/Linux)
- Implement keyboard shortcuts
- Handle window resizing
- Support right-click context menus
- Test on all target platforms

### Web
- Optimize bundle size
- Handle browser-specific limitations
- Implement proper routing
- Test across different browsers

## Common Pitfalls to Avoid

1. **Not disposing controllers/streams**
   - Always dispose in `dispose()` method
   - Use `AutomaticKeepAliveClientMixin` carefully

2. **Rebuilding entire widget tree**
   - Use `const` widgets
   - Implement `shouldRebuild` in custom painters
   - Use `ValueListenableBuilder` for specific updates

3. **Blocking the UI thread**
   - Use `compute()` for heavy computations
   - Implement isolates for background work
   - Show loading indicators

4. **Memory leaks**
   - Remove event listeners
   - Cancel timers and animations
   - Clear references to large objects

## Code Review Checklist

- [ ] All widgets that can be const are const
- [ ] Proper error handling for async operations
- [ ] Resources are disposed properly
- [ ] No hardcoded strings (use constants)
- [ ] Responsive design implemented
- [ ] Platform-specific code handled gracefully
- [ ] Tests written for new features
- [ ] Documentation updated
- [ ] Performance impact considered
- [ ] Accessibility features implemented 