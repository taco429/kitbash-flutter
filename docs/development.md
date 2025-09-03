rr# Development Guide

This guide covers the development workflow, coding standards, and best practices for the Kitbash CCG Flutter client.

## Development Environment Setup

### Prerequisites

1. **Flutter SDK**
   - Install Flutter from [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Ensure Flutter is in your PATH
   - Run `flutter doctor` to verify installation

2. **IDE Setup**
   - **VS Code**: Install Flutter and Dart extensions
   - **Android Studio/IntelliJ**: Install Flutter and Dart plugins
   - **Cursor**: Follow Flutter best practices (see `.cursor/rules/`)

3. **Backend Server**
   - Ensure the Go backend is running on `localhost:8080`
   - Check WebSocket connectivity at `ws://localhost:8080/ws`

## Code Style and Standards

### Dart/Flutter Conventions

1. **File Naming**
   - Use lowercase with underscores: `game_service.dart`
   - One class per file, matching the filename

2. **Code Formatting**
   - Run `dart format .` before committing
   - Use the provided analysis options in `analysis_options.yaml`

3. **Widget Guidelines**
   - Prefer `const` constructors where possible
   - Extract large build methods into smaller widgets
   - Use meaningful widget keys for testing

### Project Structure

```
lib/
├── game/          # Flame game components
├── models/        # Data models and entities
├── screens/       # Full-screen widgets
├── services/      # Business logic and API calls
├── utils/         # Helper functions and constants
└── widgets/       # Reusable UI components
```

## Git Workflow

### Branch Naming
- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `hotfix/description` - Critical fixes
- `docs/description` - Documentation updates

### Commit Messages
Follow conventional commits:
```
type(scope): subject

body (optional)

footer (optional)
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Process
1. Create feature branch from `main`
2. Make changes following code standards
3. Add/update tests as needed
4. Update documentation if required
5. Create PR with clear description
6. Ensure CI checks pass
7. Request code review

## Testing

### Unit Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/game_service_test.dart
```

### Integration Tests
```bash
# Run integration tests
flutter test integration_test/
```

### Widget Tests
- Test UI components in isolation
- Mock services and dependencies
- Verify widget behavior and rendering

## Debugging

### Flutter Inspector
- Use Flutter Inspector in your IDE
- Inspect widget tree and properties
- Debug layout issues

### Logging
```dart
import 'package:flutter/foundation.dart';

// Use debugPrint for development logging
debugPrint('Debug message');

// Conditional logging
if (kDebugMode) {
  print('Development only message');
}
```

### Network Debugging
- Use Flutter DevTools for network inspection
- Monitor WebSocket connections
- Check REST API calls and responses

## Performance Optimization

### Best Practices
1. Use `const` widgets where possible
2. Implement `ListView.builder` for long lists
3. Cache network images
4. Minimize widget rebuilds
5. Profile using Flutter DevTools

### Flame Optimization
1. Use object pooling for game entities
2. Implement viewport culling
3. Optimize sprite batching
4. Profile frame rendering

## Dependency Management

### Adding Dependencies
1. Add to `pubspec.yaml`
2. Run `flutter pub get`
3. Document why the dependency is needed

### Updating Dependencies
```bash
# Check outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade
```

## Build and Release

### Debug Builds
```bash
flutter run --debug
```

### Release Builds
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Platform-Specific Considerations

#### Android
- Update `android/app/build.gradle` for version
- Configure signing for release builds
- Test on multiple Android versions

#### iOS
- Update version in Xcode project
- Configure provisioning profiles
- Test on physical devices

#### Web
- Optimize for web performance
- Test across browsers
- Configure CORS for API calls

## Troubleshooting

### Common Issues

1. **Hot Reload Not Working**
   - Restart the app
   - Check for compilation errors
   - Clean and rebuild

2. **WebSocket Connection Failed**
   - Verify backend is running
   - Check network permissions
   - Review CORS configuration

3. **Build Failures**
   - Run `flutter clean`
   - Delete `.dart_tool/` directory
   - Update dependencies

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Flame Documentation](https://docs.flame-engine.org/)
- [Dart Language Guide](https://dart.dev/guides)
- [Material Design Guidelines](https://material.io/design) 