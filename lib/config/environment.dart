/// Environment configuration for the Kitbash Flutter app
/// Allows switching between local and remote backend servers
library;

class Environment {
  static const String _defaultRemoteUrl = 'http://192.168.4.156:8080';
  static const String _defaultLocalUrl = 'http://localhost:8080';

  /// Get the backend URL based on environment configuration
  /// Can be overridden with --dart-define=BACKEND_URL=<url>
  static String get backendUrl {
    // Check for runtime override first
    const overrideUrl = String.fromEnvironment('BACKEND_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }

    // Check for environment mode
    const useLocal =
        bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);
    if (useLocal) {
      return _defaultLocalUrl;
    }

    // Default to remote server
    return _defaultRemoteUrl;
  }

  /// Get WebSocket URL based on backend URL
  static String get wsUrl {
    final httpUrl = backendUrl;
    return httpUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }

  /// Get API URL
  static String get apiUrl => '$backendUrl/api';

  /// Check if we're using local backend
  static bool get isLocalBackend {
    return backendUrl.contains('localhost') || backendUrl.contains('127.0.0.1');
  }
}
