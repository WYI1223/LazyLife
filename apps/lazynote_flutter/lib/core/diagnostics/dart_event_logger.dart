import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:lazynote_flutter/core/bindings/api.dart' as bindings;

typedef DartEventLogInvoker =
    bindings.LogDartEventResponse Function({
      required String level,
      required String eventName,
      required String module,
      required String message,
    });

typedef DartEventFallbackLogger =
    void Function({
      required String message,
      Object? error,
      StackTrace? stackTrace,
    });

/// Centralized no-throw wrapper for `log_dart_event` FFI writes.
///
/// Contract:
/// - Never throws to caller paths.
/// - Optional dedupe window to suppress bursty duplicate events.
/// - Safe for lifecycle and diagnostics call sites.
class DartEventLogger {
  static DartEventLogInvoker invoker =
      ({
        required String level,
        required String eventName,
        required String module,
        required String message,
      }) => bindings.logDartEvent(
        level: level,
        eventName: eventName,
        module: module,
        message: message,
      );

  static DartEventFallbackLogger fallbackLogger =
      ({required String message, Object? error, StackTrace? stackTrace}) {
        dev.log(
          message,
          name: 'DartEventLogger',
          error: error,
          stackTrace: stackTrace,
        );
      };

  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @visibleForTesting
  static Duration defaultDedupeWindow = const Duration(seconds: 2);

  static final Map<String, DateTime> _lastLoggedAtByKey = <String, DateTime>{};
  static const int _maxDedupeKeys = 256;

  @visibleForTesting
  static void resetForTesting() {
    invoker =
        ({
          required String level,
          required String eventName,
          required String module,
          required String message,
        }) => bindings.logDartEvent(
          level: level,
          eventName: eventName,
          module: module,
          message: message,
        );
    fallbackLogger =
        ({required String message, Object? error, StackTrace? stackTrace}) {
          dev.log(
            message,
            name: 'DartEventLogger',
            error: error,
            stackTrace: stackTrace,
          );
        };
    now = DateTime.now;
    defaultDedupeWindow = const Duration(seconds: 2);
    _lastLoggedAtByKey.clear();
  }

  /// Attempts to log one event through FFI.
  ///
  /// Returns `true` when the event was accepted by Rust logging, `false`
  /// otherwise (including dedupe suppression and FFI failures).
  static bool tryLog({
    required String level,
    required String eventName,
    required String module,
    required String message,
    bool dedupe = true,
    Duration? dedupeWindow,
  }) {
    final normalizedLevel = level.trim().toLowerCase();
    final normalizedEventName = eventName.trim();
    final normalizedModule = module.trim();
    final normalizedMessage = message.trim();

    if (normalizedEventName.isEmpty ||
        normalizedModule.isEmpty ||
        normalizedMessage.isEmpty) {
      fallbackLogger(
        message: 'Skipped log_dart_event due to empty normalized payload.',
      );
      return false;
    }

    final timestamp = now();
    final effectiveWindow = dedupeWindow ?? defaultDedupeWindow;
    final dedupeKey =
        '$normalizedLevel|$normalizedEventName|$normalizedModule|$normalizedMessage';

    if (dedupe && effectiveWindow > Duration.zero) {
      final lastLoggedAt = _lastLoggedAtByKey[dedupeKey];
      if (lastLoggedAt != null &&
          timestamp.difference(lastLoggedAt) < effectiveWindow) {
        return false;
      }
    }

    try {
      final response = invoker(
        level: normalizedLevel,
        eventName: normalizedEventName,
        module: normalizedModule,
        message: normalizedMessage,
      );
      if (!response.ok) {
        fallbackLogger(
          message:
              'log_dart_event rejected by FFI ($normalizedEventName / ${response.errorCode ?? "unknown"}).',
        );
        return false;
      }

      if (dedupe && effectiveWindow > Duration.zero) {
        _lastLoggedAtByKey[dedupeKey] = timestamp;
        _pruneDedupeState(timestamp: timestamp, dedupeWindow: effectiveWindow);
      }
      return true;
    } catch (error, stackTrace) {
      fallbackLogger(
        message: 'log_dart_event invocation failed ($normalizedEventName).',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static void _pruneDedupeState({
    required DateTime timestamp,
    required Duration dedupeWindow,
  }) {
    if (_lastLoggedAtByKey.length <= _maxDedupeKeys) {
      return;
    }
    final cutoff = timestamp.subtract(dedupeWindow * 4);
    _lastLoggedAtByKey.removeWhere((_, lastLoggedAt) {
      return lastLoggedAt.isBefore(cutoff);
    });
  }
}
