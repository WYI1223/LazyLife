import 'package:flutter/foundation.dart';

/// Save lifecycle for one workspace note buffer.
enum WorkspaceSaveState { clean, dirty, saving, saveError }

/// Minimal layout state shape kept split-ready for v0.2/v0.3.
@immutable
class WorkspaceLayoutState {
  const WorkspaceLayoutState({
    required this.paneOrder,
    required this.primaryPaneId,
  });

  /// Ordered pane ids from left to right.
  final List<String> paneOrder;

  /// Default pane for single-pane baseline.
  final String primaryPaneId;

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
  const WorkspaceNoteBuffer({
    required this.noteId,
    required this.persistedContent,
    required this.draftContent,
    required this.version,
  });

  final String noteId;
  final String persistedContent;
  final String draftContent;
  final int version;

  bool get isDirty => draftContent != persistedContent;

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
