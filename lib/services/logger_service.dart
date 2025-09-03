import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralized logger initialization and named loggers.
class AppLogger {
  AppLogger._();

  /// Initialize root logger and attach a simple console handler.
  static void init({Level level = Level.INFO}) {
    // Configure root level
    Logger.root.level = level;

    // Pretty print to console with timestamp and level
    Logger.root.onRecord.listen((LogRecord record) {
      final String message =
          '[${record.time.toIso8601String()}] ${record.level.name.padRight(7)} '
                  '${record.loggerName}: ${record.message}' +
              (record.error != null ? ' | error=${record.error}' : '') +
              (record.stackTrace != null ? '\n${record.stackTrace}' : '');
      // Use debugPrint to avoid truncation in Flutter
      debugPrint(message);
    });
  }

  /// Convenience accessors for common logger names.
  static Logger get game => Logger('Game');
  static Logger get ui => Logger('UI');
  static Logger named(String name) => Logger(name);
}
