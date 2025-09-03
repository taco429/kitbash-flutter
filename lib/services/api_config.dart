import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API configuration for HTTP and WebSocket base URLs.
///
/// Priority order for base URL selection:
/// 1) Compile-time defines via --dart-define (API_BASE_URL, WS_BASE_URL)
/// 2) If running on Web inside Docker/nginx (port 80/8081): use same-origin with /api and /ws
/// 3) Local development defaults:
///    - Web dev server: http://localhost:8080 for REST and ws://localhost:8080 for WS
///    - Native (Android/iOS): http://10.0.2.2:8080 for Android emulator; http://localhost:8080 otherwise
class ApiConfig {
  ApiConfig._internal()
      : httpBase = _computeHttpBase(),
        apiBase = _computeApiBase(),
        wsBase = _computeWsBase();

  static final ApiConfig instance = ApiConfig._internal();

  /// Base URL without trailing path, e.g. http://host:8080
  final String httpBase;

  /// Base URL for REST under /api, e.g. http://host:8080/api or same-origin /api
  final String apiBase;

  /// Base URL for WebSockets, e.g. ws://host:8080
  final String wsBase;

  static const String _envHttpBase =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _envWsBase =
      String.fromEnvironment('WS_BASE_URL', defaultValue: '');

  static String _computeHttpBase() {
    if (_envHttpBase.isNotEmpty) return _stripTrailingSlash(_envHttpBase);

    if (kIsWeb) {
      final uri = Uri.base;
      final isLikelyDockerFrontend =
          uri.port == 80 || uri.port == 8081 || uri.host != 'localhost';
      if (isLikelyDockerFrontend) {
        // Use same origin; nginx should proxy /api and /ws
        return '${uri.scheme}://${uri.host}${uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      }
      // Flutter web dev server: talk directly to backend on 8080
      return 'http://localhost:8080';
    }

    // Native defaults (adjust for Android emulator)
    // Without Platform checks (dart:io) to support web compilation, default to localhost
    return 'http://10.0.2.2:8080';
  }

  static String _computeApiBase() {
    final base = _computeHttpBase();
    // If already ends with /api, keep; otherwise append
    return base.endsWith('/api') ? base : '$base/api';
  }

  static String _computeWsBase() {
    if (_envWsBase.isNotEmpty) return _stripTrailingSlash(_envWsBase);

    final http = _computeHttpBase();
    final isHttps = http.startsWith('https://');
    final wsScheme = isHttps ? 'wss://' : 'ws://';
    final withoutScheme = http.replaceFirst(RegExp(r'^https?://'), '');
    return '$wsScheme$withoutScheme';
  }

  static String _stripTrailingSlash(String value) {
    if (value.endsWith('/')) return value.substring(0, value.length - 1);
    return value;
  }
}
