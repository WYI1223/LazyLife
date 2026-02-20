import 'package:flutter/foundation.dart';

/// Save lifecycle for one workspace note buffer.
enum WorkspaceSaveState { clean, dirty, saving, saveError }

/// Root split orientation for v0.2 non-recursive layout.
enum WorkspaceSplitDirection { horizontal, vertical }

/// Stable result codes for split command handling.
enum WorkspaceSplitResult {
  ok,
  paneNotFound,
  maxPanesReached,
  directionLocked,
  minSizeBlocked,
}

/// Stable result codes for close-pane merge command handling.
enum WorkspaceMergeResult { ok, singlePaneBlocked, paneNotFound }

/// Minimal layout state shape kept split-ready for v0.2/v0.3.
@immutable
class WorkspaceLayoutState {
  /// Creates one immutable workspace layout snapshot.
  WorkspaceLayoutState({
    required List<String> paneOrder,
    required List<double> paneFractions,
    required this.splitDirection,
    required this.primaryPaneId,
  }) : paneOrder = List.unmodifiable(List<String>.from(paneOrder)),
       paneFractions = List.unmodifiable(List<double>.from(paneFractions));

  /// Ordered pane ids from left to right.
  final List<String> paneOrder;

  /// Relative pane size fractions aligned with [paneOrder].
  final List<double> paneFractions;

  /// Root split orientation for current pane set.
  final WorkspaceSplitDirection splitDirection;

  /// Default pane for single-pane baseline.
  final String primaryPaneId;

  /// Returns the baseline single-pane layout used by current UI.
  factory WorkspaceLayoutState.singlePane() {
    return WorkspaceLayoutState(
      paneOrder: <String>['pane.primary'],
      paneFractions: <double>[1.0],
      splitDirection: WorkspaceSplitDirection.horizontal,
      primaryPaneId: 'pane.primary',
    );
  }

  /// Returns one copied layout snapshot with selective field updates.
  WorkspaceLayoutState copyWith({
    List<String>? paneOrder,
    List<double>? paneFractions,
    WorkspaceSplitDirection? splitDirection,
    String? primaryPaneId,
  }) {
    return WorkspaceLayoutState(
      paneOrder: paneOrder ?? this.paneOrder,
      paneFractions: paneFractions ?? this.paneFractions,
      splitDirection: splitDirection ?? this.splitDirection,
      primaryPaneId: primaryPaneId ?? this.primaryPaneId,
    );
  }
}

/// In-memory draft/persisted snapshot for one note id.
@immutable
class WorkspaceNoteBuffer {
  /// Creates one immutable note buffer snapshot.
  const WorkspaceNoteBuffer({
    required this.noteId,
    required this.persistedContent,
    required this.draftContent,
    required this.version,
  });

  /// Stable note identifier associated with this buffer.
  final String noteId;

  /// Last persisted content acknowledged by save pipeline.
  final String persistedContent;

  /// Latest editor draft content.
  final String draftContent;

  /// Monotonic local version used to detect stale save responses.
  final int version;

  /// Whether current draft differs from persisted content.
  bool get isDirty => draftContent != persistedContent;

  /// Returns a new buffer snapshot with selective field updates.
  WorkspaceNoteBuffer copyWith({
    String? persistedContent,
    String? draftContent,
    int? version,
  }) {
    return WorkspaceNoteBuffer(
      noteId: noteId,
      persistedContent: persistedContent ?? this.persistedContent,
      draftContent: draftContent ?? this.draftContent,
      version: version ?? this.version,
    );
  }
}
