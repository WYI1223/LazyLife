typedef WorkspacePortSnapshot = ({
  List<String> paneOrder,
  String activePaneId,
  Map<String, List<String>> openTabsByPane,
});

/// Notes->workspace boundary interface (D7).
abstract interface class WorkspacePort {
  String? get activeNoteId;
  String get activeDraftContent;
  bool hasDraftBuffer(String noteId);

  WorkspacePortSnapshot snapshot();
  void beginBatchSync();
  void endBatchSync();
  void resetAll();

  void syncExternalNote({
    required String noteId,
    required String persistedContent,
    required String draftContent,
    required String saveState,
    bool activate = false,
    String? paneId,
  });

  void syncSaveState({required String noteId, required String saveState});
}
