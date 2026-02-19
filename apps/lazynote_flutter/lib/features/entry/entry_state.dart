import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/features/entry/command_router.dart';

/// Stable state phases for the single-entry UI flow.
enum EntryPhase { idle, loading, success, error }

/// Message type used by UI for status color/priority mapping.
enum EntryStatusMessageType { info, success, error }

/// User-visible status payload emitted by the state model.
@immutable
class EntryStatusMessage {
  /// Creates one status message payload.
  const EntryStatusMessage({required this.type, required this.text});

  /// Message severity used by UI color mapping.
  final EntryStatusMessageType type;

  /// Human-readable status message shown in Single Entry panel.
  final String text;
}

/// Immutable view state for single-entry routing.
///
/// This state does not execute side effects. It only models transitions
/// for parser/router outcomes and command/search execution lifecycle.
@immutable
class EntryState {
  /// Creates one immutable entry state snapshot.
  const EntryState({
    required this.phase,
    required this.rawInput,
    this.intent,
    this.statusMessage,
    this.detailPayload,
  });

  /// Creates the pristine idle entry state.
  const EntryState.idle()
    : phase = EntryPhase.idle,
      rawInput = '',
      intent = null,
      statusMessage = null,
      detailPayload = null;

  /// Current phase in the parser/search/command flow.
  final EntryPhase phase;

  /// Raw input text snapshot associated with this state.
  final String rawInput;

  /// Routed intent for this state; `null` only in pristine idle state.
  final EntryIntent? intent;

  /// Optional status line payload shown under the input.
  final EntryStatusMessage? statusMessage;

  /// Optional detail payload shown when detail view is open.
  final String? detailPayload;

  /// Convenience flag for error-phase rendering branches.
  bool get hasError => phase == EntryPhase.error;

  /// Transition used while search/command execution is in-flight.
  EntryState toLoading({
    required String rawInput,
    required EntryIntent intent,
    String message = 'Processing...',
  }) {
    return EntryState(
      phase: EntryPhase.loading,
      rawInput: rawInput,
      intent: intent,
      statusMessage: EntryStatusMessage(
        type: EntryStatusMessageType.info,
        text: message,
      ),
      detailPayload: detailPayload,
    );
  }

  /// Transition used when parser/execution succeeds.
  EntryState toSuccess({
    required String rawInput,
    required EntryIntent intent,
    required String message,
    String? detailPayload,
  }) {
    return EntryState(
      phase: EntryPhase.success,
      rawInput: rawInput,
      intent: intent,
      statusMessage: EntryStatusMessage(
        type: EntryStatusMessageType.success,
        text: message,
      ),
      detailPayload: detailPayload ?? this.detailPayload,
    );
  }

  /// Transition used on parser or execution failure.
  ///
  /// The caller must provide unchanged `rawInput` to keep input preserved.
  EntryState toError({
    required String rawInput,
    required EntryIntent intent,
    required String message,
    String? detailPayload,
  }) {
    return EntryState(
      phase: EntryPhase.error,
      rawInput: rawInput,
      intent: intent,
      statusMessage: EntryStatusMessage(
        type: EntryStatusMessageType.error,
        text: message,
      ),
      detailPayload: detailPayload ?? this.detailPayload,
    );
  }

  /// Clears status while preserving last input and detail payload.
  EntryState clearStatus() {
    return EntryState(
      phase: EntryPhase.idle,
      rawInput: rawInput,
      intent: intent,
      statusMessage: null,
      detailPayload: detailPayload,
    );
  }
}
