import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/diagnostics/dart_event_logger.dart';
import 'package:lazynote_flutter/core/workspace/workspace_tree_children_loader.dart';
import 'package:lazynote_flutter/core/workspace/workspace_tree_error_utils.dart';
import 'package:lazynote_flutter/core/workspace/workspace_tree_types.dart';
export 'workspace_tree_types.dart';

/// Workspace tree state and mutation service (core infrastructure).
///
/// Scope:
/// - Holds workspace tree request state + error envelopes.
/// - Owns create/rename/move/delete/list tree operations.
/// - Keeps controller-facing API stable via facade delegation.
///
/// Renamed from WorkspaceTreeManager in PR-RB-05 (S9 core/workspace extraction).
class WorkspaceTreeService extends ChangeNotifier {
  static const String _uncategorizedFolderNodeId = '__uncategorized__';
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  WorkspaceTreeService({
    required WorkspaceDeleteFolderInvoker workspaceDeleteFolderInvoker,
    required WorkspaceCreateFolderInvoker workspaceCreateFolderInvoker,
    required WorkspaceRenameNodeInvoker workspaceRenameNodeInvoker,
    required WorkspaceMoveNodeInvoker workspaceMoveNodeInvoker,
    required WorkspaceListChildrenInvoker workspaceListChildrenInvoker,
    WorkspaceAncestorPathInvoker? workspaceAncestorPathInvoker,
    WorkspaceResolveDesignatedInvoker? workspaceResolveDesignatedInvoker,
    WorkspaceReassignDesignatedInvoker? workspaceReassignDesignatedInvoker,
    WorkspaceGetAncestorPathInvoker? workspaceGetAncestorPathInvoker,
    WorkspaceGetDefaultInvoker? workspaceGetDefaultInvoker,
    required WorkspacePrepare prepare,
    required WorkspaceCreateNoteAndGetAtomId createNoteAndGetAtomId,
    required WorkspaceFlushPendingSave flushPendingSave,
    required WorkspaceDeleteSuccessHook onDeleteSuccess,
    required WorkspaceNoteById noteById,
    required WorkspaceListItemsReader listItems,
  }) : _workspaceDeleteFolderInvoker = workspaceDeleteFolderInvoker,
       _workspaceCreateFolderInvoker = workspaceCreateFolderInvoker,
       _workspaceRenameNodeInvoker = workspaceRenameNodeInvoker,
       _workspaceMoveNodeInvoker = workspaceMoveNodeInvoker,
       _workspaceAncestorPathInvoker = workspaceAncestorPathInvoker,
       _workspaceResolveDesignatedInvoker = workspaceResolveDesignatedInvoker,
       _workspaceReassignDesignatedInvoker = workspaceReassignDesignatedInvoker,
       _workspaceGetAncestorPathInvoker = workspaceGetAncestorPathInvoker,
       _workspaceGetDefaultInvoker = workspaceGetDefaultInvoker,
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
  final WorkspaceRenameNodeInvoker _workspaceRenameNodeInvoker;
  final WorkspaceMoveNodeInvoker _workspaceMoveNodeInvoker;
  final WorkspaceAncestorPathInvoker? _workspaceAncestorPathInvoker;
  final WorkspaceResolveDesignatedInvoker? _workspaceResolveDesignatedInvoker;
  final WorkspaceReassignDesignatedInvoker? _workspaceReassignDesignatedInvoker;
  final WorkspaceGetAncestorPathInvoker? _workspaceGetAncestorPathInvoker;
  final WorkspaceGetDefaultInvoker? _workspaceGetDefaultInvoker;
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
  final Map<String, Map<String, String>> _designatedNodeCache =
      <String, Map<String, String>>{};
  TreeMutationDelta? _lastMutation;
  int _mutationRevision = 0;

  bool get workspaceDeleteInFlight => _workspaceDeleteInFlight;

  String? get workspaceDeleteErrorMessage => _workspaceDeleteErrorMessage;

  bool get workspaceCreateFolderInFlight => _workspaceCreateFolderInFlight;

  String? get workspaceCreateFolderErrorMessage =>
      _workspaceCreateFolderErrorMessage;

  bool get workspaceNodeMutationInFlight => _workspaceNodeMutationInFlight;

  String? get workspaceNodeMutationErrorMessage =>
      _workspaceNodeMutationErrorMessage;

  int get workspaceTreeRevision => _workspaceTreeRevision;

  TreeMutationDelta? get lastMutation => _lastMutation;

  bool get hasGuardedReassignSupport =>
      _workspaceReassignDesignatedInvoker != null;

  bool get hasGuardedAncestorPathSupport =>
      _workspaceGetAncestorPathInvoker != null;

  Future<String?> resolveDefaultWorkspaceRootId() =>
      _resolveDefaultWorkspaceRootId();

  Future<void> loadSystemNodes(String workspaceId) async {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      throw WorkspaceInitException('Workspace id is required.');
    }

    const requiredRoles = <String>['inbox', 'tasks', 'calendar'];
    final cached = _designatedNodeCache[normalizedWorkspaceId];
    if (cached != null &&
        requiredRoles.every((role) => (cached[role] ?? '').trim().isNotEmpty)) {
      return;
    }

    final invoker = _workspaceResolveDesignatedInvoker;
    if (invoker == null) {
      throw WorkspaceInitException(
        'Workspace designated-folder lookup is not configured.',
      );
    }

    await _prepare();
    final caller = buildWorkspaceCaller(normalizedWorkspaceId);
    final resolved = <String, String>{};

    for (final role in requiredRoles) {
      final response = await invoker(
        caller: caller,
        workspaceId: normalizedWorkspaceId,
        role: role,
      );
      final nodeUuid = response.nodeUuid?.trim();
      if (response.ok && nodeUuid != null && nodeUuid.isNotEmpty) {
        resolved[role] = nodeUuid;
        continue;
      }
      if (response.errorCode == 'designated_role_not_found') {
        throw DesignatedRoleNotFoundException(
          workspaceId: normalizedWorkspaceId,
          role: role,
          message: response.message,
        );
      }
      throw WorkspaceInitException(
        response.message.isNotEmpty
            ? response.message
            : 'Failed to resolve designated role $role.',
      );
    }

    _designatedNodeCache[normalizedWorkspaceId] = resolved;
  }

  String getSystemNodeId(String workspaceId, String role) {
    final normalizedWorkspaceId = workspaceId.trim();
    final normalizedRole = role.trim();
    final workspaceRoles = _designatedNodeCache[normalizedWorkspaceId];
    if (workspaceRoles == null) {
      throw WorkspaceInitException(
        'Workspace $normalizedWorkspaceId has not been initialized.',
      );
    }

    final nodeId = workspaceRoles[normalizedRole]?.trim();
    if (nodeId == null || nodeId.isEmpty) {
      throw DesignatedRoleNotFoundException(
        workspaceId: normalizedWorkspaceId,
        role: normalizedRole,
      );
    }
    return nodeId;
  }

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
      final deltaParentId = await _resolveRequiredCreateParentId(
        normalizedParent,
      );
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
      _emitMutation(TreeMutationType.create, <String?>[deltaParentId]);
      return response;
    } on _WorkspaceMutationPreconditionException catch (error) {
      _workspaceCreateFolderErrorMessage = error.message;
      return rust_api.WorkspaceNodeResponse(
        ok: false,
        errorCode: error.errorCode,
        message: error.message,
        node: null,
      );
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
      await _prepare();
      final deltaParentId = await _resolveRequiredCreateParentId(
        parentForCreateRef,
      );
      final result = await _createNoteAndGetAtomId(
        parentNodeId: parentForCreateRef,
      );
      if (result.atomId == null || result.atomId!.trim().isEmpty) {
        final errorCode = result.errorCode ?? 'internal_error';
        final message = workspaceActionErrorMessage(
          errorCode: result.errorCode,
          message: result.errorMessage ?? '',
          fallback: 'Created note is missing atom id for workspace linking.',
        );
        _workspaceNodeMutationErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: errorCode,
          message: message,
        );
      }

      _workspaceNodeMutationErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      _emitMutation(TreeMutationType.create, <String?>[deltaParentId]);
      return const rust_api.WorkspaceActionResponse(
        ok: true,
        errorCode: null,
        message: 'ok',
      );
    } on _WorkspaceMutationPreconditionException catch (error) {
      _workspaceNodeMutationErrorMessage = error.message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: error.errorCode,
        message: error.message,
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
      final parentBefore = await _resolveRequiredParentForNode(
        normalizedNodeId,
        fallbackMessage:
            'Failed to resolve parent branch for workspace rename.',
      );
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
      _emitMutation(TreeMutationType.rename, <String?>[parentBefore]);
      return response;
    } on _WorkspaceMutationPreconditionException catch (error) {
      _workspaceNodeMutationErrorMessage = error.message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: error.errorCode,
        message: error.message,
      );
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
    final _ = targetOrder;

    _workspaceNodeMutationInFlight = true;
    _workspaceNodeMutationErrorMessage = null;
    notifyListeners();
    try {
      await _prepare();
      final parentForMove = switch (normalizedParent) {
        _WorkspaceParentValidation.root =>
          await _resolveRequiredDefaultWorkspaceRootId(),
        _WorkspaceParentValidation.value => newParentNodeId?.trim(),
        _WorkspaceParentValidation.invalid => null,
      };
      final oldParentId = await _resolveRequiredParentForNode(
        normalizedNodeId,
        fallbackMessage: 'Failed to resolve source parent branch for move.',
      );
      final newParentId = parentForMove;
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
          module: 'core.workspace_tree_service',
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
        module: 'core.workspace_tree_service',
        message: 'Workspace move succeeded.',
        dedupe: false,
      );
      _workspaceNodeMutationErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      _emitMutation(TreeMutationType.move, <String?>[oldParentId, newParentId]);
      return response;
    } on _WorkspaceMutationPreconditionException catch (error) {
      _workspaceNodeMutationErrorMessage = error.message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: error.errorCode,
        message: error.message,
      );
    } catch (error) {
      final message = 'Workspace node move failed unexpectedly: $error';
      DartEventLogger.tryLog(
        level: 'warn',
        eventName: 'workspace.node_move.exception',
        module: 'core.workspace_tree_service',
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
      final parentBefore = await _resolveRequiredParentForNode(
        normalizedFolderId,
        fallbackMessage:
            'Failed to resolve parent branch for workspace delete.',
      );
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
      _emitMutation(TreeMutationType.delete, <String?>[parentBefore]);
      return response;
    } on _WorkspaceMutationPreconditionException catch (error) {
      _workspaceDeleteErrorMessage = error.message;
      return rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: error.errorCode,
        message: error.message,
      );
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

  Future<rust_api.WorkspaceActionResponse> reassignDesignated({
    required String workspaceId,
    required String role,
    required String newNodeUuid,
  }) async {
    if (_workspaceNodeMutationInFlight) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'busy',
        message: 'Workspace node mutation is already in progress.',
      );
    }

    final normalizedWorkspaceId = workspaceId.trim();
    final normalizedRole = role.trim();
    final normalizedNewNodeUuid = newNodeUuid.trim();
    if (normalizedWorkspaceId.isEmpty) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'workspace_not_found',
        message: 'Workspace id is required.',
      );
    }
    if (normalizedRole.isEmpty) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'designated_role_not_found',
        message: 'Designated role is required.',
      );
    }
    if (normalizedNewNodeUuid.isEmpty ||
        !_uuidPattern.hasMatch(normalizedNewNodeUuid)) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'invalid_node_id',
        message: 'New designated folder id must be a UUID.',
      );
    }

    final resolveInvoker = _workspaceResolveDesignatedInvoker;
    final reassignInvoker = _workspaceReassignDesignatedInvoker;
    if (resolveInvoker == null || reassignInvoker == null) {
      return const rust_api.WorkspaceActionResponse(
        ok: false,
        errorCode: 'internal_error',
        message: 'Workspace designated-folder reassign is not configured.',
      );
    }

    _workspaceNodeMutationInFlight = true;
    _workspaceNodeMutationErrorMessage = null;
    notifyListeners();
    try {
      await _prepare();
      final caller = buildWorkspaceCaller(normalizedWorkspaceId);
      final cachedNodeId =
          _designatedNodeCache[normalizedWorkspaceId]?[normalizedRole]?.trim();
      final currentDesignated = await _resolveCurrentDesignatedNodeId(
        workspaceId: normalizedWorkspaceId,
        role: normalizedRole,
        caller: caller,
        cachedNodeId: cachedNodeId,
        resolveInvoker: resolveInvoker,
      );
      final oldNodeId = currentDesignated.nodeId;
      if (oldNodeId == null) {
        final errorCode = (currentDesignated.errorCode ?? '').trim().isEmpty
            ? 'designated_role_not_found'
            : currentDesignated.errorCode!;
        final message = workspaceActionErrorMessage(
          errorCode: errorCode,
          message: currentDesignated.message,
          fallback: errorCode == 'workspace_not_found'
              ? 'Workspace not found.'
              : 'Failed to resolve current designated folder.',
        );
        _workspaceNodeMutationErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: errorCode,
          message: message,
        );
      }

      final oldParentId = await _resolveRequiredParentForNode(
        oldNodeId,
        workspaceId: normalizedWorkspaceId,
        fallbackMessage:
            'Failed to resolve previous designated-folder parent branch.',
      );
      final newParentId = await _resolveRequiredParentForNode(
        normalizedNewNodeUuid,
        workspaceId: normalizedWorkspaceId,
        fallbackMessage:
            'Failed to resolve new designated-folder parent branch.',
      );
      final response = await reassignInvoker(
        caller: caller,
        workspaceId: normalizedWorkspaceId,
        role: normalizedRole,
        newNodeUuid: normalizedNewNodeUuid,
      );
      if (!response.ok) {
        final message = workspaceActionErrorMessage(
          errorCode: response.errorCode,
          message: response.message,
          fallback: 'Failed to reassign designated folder.',
        );
        _workspaceNodeMutationErrorMessage = message;
        return rust_api.WorkspaceActionResponse(
          ok: false,
          errorCode: response.errorCode,
          message: message,
        );
      }

      _designatedNodeCache.putIfAbsent(
        normalizedWorkspaceId,
        () => <String, String>{},
      )[normalizedRole] = normalizedNewNodeUuid;
      _workspaceNodeMutationErrorMessage = null;
      _bumpWorkspaceTreeRevision();
      _emitMutation(TreeMutationType.reassign, <String?>[
        oldParentId,
        newParentId,
      ]);
      return response;
    } catch (error) {
      final message =
          'Workspace designated reassign failed unexpectedly: $error';
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

  /// Returns the ancestor folder path for an atom (root to direct parent).
  ///
  /// Returns empty list if no invoker is configured or on failure.
  Future<List<String>> ancestorPath({required String atomId}) async {
    final invoker = _workspaceAncestorPathInvoker;
    if (invoker == null) return const [];
    try {
      await _prepare();
      final response = await invoker(atomId: atomId);
      if (response.ok) return response.path;
    } catch (_) {
      // Non-fatal; caller handles empty path gracefully.
    }
    return const [];
  }

  void _bumpWorkspaceTreeRevision() {
    _workspaceTreeRevision += 1;
  }

  Future<String> _resolveRequiredCreateParentId(
    String? normalizedParent,
  ) async {
    if (normalizedParent != null && normalizedParent.isNotEmpty) {
      return normalizedParent;
    }
    return _resolveRequiredDefaultWorkspaceRootId();
  }

  Future<String?> _resolveRequiredParentForNode(
    String nodeId, {
    String? workspaceId,
    required String fallbackMessage,
  }) async {
    final invoker = _workspaceGetAncestorPathInvoker;
    if (invoker == null) {
      throw const _WorkspaceMutationPreconditionException(
        'internal_error',
        'Workspace ancestor-path lookup is not configured.',
      );
    }
    try {
      final response = await invoker(
        caller: workspaceId == null
            ? const rust_api.FfiCallerContext(
                identity: rust_api.FfiCallerIdentity.app,
              )
            : buildWorkspaceCaller(workspaceId),
        nodeUuid: nodeId,
      );
      if (!response.ok) {
        throw _WorkspaceMutationPreconditionException(
          (response.errorCode ?? '').trim().isEmpty
              ? 'internal_error'
              : response.errorCode!,
          response.message.trim().isEmpty ? fallbackMessage : response.message,
        );
      }
      if (response.segments.isEmpty) {
        return null;
      }
      final parentId = response.segments.last.nodeUuid.trim();
      return parentId.isEmpty ? null : parentId;
    } on _WorkspaceMutationPreconditionException {
      rethrow;
    } catch (error) {
      throw _WorkspaceMutationPreconditionException(
        'internal_error',
        '$fallbackMessage $error',
      );
    }
  }

  Future<String?> _resolveDefaultWorkspaceRootId() async {
    final invoker = _workspaceGetDefaultInvoker;
    if (invoker == null) return null;
    try {
      final response = await invoker(
        caller: const rust_api.FfiCallerContext(
          identity: rust_api.FfiCallerIdentity.app,
        ),
      );
      if (!response.ok || response.workspace == null) {
        return null;
      }
      final workspaceId = response.workspace!.workspaceId.trim();
      return workspaceId.isEmpty ? null : workspaceId;
    } catch (_) {
      return null;
    }
  }

  Future<String> _resolveRequiredDefaultWorkspaceRootId() async {
    final invoker = _workspaceGetDefaultInvoker;
    if (invoker == null) {
      throw const _WorkspaceMutationPreconditionException(
        'internal_error',
        'Default workspace lookup is not configured.',
      );
    }

    final response = await invoker(
      caller: const rust_api.FfiCallerContext(
        identity: rust_api.FfiCallerIdentity.app,
      ),
    );
    if (!response.ok) {
      throw _WorkspaceMutationPreconditionException(
        (response.errorCode ?? '').trim().isEmpty
            ? 'internal_error'
            : response.errorCode!,
        response.message.trim().isEmpty
            ? 'Failed to resolve the default workspace root.'
            : response.message,
      );
    }
    final workspaceId = response.workspace?.workspaceId.trim() ?? '';
    if (workspaceId.isEmpty) {
      throw const _WorkspaceMutationPreconditionException(
        'internal_error',
        'Failed to resolve the default workspace root.',
      );
    }
    return workspaceId;
  }

  void _emitMutation(TreeMutationType type, Iterable<String?> parentIds) {
    _mutationRevision += 1;
    _lastMutation = TreeMutationDelta(
      revision: _mutationRevision,
      type: type,
      affectedParentIds: parentIds,
    );
  }

  Future<({String? nodeId, String? errorCode, String message})>
  _resolveCurrentDesignatedNodeId({
    required String workspaceId,
    required String role,
    required rust_api.FfiCallerContext caller,
    required String? cachedNodeId,
    required WorkspaceResolveDesignatedInvoker resolveInvoker,
  }) async {
    if (cachedNodeId != null && cachedNodeId.isNotEmpty) {
      return (nodeId: cachedNodeId, errorCode: null, message: '');
    }
    final response = await resolveInvoker(
      caller: caller,
      workspaceId: workspaceId,
      role: role,
    );
    final nodeId = response.nodeUuid?.trim();
    if (!response.ok || nodeId == null || nodeId.isEmpty) {
      return (
        nodeId: null,
        errorCode: response.errorCode,
        message: response.message,
      );
    }
    return (nodeId: nodeId, errorCode: null, message: '');
  }
}

enum _WorkspaceParentValidation { root, value, invalid }

class _WorkspaceMutationPreconditionException implements Exception {
  const _WorkspaceMutationPreconditionException(this.errorCode, this.message);

  final String errorCode;
  final String message;
}
