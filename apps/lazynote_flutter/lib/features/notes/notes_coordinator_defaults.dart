part of 'notes_coordinator.dart';

// ── Default invokers ───────────────────────────────────────────────────
// Production-wired FFI delegates used when no test invoker is injected.

Future<rust_api.AtomListResponse> _defaultNotesListInvoker({
  String? tag,
  int? limit,
  int? offset,
}) {
  return rust_api.notesList(tag: tag, limit: limit, offset: offset);
}

Future<rust_api.AtomItemResponse> _defaultNoteGetInvoker({
  required String atomId,
}) {
  return rust_api.noteGet(atomId: atomId);
}

Future<rust_api.AtomItemResponse> _defaultNoteCreateInvoker({
  required String content,
  String? parentNodeId,
}) {
  return rust_api.noteCreate(content: content, parentNodeId: parentNodeId);
}

Future<rust_api.AtomItemResponse> _defaultNoteUpdateInvoker({
  required String atomId,
  required String content,
}) {
  return rust_api.noteUpdate(atomId: atomId, content: content);
}

Future<rust_api.TagsListResponse> _defaultTagsListInvoker() {
  return rust_api.tagsList();
}

Future<rust_api.AtomItemResponse> _defaultNoteSetTagsInvoker({
  required String atomId,
  required List<String> tags,
}) {
  return rust_api.noteSetTags(atomId: atomId, tags: tags);
}

Future<rust_api.WorkspaceActionResponse> _defaultWorkspaceDeleteFolderInvoker({
  required String nodeId,
  required String mode,
}) {
  return rust_api.workspaceDeleteFolder(nodeId: nodeId, mode: mode);
}

Future<rust_api.WorkspaceNodeResponse> _defaultWorkspaceCreateFolderInvoker({
  String? parentNodeId,
  required String name,
}) {
  return rust_api.workspaceCreateFolder(parentNodeId: parentNodeId, name: name);
}

Future<rust_api.WorkspaceActionResponse> _defaultWorkspaceRenameNodeInvoker({
  required String nodeId,
  required String newName,
}) {
  return rust_api.workspaceRenameNode(nodeId: nodeId, newName: newName);
}

Future<rust_api.WorkspaceActionResponse> _defaultWorkspaceMoveNodeInvoker({
  required String nodeId,
  String? newParentId,
  int? targetOrder,
}) {
  return rust_api.workspaceMoveNode(
    nodeId: nodeId,
    newParentId: newParentId,
    targetOrder: targetOrder,
  );
}

Future<rust_api.WorkspaceListChildrenResponse>
_defaultWorkspaceListChildrenInvoker({String? parentNodeId}) {
  return rust_api.workspaceListChildren(parentNodeId: parentNodeId);
}

Future<void> _defaultPrepare() async {
  await RustBridge.ensureEntryDbPathConfigured();
}
