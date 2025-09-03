import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';

/// Provides a robust way to retrieve the app version string across platforms.
///
/// Precedence:
/// 1) Compile-time define APP_VERSION (e.g. --dart-define=APP_VERSION=1.2.3+45)
/// 2) package_info_plus from the platform (version + buildNumber)
/// 3) Fallback: parse version from bundled pubspec.yaml asset
/// 4) Final fallback: "unknown"
///
/// Optionally appends short git SHA if provided via --dart-define=GIT_SHA.
class VersionService {
  static const String _definedVersion = String.fromEnvironment('APP_VERSION');
  static const String _definedGitSha = String.fromEnvironment('GIT_SHA');

  static String? _cachedVersion;

  static Future<String> getVersionLabel() async {
    if (_cachedVersion != null) {
      return _cachedVersion!;
    }

    // 1) Compile-time provided version
    if (_definedVersion.trim().isNotEmpty) {
      _cachedVersion = _withOptionalSha(_definedVersion.trim());
      return _cachedVersion!;
    }

    // 2) Platform package info
    final String? fromPackage = await _getVersionUsingPackageInfo();
    if (fromPackage != null && fromPackage.trim().isNotEmpty) {
      _cachedVersion = _withOptionalSha(fromPackage.trim());
      return _cachedVersion!;
    }

    // 3) Fallback to parsing pubspec asset
    final String? fromPubspec = await _getVersionFromPubspecAsset();
    if (fromPubspec != null && fromPubspec.trim().isNotEmpty) {
      _cachedVersion = _withOptionalSha(fromPubspec.trim());
      return _cachedVersion!;
    }

    // 4) Final fallback
    _cachedVersion = _withOptionalSha('unknown');
    return _cachedVersion!;
  }

  static String _withOptionalSha(String base) {
    final sha = _definedGitSha.trim();
    if (sha.isEmpty) return base;
    final shortSha = sha.length > 8 ? sha.substring(0, 8) : sha;
    return '$base ($shortSha)';
  }

  static Future<String?> _getVersionUsingPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version;
      final build = info.buildNumber;
      if (version.isEmpty && build.isEmpty) {
        return null;
      }
      if (version.isNotEmpty && build.isNotEmpty) {
        return '$version+$build';
      }
      return version.isNotEmpty ? version : build;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _getVersionFromPubspecAsset() async {
    try {
      final String manifestString = await rootBundle.loadString('pubspec.yaml');
      final RegExp versionRegex = RegExp(r'^version:\s*(.+)$', multiLine: true);
      final Match? match = versionRegex.firstMatch(manifestString);
      if (match != null) {
        return match.group(1)!.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
