import 'package:flutter/foundation.dart';
import '../models/card_drag_payload.dart';
import 'game_service.dart';

/// Granular state management for specific game aspects
/// Allows widgets to listen to only the state they need

/// Manages card discard selection state
class DiscardSelectionNotifier extends ValueNotifier<Set<String>> {
  DiscardSelectionNotifier() : super({});

  bool isCardMarkedForDiscard(String instanceId) {
    return value.contains(instanceId);
  }

  void toggleCardDiscard(String instanceId) {
    final newSet = Set<String>.from(value);
    if (newSet.contains(instanceId)) {
      newSet.remove(instanceId);
      debugPrint('Unmarked card for discard: $instanceId');
    } else {
      newSet.add(instanceId);
      debugPrint('Marked card for discard: $instanceId');
    }
    debugPrint('Total cards marked for discard: ${newSet.length}');
    value = newSet; // This only notifies discard listeners
  }

  void clearDiscardSelection() {
    if (value.isNotEmpty) {
      value = {}; // Only notifies if actually changed
    }
  }
}

/// Manages card preview state
class CardPreviewNotifier extends ValueNotifier<CardDragPayload?> {
  CardPreviewNotifier() : super(null);

  void showCardPreview(CardDragPayload payload) {
    value = payload;
  }

  void clearCardPreview() {
    value = null;
  }
}

/// Manages card placement state
class CardPlacementNotifier extends ValueNotifier<CardDragPayload?> {
  CardPlacementNotifier() : super(null);

  void beginCardPlacement(CardDragPayload payload) {
    value = payload;
  }

  void clearCardPlacement() {
    value = null;
  }
}

/// Manages player lock states
class LockStateNotifier extends ValueNotifier<Map<int, bool>> {
  LockStateNotifier() : super({0: false, 1: false});

  void setPlayerLocked(int playerIndex, bool locked) {
    if (value[playerIndex] != locked) {
      final newMap = Map<int, bool>.from(value);
      newMap[playerIndex] = locked;
      value = newMap;
    }
  }

  bool isPlayerLocked(int playerIndex) {
    return value[playerIndex] ?? false;
  }

  bool get allPlayersLocked {
    return value.values.every((locked) => locked);
  }
}

/// Manages connection state
class ConnectionStateNotifier extends ValueNotifier<bool> {
  ConnectionStateNotifier() : super(false);

  void setConnected(bool connected) {
    if (value != connected) {
      value = connected;
    }
  }
}

/// Manages core game state updates
class GameStateNotifier extends ChangeNotifier {
  GameState? _gameState;
  String? _lastError;

  GameState? get gameState => _gameState;
  String? get lastError => _lastError;

  void updateGameState(GameState? newState) {
    debugPrint(
        'GameStateNotifier: Updating state - ${newState != null ? "has state" : "null state"}');
    // Always update and notify when we get a new state object
    // Even if the values are the same, it's a new state from the server
    _gameState = newState;
    debugPrint('GameStateNotifier: State updated, notifying listeners');
    notifyListeners();
  }

  void setError(String? error) {
    if (_lastError != error) {
      _lastError = error;
      notifyListeners();
    }
  }
}

/// Manages discard log separately
class DiscardLogNotifier extends ChangeNotifier {
  final List<RoundDiscardSummary> _discardLog = [];

  List<RoundDiscardSummary> get discardLog => List.unmodifiable(_discardLog);

  RoundDiscardSummary ensureRoundSummary(int round) {
    final idx = _discardLog.indexWhere((e) => e.roundNumber == round);
    if (idx >= 0) return _discardLog[idx];

    final summary = RoundDiscardSummary(roundNumber: round);
    _discardLog.add(summary);

    // Keep only recent 50 rounds to bound memory
    if (_discardLog.length > 50) {
      _discardLog.removeRange(0, _discardLog.length - 50);
    }

    notifyListeners();
    return summary;
  }

  void recordDiscardEvent({
    required int round,
    required int playerIndex,
    required int count,
  }) {
    final summary = ensureRoundSummary(round);
    summary.playerToDiscardCount[playerIndex] =
        (summary.playerToDiscardCount[playerIndex] ?? 0) + count;
    notifyListeners();
  }
}

/// Represents a backend target validation response
class TargetValidationResult {
  final int row;
  final int col;
  final String cardInstanceId;
  final bool valid;
  final String? reason;

  const TargetValidationResult({
    required this.row,
    required this.col,
    required this.cardInstanceId,
    required this.valid,
    this.reason,
  });
}

/// Notifier for latest target validation result
class TargetValidationNotifier extends ValueNotifier<TargetValidationResult?> {
  TargetValidationNotifier() : super(null);

  void setResult(TargetValidationResult? result) {
    value = result;
  }

  void clear() {
    if (value != null) value = null;
  }
}

/// Play event log entry
class PlayEventEntry {
  final int round;
  final int playerIndex;
  final String cardId;
  final String cardInstanceId;
  final int row;
  final int col;

  const PlayEventEntry({
    required this.round,
    required this.playerIndex,
    required this.cardId,
    required this.cardInstanceId,
    required this.row,
    required this.col,
  });
}

/// Notifier to accumulate play events per round
class PlayLogNotifier extends ChangeNotifier {
  final List<PlayEventEntry> _entries = [];

  List<PlayEventEntry> get entries => List.unmodifiable(_entries);

  void add(PlayEventEntry e) {
    _entries.add(e);
    // Bound log size
    if (_entries.length > 100) {
      _entries.removeRange(0, _entries.length - 100);
    }
    notifyListeners();
  }

  void clear() {
    if (_entries.isNotEmpty) {
      _entries.clear();
      notifyListeners();
    }
  }
}
