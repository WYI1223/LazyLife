import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/diagnostics/dart_event_logger.dart';
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_children_loader.dart';
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_error_utils.dart';
import 'package:lazynote_flutter/features/notes/managers/workspace_tree_types.dart';
export 'workspace_tree_types.dart';

/// Extracted workspace-tree state and mutation manager.
///
/// Scope:
/// - Holds workspace tree request state + error envelopes.
/// - Owns create/rename/move/delete/list tree operations.
/// - Keeps controller-facing API stable via facade delegation.
class WorkspaceTreeManager extends ChangeNotifier {
  static const String _uncategorizedFolderNodeId = '__uncategorized__';
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  WorkspaceTreeManager({
    required WorkspaceDeleteFolderInvoker workspaceDeleteFolderInvoker,
    required WorkspaceCreateFolderInvoker workspaceCreateFolderInvoker,
    required WorkspaceCreateNoteRefInvoker workspaceCreateNoteRefInvoker,
    required WorkspaceRenameNodeInvoker workspaceRenameNodeInvoker,
    required WorkspaceMoveNodeInvoker workspaceMoveNodeInvoker,
    required WorkspaceListChildrenInvoker workspaceListChildrenInvoker,
    required WorkspacePrepare prepare,
    required WorkspaceCreateNoteAndGetAtomId createNoteAndGetAtomId,
    required WorkspaceFlushPendingSave flushPendingSave,
    required WorkspaceDeleteSuccessHook onDeleteSuccess,
    required WorkspaceNoteById noteById,
    required WorkspaceListItemsReader listItems,
  }) : _workspaceDeleteFolderInvoker = workspaceDeleteFolderInvoker,
       _workspaceCreateFolderInvoker = workspaceCreateFolderInvoker,
       _workspaceCreateNoteRefInvoker = workspaceCreateNoteRefInvoker,
       _workspaceRenameNodeInvoker = workspaceRenameNodeInvoker,
       _workspaceMoveNodeInvoker = workspaceMoveNodeInvoker,
       _prepare = prepare,
       _createNoteAndGetAtomId = createNoteAndGetAtomId,
       _flushPendingSave = flushPendingSave,
       _onDeleteSuccess = onDeleteSuccess,
       _childrenLoader = WorkspaceTreeChildrenLoader(
         prepare: prepare,
         listChildrenInvoker: workspaceListChildrenInvoker,
         noteById: noteById,
         listItems: listItems,
       );

  final WorkspaceDeleteFolderInvoker _workspaceDeleteFolderInvoker;
  final WorkspaceCreateFolderInvoker _workspaceCreateFolderInvoker;
  final WorkspaceCreateNoteRefInvoker _workspaceCreateNoteRefInvoker;
  final WorkspaceRenameNodeInvoker _workspaceRenameNodeInvoker;
  final WorkspaceMoveNodeInvoker _workspaceMoveNodeInvoker;
  final WorkspacePrepare _prepare;
  final WorkspaceCreateNoteAndGetAtomId _createNoteAndGetAtomId;
  final WorkspaceFlushPendingSave _flushPendingSave;
  final WorkspaceDeleteSuccessHook _onDeleteSuccess;
  final WorkspaceTreeChildrenLoader _childrenLoader;

  bool _workspaceDeleteInFlight = false;
  String? _workspaceDeleteErrorMessage;
  bool _workspaceCreateFolderInFlight = false;
  String? _workspaceCreateFolderErrorMessage;
  bool _workspaceNodeMutationInFlight = false;
  String? _workspaceNodeMutationErrorMessage;
  int _workspaceTreeRevision = 0;

  bool get workspaceDeleteInFlight => _workspaceDeleteInFlight;

  String? get workspaceDeleteErrorMessage => _workspaceDeleteErrorMessage;

  bool get workspaceCreateFolderInFlight => _workspaceCreateFolderInFlight;

  String? get workspaceCreateFolderErrorMessage =>
      _workspaceCreateFolderErrorMessage;

  bool get workspaceNodeMutationInFlight => _workspaceNodeMutationInFlight;

  String? get workspaceNodeMutationErrorMessage =>
      _workspaceNodeMutationErrorMessage;

  int get workspaceTreeRevision => _workspaceTreeRevision;

  /// Creates one workspace folder under root or one parent folder.
  Future<rust_api.WorkspaceNodeResponse> createWorkspaceFolder({
    required String name,
    String? parentNodeId,
  }) async {
    if (_workspaceCreateFolderInFlight) {
      return const rust_api.WorkspaceNodeResponse(
        ok: false,
        errorCode: 'busy',
        message: 'Workspace folder create is already in progress.',
        node: null,
      );
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return const rust_api.WorkspaceNodeResponse(
        ok: false,
        errorCode: 'invalid_display_name',
        message: 'Folder name is required.',
        node: null,
      );
    }
    final normalizedParent = parentNodeId?.trim();
    if (normalizedParent != null && normalizedParent.isEmpty) {
      return const rust_api.WorkspaceNodeResponse(
        ok: false,
        errorCode: 'invalid_parent_node_id',
        message: 'Parent node id is invalid.',
        node: null,
      );
    }
    if (normalizedParent != null && !_uuidPattern.hasMatch(normalizedParent)) {
      return const rust_api.WorkspaceNodeResponse(
        ok: false,
        errorCode: 'invalid_parent_node_id',
        message: 'Parent node id must be a UUID.',
        node: null,
      );
    }

    _workspaceCreateFolderInFlight = true;
    _workspaceCreateFolderErrorMessage = null;
    notifyListeners();
    try {
      await _prepare();
      final response = await _workspaceCreateFolderInvoker(
        parentNodeId: normalizedParent,
        name: normalizedName,
      );
      if (!response.ok) {
        final message = workspaceActionErrorMessage(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to create workspace folder.',
        );
        _workspaceCreateFolderErrorMessage = message;
        return rust_api.WorkspaceNodeResponse(
          ok: false,
          errorCode: response.errorCode,
          message: message,
          node: response.node,
        );
      }
      _workspaceCreateFolderErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      return response;
    } catch (error) {
      final message = 'Workspace folder create failed unexpectedly: $error';
      _workspaceCreateFolderErrorMessage = message;
      return rust_api.WorkspaceNodeResponse(
        ok: false,
        errorCode: 'internal_error',
        message: message,
        node: null,
      );
    } finally {
      _workspaceCreateFolderInFlight = false;
      notifyListeners();
    }
  }

  /// Creates one note and links it into workspace tree under optional parent.
  Future<rust_api.WorkspaceActionResponse> createWorkspaceNoteInFolder({
    String? parentNodeId,
  }) async {
    if (_workspaceNodeMutationInFlight) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'busy',
        message: 'Workspace node mutation is already in progress.',
      );
    }

    final normalizedParent = _normalizeWorkspaceParentId(parentNodeId);
    if (normalizedParent == _WorkspaceParentValidation.invalid) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_parent_node_id',
        message: 'Parent node id must be a UUID or null.',
      );
    }
    final parentForCreateRef = switch (normalizedParent) {
      _WorkspaceParentValidation.root => null,
      _WorkspaceParentValidation.value => parentNodeId?.trim(),
      _WorkspaceParentValidation.invalid => null,
    };

    _workspaceNodeMutationInFlight = true;
    _workspaceNodeMutationErrorMessage = null;
    notifyListeners();
    try {
      final atomId = await _createNoteAndGetAtomId();
      if (atomId == null || atomId.trim().isEmpty) {
        _workspaceNodeMutationErrorMessage =
            'Created note is missing atom id for workspace linking.';
        return const rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: 'internal_error',
          message: 'Created note is missing atom id for workspace linking.',
        );
      }

      await _prepare();
      final linkResponse = await _workspaceCreateNoteRefInvoker(
        parentNodeId: parentForCreateRef,
        atomId: atomId,
        displayName: null,
      );
      if (!linkResponse.ok) {
        final message = workspaceActionErrorMessage(
          errorCode: linkResponse.errorCode,
          message: linkResponse.message,
          fallback: 'Note created, but linking into workspace failed.',
        );
        _workspaceNodeMutationErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: linkResponse.errorCode,
          message: message,
        );
      }

      _workspaceNodeMutationErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      return const rust_api.WorkspaceActionResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
      );
    } catch (error) {
      final message = 'Workspace note create failed unexpectedly: $error';
      _workspaceNodeMutationErrorMessage = message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'internal_error',
        message: message,
      );
    } finally {
      _workspaceNodeMutationInFlight = false;
      notifyListeners();
    }
  }

  /// Renames one workspace node.
  Future<rust_api.WorkspaceActionResponse> renameWorkspaceNode({
    required String nodeId,
    required String newName,
  }) async {
    if (_workspaceNodeMutationInFlight) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'busy',
        message: 'Workspace node mutation is already in progress.',
      );
    }
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId.isEmpty || !_uuidPattern.hasMatch(normalizedNodeId)) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_node_id',
        message: 'Node id must be a UUID.',
      );
    }
    final normalizedName = newName.trim();
    if (normalizedName.isEmpty) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_display_name',
        message: 'Node name is required.',
      );
    }

    _workspaceNodeMutationInFlight = true;
    _workspaceNodeMutationErrorMessage = null;
    notifyListeners();
    try {
      await _prepare();
      final response = await _workspaceRenameNodeInvoker(
        nodeId: normalizedNodeId,
        newName: normalizedName,
      );
      if (!response.ok) {
        final message = workspaceActionErrorMessage(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to rename workspace node.',
        );
        _workspaceNodeMutationErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: response.errorCode,
          message: message,
        );
      }
      _workspaceNodeMutationErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      return response;
    } catch (error) {
      final message = 'Workspace node rename failed unexpectedly: $error';
      _workspaceNodeMutationErrorMessage = message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'internal_error',
        message: message,
      );
    } finally {
      _workspaceNodeMutationInFlight = false;
      notifyListeners();
    }
  }

  /// Moves one workspace node under optional target parent.
  Future<rust_api.WorkspaceActionResponse> moveWorkspaceNode({
    required String nodeId,
    String? newParentNodeId,
    int? targetOrder,
  }) async {
    if (_workspaceNodeMutationInFlight) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'busy',
        message: 'Workspace node mutation is already in progress.',
      );
    }
    final normalizedNodeId = nodeId.trim();
    if (normalizedNodeId.isEmpty || !_uuidPattern.hasMatch(normalizedNodeId)) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_node_id',
        message: 'Node id must be a UUID.',
      );
    }
    final normalizedParent = _normalizeWorkspaceParentId(newParentNodeId);
    if (normalizedParent == _WorkspaceParentValidation.invalid) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_parent_node_id',
        message: 'Parent node id must be a UUID or null.',
      );
    }
    final parentForMove = switch (normalizedParent) {
      _WorkspaceParentValidation.root => null,
      _WorkspaceParentValidation.value => newParentNodeId?.trim(),
      _WorkspaceParentValidation.invalid => null,
    };
    final _ = targetOrder;

    _workspaceNodeMutationInFlight = true;
    _workspaceNodeMutationErrorMessage = null;
    notifyListeners();
    try {
      await _prepare();
      final response = await _workspaceMoveNodeInvoker(
        nodeId: normalizedNodeId,
        newParentId: parentForMove,
        // v0.2 transition freeze: UI move path is parent-change-only.
        // Keep `targetOrder` in API shape for compatibility, but do not pass it.
        targetOrder: null,
      );
      if (!response.ok) {
        final message = workspaceActionErrorMessage(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to move workspace node.',
        );
        DartEventLogger.tryLog(
          level: 'warn',
          eventName: 'workspace.node_move.error',
          module: 'notes.workspace_tree_manager',
          message:
              'Workspace move failed (${response.errorCode ?? "unknown"}).',
          dedupe: false,
        );
        _workspaceNodeMutationErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: response.errorCode,
          message: message,
        );
      }
      DartEventLogger.tryLog(
        level: 'info',
        eventName: 'workspace.node_move.ok',
        module: 'notes.workspace_tree_manager',
        message: 'Workspace move succeeded.',
        dedupe: false,
      );
      _workspaceNodeMutationErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      return response;
    } catch (error) {
      final message = 'Workspace node move failed unexpectedly: $error';
      DartEventLogger.tryLog(
        level: 'warn',
        eventName: 'workspace.node_move.exception',
        module: 'notes.workspace_tree_manager',
        message: 'Workspace move failed unexpectedly.',
        dedupe: false,
      );
      _workspaceNodeMutationErrorMessage = message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'internal_error',
        message: message,
      );
    } finally {
      _workspaceNodeMutationInFlight = false;
      notifyListeners();
    }
  }

  /// Lists workspace tree children for explorer lazy rendering.
  Future<rust_api.WorkspaceListChildrenResponse> listWorkspaceChildren({
    String? parentNodeId,
  }) async {
    return _childrenLoader.listWorkspaceChildren(parentNodeId: parentNodeId);
  }

  /// Deletes one workspace folder by explicit mode, then runs success hook.
  Future<rust_api.WorkspaceActionResponse> deleteWorkspaceFolder({
    required String folderId,
    required String mode,
  }) async {
    if (_workspaceDeleteInFlight) {
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'busy',
        message: 'Workspace delete is already in progress.',
      );
    }

    final normalizedFolderId = folderId.trim();
    if (normalizedFolderId.isEmpty) {
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_node_id',
        message: 'Folder id is required.',
      );
    }
    final normalizedMode = mode.trim();
    if (normalizedMode != 'dissolve' && normalizedMode != 'delete_all') {
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_delete_mode',
        message: 'Delete mode must be dissolve or delete_all.',
      );
    }

    final flushed = await _flushPendingSave();
    if (!flushed) {
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'save_blocked',
        message: 'Save failed. Retry or back up content before folder delete.',
      );
    }

    _workspaceDeleteInFlight = true;
    _workspaceDeleteErrorMessage = null;
    notifyListeners();
    try {
      await _prepare();
      final response = await _workspaceDeleteFolderInvoker(
        nodeId: normalizedFolderId,
        mode: normalizedMode,
      );
      if (!response.ok) {
        final message = workspaceActionErrorMessage(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to delete workspace folder.',
        );
        _workspaceDeleteErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: response.errorCode,
          message: message,
        );
      }

      await _onDeleteSuccess();
      _workspaceDeleteErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      return response;
    } catch (error) {
      final message = 'Workspace folder delete failed unexpectedly: $error';
      _workspaceDeleteErrorMessage = message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'internal_error',
        message: message,
      );
    } finally {
      _workspaceDeleteInFlight = false;
      notifyListeners();
    }
  }

  _WorkspaceParentValidation _normalizeWorkspaceParentId(String? raw) {
    if (raw == null) {
      return _WorkspaceParentValidation.root;
    }
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return _WorkspaceParentValidation.invalid;
    }
    if (normalized == _uncategorizedFolderNodeId) {
      return _WorkspaceParentValidation.root;
    }
    if (!_uuidPattern.hasMatch(normalized)) {
      return _WorkspaceParentValidation.invalid;
    }
    return _WorkspaceParentValidation.value;
  }

  void _bumpWorkspaceTreeRevision() {
    _workspaceTreeRevision += 1;
  }
}

enum _WorkspaceParentValidation { root, value, invalid }
