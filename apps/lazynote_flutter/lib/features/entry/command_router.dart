import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/features/entry/command_parser.dart';

/// Default search limit applied by single-entry routing in v0.1.
const int defaultSearchLimit = 10;

/// Maximum search limit accepted by single-entry routing in v0.1.
const int maxSearchLimit = 10;

/// Routes raw single-entry text to search or command intents.
@immutable
class CommandRouter {
  /// Creates a router with an injectable command parser.
  const CommandRouter({this.parser = const CommandParser()});

  /// Parser used when input is detected as command mode (`>` prefix).
  final CommandParser parser;

  /// Returns intent by applying single-entry route rules.
  ///
  /// Rules:
  /// - empty -> [NoopIntent]
  /// - starts with `>` -> parser-driven command intent
  /// - otherwise -> [SearchIntent]
  EntryIntent route(
    String rawInput, {
    int requestedSearchLimit = defaultSearchLimit,
  }) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return const NoopIntent();
    }
    if (!trimmed.startsWith('>')) {
      return SearchIntent(
        text: trimmed,
        limit: _normalizeSearchLimit(requestedSearchLimit),
      );
    }

    final parsed = parser.parse(trimmed);
    return switch (parsed) {
      CommandParseSuccess(:final command) => CommandIntent(command: command),
      CommandParseFailure(:final code, :final message) => ParseErrorIntent(
        code: code,
        message: message,
      ),
    };
  }

  int _normalizeSearchLimit(int requestedLimit) {
    if (requestedLimit <= 0) {
      return defaultSearchLimit;
    }
    if (requestedLimit > maxSearchLimit) {
      return maxSearchLimit;
    }
    return requestedLimit;
  }
}

/// Base type for single-entry route intents.
@immutable
sealed class EntryIntent {
  /// Base constructor for routed intents.
  const EntryIntent();
}

/// No-op intent when input is empty.
@immutable
final class NoopIntent extends EntryIntent {
  /// Creates no-op intent.
  const NoopIntent();
}

/// Search intent for non-command text.
@immutable
final class SearchIntent extends EntryIntent {
  /// Creates search intent payload.
  const SearchIntent({required this.text, required this.limit});

  /// Query text used for FTS search.
  final String text;

  /// Applied search limit after normalization/clamping.
  final int limit;
}

/// Command intent produced by successful command parsing.
@immutable
final class CommandIntent extends EntryIntent {
  /// Creates command intent payload.
  const CommandIntent({required this.command});

  /// Parsed command payload for execution stage.
  final EntryCommand command;
}

/// Parse error intent produced by command parse failure.
@immutable
final class ParseErrorIntent extends EntryIntent {
  /// Creates parse-error intent payload.
  const ParseErrorIntent({required this.code, required this.message});

  /// Stable parser error code for machine-branching.
  final String code;

  /// Human-readable parser error text for UI feedback.
  final String message;
}
