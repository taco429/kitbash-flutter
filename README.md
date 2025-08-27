# Kitbash CCG - Flutter Client

A cross-platform collectible card game client built with Flutter and the Flame game engine. This client connects to a Go backend server for online multiplayer gameplay.

## Features

- 🎮 Cross-platform support (Mobile, Desktop, Web)
- 🔥 Built with Flame game engine for smooth gameplay
- 🌐 REST API integration for matchmaking and game management
- 🔌 WebSocket support for real-time multiplayer gameplay
- 📱 Responsive design for various screen sizes

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- A running instance of the Kitbash Go backend server

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd kitbash-flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For development (with hot reload)
   flutter run
   
   # For specific platform
   flutter run -d chrome  # Web
   flutter run -d macos   # macOS
   flutter run -d windows # Windows
   flutter run -d linux   # Linux
   ```

## Project Structure

```
kitbash-flutter/
├── lib/
│   ├── main.dart           # Application entry point
│   ├── game/               # Flame game components
│   │   └── kitbash_game.dart
│   ├── screens/            # UI screens
│   │   ├── menu_screen.dart
│   │   └── game_screen.dart
│   ├── services/           # Backend communication
│   │   └── game_service.dart
│   ├── models/             # Data models
│   └── widgets/            # Reusable UI components
├── assets/                 # Game assets
│   ├── images/
│   └── audio/
├── test/                   # Unit and widget tests
├── docs/                   # Documentation
└── .github/                # GitHub Actions workflows
```

## Backend Configuration

The client is configured to connect to a local backend server by default:
- REST API: `http://localhost:8080`
- WebSocket: `ws://localhost:8080/ws`

To change the backend URL, modify the `baseUrl` in `lib/services/game_service.dart`.

### Run with Docker Compose (optional)

If you have Docker installed:

```bash
docker compose build
docker compose up
```

Services:
- Backend API: `http://localhost:8080`
- Frontend (web, via nginx): `http://localhost:8081`

More details in `docs/backend.md`.

## Development

### Running Tests
```bash
flutter test
```

### Building for Production

```bash
# Android
flutter build apk
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web

# Desktop
flutter build macos
flutter build windows
flutter build linux
```

## Architecture

The application follows a clean architecture pattern:

- **Presentation Layer**: Flutter widgets and screens
- **Game Layer**: Flame game engine components
- **Service Layer**: REST and WebSocket communication
- **State Management**: Provider for app-wide state

## Contributing

Please read our [Development Guide](docs/development.md) for details on our code style, commit conventions, and development workflow.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 