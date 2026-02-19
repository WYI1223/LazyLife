import 'package:flutter/foundation.dart';

/// Save lifecycle for one workspace note buffer.
enum WorkspaceSaveState { clean, dirty, saving, saveError }

/// Minimal layout state shape kept split-ready for v0.2/v0.3.
@immutable
class WorkspaceLayoutState {
  /// Creates one immutable workspace layout snapshot.
  const WorkspaceLayoutState({
    required this.paneOrder,
    required this.primaryPaneId,
  });

  /// Ordered pane ids from left to right.
  final List<String> paneOrder;

  /// Default pane for single-pane baseline.
  final String primaryPaneId;

  /// Returns the baseline single-pane layout used by current UI.
  factory WorkspaceLayoutState.singlePane() {
    return const WorkspaceLayoutState(
      paneOrder: <String>['pane.primary'],
      primaryPaneId: 'pane.primary',
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
