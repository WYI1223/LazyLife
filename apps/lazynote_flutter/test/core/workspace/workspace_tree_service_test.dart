import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/workspace/workspace_tree_service.dart';

void main() {
  group('buildWorkspaceCaller', () {
    test('sets app identity and workspace scope', () {
      final caller = buildWorkspaceCaller('ws-1');

      expect(caller.identity, rust_api.FfiCallerIdentity.app);
      expect(caller.scopeWorkspaceId, 'ws-1');
    });
  });

  group('TreeMutationDelta', () {
    test('preserves revision, type, and deduped affected parent ids', () {
      final delta = TreeMutationDelta(
        revision: 7,
        type: TreeMutationType.move,
        affectedParentIds: const <String?>['parent-a', 'parent-a', null, null],
      );

      expect(delta.revision, 7);
      expect(delta.type, TreeMutationType.move);
      expect(delta.affectedParentIds, <String?>{'parent-a', null});
    });
  });

  group('WorkspaceTreeService system nodes', () {
    test('getSystemNodeId throws before preload', () {
      final service = _buildService();

      expect(
        () => service.getSystemNodeId('ws-1', 'inbox'),
        throwsA(isA<WorkspaceInitException>()),
      );
    });

    test(
      'loadSystemNodes loads designated roles and caches sync lookup',
      () async {
        final resolveCalls = <String>[];
        final service = _buildService(
          workspaceResolveDesignatedInvoker:
              ({required caller, required workspaceId, required role}) async {
                resolveCalls.add(
                  '${caller.identity.name}|${caller.scopeWorkspaceId}|$workspaceId|$role',
                );
                return rust_api.DesignatedFolderResponse(
                  ok: true,
                  message: 'ok',
                  nodeUuid: '$role-node',
                );
              },
        );

        await service.loadSystemNodes('ws-1');

        expect(resolveCalls, <String>[
          'app|ws-1|ws-1|inbox',
          'app|ws-1|ws-1|tasks',
          'app|ws-1|ws-1|calendar',
        ]);
        expect(service.getSystemNodeId('ws-1', 'inbox'), 'inbox-node');
        expect(service.getSystemNodeId('ws-1', 'tasks'), 'tasks-node');
        expect(service.getSystemNodeId('ws-1', 'calendar'), 'calendar-node');
      },
    );

    test(
      'loadSystemNodes throws explicit error when designated role is missing',
      () async {
        final service = _buildService(
          workspaceResolveDesignatedInvoker:
              ({required caller, required workspaceId, required role}) async {
                if (role == 'tasks') {
                  return const rust_api.DesignatedFolderResponse(
                    ok: false,
                    errorCode: 'designated_role_not_found',
                    message: 'missing tasks',
                  );
                }
                return rust_api.DesignatedFolderResponse(
                  ok: true,
                  message: 'ok',
                  nodeUuid: '$role-node',
                );
              },
        );

        await expectLater(
          () => service.loadSystemNodes('ws-1'),
          throwsA(isA<DesignatedRoleNotFoundException>()),
        );
      },
    );
  });

  group('WorkspaceTreeService mutation deltas', () {
    test(
      'createWorkspaceFolder emits create delta for explicit parent',
      () async {
        final parentId = _uuid('parent-a');
        final service = _buildService();

        final response = await service.createWorkspaceFolder(
          name: 'Inbox',
          parentNodeId: parentId,
        );

        expect(response.ok, isTrue);
        expect(service.lastMutation?.revision, 1);
        expect(service.lastMutation?.type, TreeMutationType.create);
        expect(service.lastMutation?.affectedParentIds, <String?>{parentId});
      },
    );

    test(
      'createWorkspaceFolder resolves null parent to concrete default workspace root id',
      () async {
        final service = _buildService(
          workspaceGetDefaultInvoker: ({required caller}) async =>
              const rust_api.WorkspaceInfoResponse(
                ok: true,
                message: 'ok',
                workspace: rust_api.WorkspaceInfo(
                  workspaceId: 'workspace-root',
                  name: 'Default',
                  isDefault: true,
                ),
              ),
        );

        final response = await service.createWorkspaceFolder(name: 'Inbox');

        expect(response.ok, isTrue);
        expect(service.lastMutation?.type, TreeMutationType.create);
        expect(service.lastMutation?.affectedParentIds, <String?>{
          'workspace-root',
        });
      },
    );

    test(
      'createWorkspaceFolder fails when default workspace root cannot be resolved for null parent',
      () async {
        final service = _buildService(
          workspaceGetDefaultInvoker: ({required caller}) async =>
              const rust_api.WorkspaceInfoResponse(
                ok: false,
                errorCode: 'workspace_not_found',
                message: 'default workspace missing',
              ),
        );

        final response = await service.createWorkspaceFolder(name: 'Inbox');

        expect(response.ok, isFalse);
        expect(response.errorCode, 'workspace_not_found');
        expect(response.message, contains('default workspace missing'));
        expect(service.lastMutation, isNull);
      },
    );

    test(
      'createWorkspaceNoteInFolder emits create delta for explicit parent',
      () async {
        final parentId = _uuid('parent-note');
        final service = _buildService(
          createNoteAndGetAtomId: ({parentNodeId}) async {
            expect(parentNodeId, parentId);
            return (atomId: 'atom-1', errorCode: null, errorMessage: null);
          },
        );

        final response = await service.createWorkspaceNoteInFolder(
          parentNodeId: parentId,
        );

        expect(response.ok, isTrue);
        expect(service.lastMutation?.type, TreeMutationType.create);
        expect(service.lastMutation?.affectedParentIds, <String?>{parentId});
      },
    );

    test(
      'createWorkspaceNoteInFolder resolves null parent to concrete default workspace root id',
      () async {
        final service = _buildService(
          createNoteAndGetAtomId: ({parentNodeId}) async {
            expect(parentNodeId, isNull);
            return (atomId: 'atom-1', errorCode: null, errorMessage: null);
          },
          workspaceGetDefaultInvoker: ({required caller}) async =>
              const rust_api.WorkspaceInfoResponse(
                ok: true,
                message: 'ok',
                workspace: rust_api.WorkspaceInfo(
                  workspaceId: 'workspace-root',
                  name: 'Default',
                  isDefault: true,
                ),
              ),
        );

        final response = await service.createWorkspaceNoteInFolder();

        expect(response.ok, isTrue);
        expect(service.lastMutation?.type, TreeMutationType.create);
        expect(service.lastMutation?.affectedParentIds, <String?>{
          'workspace-root',
        });
      },
    );

    test(
      'renameWorkspaceNode emits parent-targeted delta from ancestor path',
      () async {
        final nodeId = _uuid('node-a');
        final parentId = _uuid('parent-a');
        final service = _buildService(
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async {
                expect(nodeUuid, nodeId);
                return _ancestorResponse(parentId);
              },
        );

        final response = await service.renameWorkspaceNode(
          nodeId: nodeId,
          newName: 'Renamed',
        );

        expect(response.ok, isTrue);
        expect(service.lastMutation?.type, TreeMutationType.rename);
        expect(service.lastMutation?.affectedParentIds, <String?>{parentId});
      },
    );

    test(
      'renameWorkspaceNode prepares before ancestor-path preflight',
      () async {
        final calls = <String>[];
        final nodeId = _uuid('node-rename-order');
        final parentId = _uuid('parent-rename-order');
        final service = _buildService(
          prepare: () async {
            calls.add('prepare');
          },
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async {
                calls.add('ancestor');
                expect(nodeUuid, nodeId);
                return _ancestorResponse(parentId);
              },
          workspaceRenameNodeInvoker:
              ({required nodeId, required newName}) async {
                calls.add('rename');
                return const rust_api.WorkspaceActionResponse(
                  ok: true,
                  message: 'ok',
                );
              },
        );

        final response = await service.renameWorkspaceNode(
          nodeId: nodeId,
          newName: 'Renamed',
        );

        expect(response.ok, isTrue);
        expect(calls, <String>['prepare', 'ancestor', 'rename']);
      },
    );

    test(
      'renameWorkspaceNode fails explicitly when ancestor-path preflight fails',
      () async {
        final nodeId = _uuid('node-rename-fail');
        var renameCalled = false;
        final service = _buildService(
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async =>
                  const rust_api.AncestorPathResponse(
                    ok: false,
                    errorCode: 'bridge_unavailable',
                    message: 'ancestor path unavailable',
                    segments: <rust_api.PathSegment>[],
                  ),
          workspaceRenameNodeInvoker:
              ({required nodeId, required newName}) async {
                renameCalled = true;
                return const rust_api.WorkspaceActionResponse(
                  ok: true,
                  message: 'ok',
                );
              },
        );

        final response = await service.renameWorkspaceNode(
          nodeId: nodeId,
          newName: 'Renamed',
        );

        expect(response.ok, isFalse);
        expect(response.errorCode, 'bridge_unavailable');
        expect(response.message, contains('ancestor path unavailable'));
        expect(renameCalled, isFalse);
        expect(service.lastMutation, isNull);
      },
    );

    test('moveWorkspaceNode emits old and new parent ids', () async {
      final nodeId = _uuid('node-b');
      final oldParentId = _uuid('old-parent');
      final newParentId = _uuid('new-parent');
      final service = _buildService(
        workspaceGetAncestorPathInvoker:
            ({required caller, required nodeUuid}) async {
              expect(nodeUuid, nodeId);
              return _ancestorResponse(oldParentId);
            },
      );

      final response = await service.moveWorkspaceNode(
        nodeId: nodeId,
        newParentNodeId: newParentId,
      );

      expect(response.ok, isTrue);
      expect(service.lastMutation?.type, TreeMutationType.move);
      expect(service.lastMutation?.affectedParentIds, <String?>{
        oldParentId,
        newParentId,
      });
    });

    test(
      'moveWorkspaceNode resolves null parent to concrete default workspace root id',
      () async {
        final nodeId = _uuid('node-root');
        final oldParentId = _uuid('old-parent-root');
        String? forwardedParentId;
        final service = _buildService(
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async {
                expect(nodeUuid, nodeId);
                return _ancestorResponse(oldParentId);
              },
          workspaceGetDefaultInvoker: ({required caller}) async =>
              const rust_api.WorkspaceInfoResponse(
                ok: true,
                message: 'ok',
                workspace: rust_api.WorkspaceInfo(
                  workspaceId: 'workspace-root',
                  name: 'Default',
                  isDefault: true,
                ),
              ),
          workspaceMoveNodeInvoker:
              ({required nodeId, newParentId, targetOrder}) async {
                forwardedParentId = newParentId;
                return const rust_api.WorkspaceActionResponse(
                  ok: true,
                  message: 'ok',
                );
              },
        );

        final response = await service.moveWorkspaceNode(
          nodeId: nodeId,
          newParentNodeId: null,
        );

        expect(response.ok, isTrue);
        expect(forwardedParentId, 'workspace-root');
        expect(service.lastMutation?.type, TreeMutationType.move);
        expect(service.lastMutation?.affectedParentIds, <String?>{
          oldParentId,
          'workspace-root',
        });
      },
    );

    test(
      'moveWorkspaceNode prepares before root/default and ancestor preflight',
      () async {
        final calls = <String>[];
        final nodeId = _uuid('node-move-order');
        final oldParentId = _uuid('old-parent-move-order');
        final service = _buildService(
          prepare: () async {
            calls.add('prepare');
          },
          workspaceGetDefaultInvoker: ({required caller}) async {
            calls.add('default');
            return const rust_api.WorkspaceInfoResponse(
              ok: true,
              message: 'ok',
              workspace: rust_api.WorkspaceInfo(
                workspaceId: 'workspace-root',
                name: 'Default',
                isDefault: true,
              ),
            );
          },
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async {
                calls.add('ancestor');
                expect(nodeUuid, nodeId);
                return _ancestorResponse(oldParentId);
              },
          workspaceMoveNodeInvoker:
              ({required nodeId, newParentId, targetOrder}) async {
                calls.add('move');
                return const rust_api.WorkspaceActionResponse(
                  ok: true,
                  message: 'ok',
                );
              },
        );

        final response = await service.moveWorkspaceNode(
          nodeId: nodeId,
          newParentNodeId: null,
        );

        expect(response.ok, isTrue);
        expect(calls, <String>['prepare', 'default', 'ancestor', 'move']);
      },
    );

    test('moveWorkspaceNode dedupes same-parent move delta', () async {
      final nodeId = _uuid('node-c');
      final parentId = _uuid('parent-c');
      final service = _buildService(
        workspaceGetAncestorPathInvoker:
            ({required caller, required nodeUuid}) async =>
                _ancestorResponse(parentId),
      );

      final response = await service.moveWorkspaceNode(
        nodeId: nodeId,
        newParentNodeId: parentId,
      );

      expect(response.ok, isTrue);
      expect(service.lastMutation?.type, TreeMutationType.move);
      expect(service.lastMutation?.affectedParentIds, <String?>{parentId});
    });

    test(
      'deleteWorkspaceFolder emits parent-targeted delta from ancestor path',
      () async {
        final folderId = _uuid('folder-a');
        final parentId = _uuid('parent-delete');
        final service = _buildService(
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async =>
                  _ancestorResponse(parentId),
        );

        final response = await service.deleteWorkspaceFolder(
          folderId: folderId,
          mode: 'dissolve',
        );

        expect(response.ok, isTrue);
        expect(service.lastMutation?.type, TreeMutationType.delete);
        expect(service.lastMutation?.affectedParentIds, <String?>{parentId});
      },
    );

    test(
      'deleteWorkspaceFolder fails explicitly when ancestor-path preflight fails',
      () async {
        final folderId = _uuid('folder-delete-fail');
        var deleteCalled = false;
        final service = _buildService(
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async =>
                  const rust_api.AncestorPathResponse(
                    ok: false,
                    errorCode: 'bridge_unavailable',
                    message: 'ancestor path unavailable',
                    segments: <rust_api.PathSegment>[],
                  ),
          workspaceDeleteFolderInvoker:
              ({required nodeId, required mode}) async {
                deleteCalled = true;
                return const rust_api.WorkspaceActionResponse(
                  ok: true,
                  message: 'ok',
                );
              },
        );

        final response = await service.deleteWorkspaceFolder(
          folderId: folderId,
          mode: 'dissolve',
        );

        expect(response.ok, isFalse);
        expect(response.errorCode, 'bridge_unavailable');
        expect(response.message, contains('ancestor path unavailable'));
        expect(deleteCalled, isFalse);
        expect(service.lastMutation, isNull);
      },
    );

    test('reassignDesignated updates cache and emits reassign delta', () async {
      final workspaceId = _uuid('workspace-a');
      final oldNodeId = _uuid('old-designated');
      final newNodeId = _uuid('new-designated');
      final oldParentId = _uuid('old-parent');
      final newParentId = _uuid('new-parent');
      final reassignCalls = <String>[];
      final service = _buildService(
        workspaceResolveDesignatedInvoker:
            ({required caller, required workspaceId, required role}) async =>
                rust_api.DesignatedFolderResponse(
                  ok: true,
                  message: 'ok',
                  nodeUuid: role == 'tasks' ? oldNodeId : '$role-node',
                ),
        workspaceReassignDesignatedInvoker:
            ({
              required caller,
              required workspaceId,
              required role,
              required newNodeUuid,
            }) async {
              reassignCalls.add(
                '${caller.identity.name}|${caller.scopeWorkspaceId}|$workspaceId|$role|$newNodeUuid',
              );
              return const rust_api.WorkspaceActionResponse(
                ok: true,
                message: 'ok',
              );
            },
        workspaceGetAncestorPathInvoker:
            ({required caller, required nodeUuid}) async {
              if (nodeUuid == oldNodeId) {
                return _ancestorResponse(oldParentId);
              }
              if (nodeUuid == newNodeId) {
                return _ancestorResponse(newParentId);
              }
              return const rust_api.AncestorPathResponse(
                ok: true,
                message: 'ok',
                segments: <rust_api.PathSegment>[],
              );
            },
      );

      await service.loadSystemNodes(workspaceId);
      final response = await service.reassignDesignated(
        workspaceId: workspaceId,
        role: 'tasks',
        newNodeUuid: newNodeId,
      );

      expect(response.ok, isTrue);
      expect(reassignCalls, <String>[
        'app|$workspaceId|$workspaceId|tasks|$newNodeId',
      ]);
      expect(service.getSystemNodeId(workspaceId, 'tasks'), newNodeId);
      expect(service.lastMutation?.type, TreeMutationType.reassign);
      expect(service.lastMutation?.affectedParentIds, <String?>{
        oldParentId,
        newParentId,
      });
    });

    test(
      'reassignDesignated keeps cache and delta unchanged on failure',
      () async {
        final workspaceId = _uuid('workspace-b');
        final oldNodeId = _uuid('old-designated-b');
        final newNodeId = _uuid('new-designated-b');
        final oldParentId = _uuid('old-parent-b');
        final newParentId = _uuid('new-parent-b');
        final service = _buildService(
          workspaceResolveDesignatedInvoker:
              ({required caller, required workspaceId, required role}) async =>
                  rust_api.DesignatedFolderResponse(
                    ok: true,
                    message: 'ok',
                    nodeUuid: role == 'tasks' ? oldNodeId : '$role-node',
                  ),
          workspaceReassignDesignatedInvoker:
              ({
                required caller,
                required workspaceId,
                required role,
                required newNodeUuid,
              }) async => const rust_api.WorkspaceActionResponse(
                ok: false,
                errorCode: 'db_busy',
                message: 'database is locked',
              ),
          workspaceGetAncestorPathInvoker:
              ({required caller, required nodeUuid}) async {
                if (nodeUuid == oldNodeId) {
                  return _ancestorResponse(oldParentId);
                }
                if (nodeUuid == newNodeId) {
                  return _ancestorResponse(newParentId);
                }
                return const rust_api.AncestorPathResponse(
                  ok: true,
                  message: 'ok',
                  segments: <rust_api.PathSegment>[],
                );
              },
        );

        await service.loadSystemNodes(workspaceId);
        final response = await service.reassignDesignated(
          workspaceId: workspaceId,
          role: 'tasks',
          newNodeUuid: newNodeId,
        );

        expect(response.ok, isFalse);
        expect(response.errorCode, 'db_busy');
        expect(response.message, contains('Retry in a moment.'));
        expect(service.workspaceNodeMutationErrorMessage, response.message);
        expect(service.getSystemNodeId(workspaceId, 'tasks'), oldNodeId);
        expect(service.lastMutation, isNull);
      },
    );

    test(
      'reassignDesignated preserves workspace_not_found when designated lookup fails',
      () async {
        final workspaceId = _uuid('workspace-missing');
        final service = _buildService(
          workspaceResolveDesignatedInvoker:
              ({required caller, required workspaceId, required role}) async =>
                  const rust_api.DesignatedFolderResponse(
                    ok: false,
                    errorCode: 'workspace_not_found',
                    message: 'workspace missing',
                  ),
        );

        final response = await service.reassignDesignated(
          workspaceId: workspaceId,
          role: 'tasks',
          newNodeUuid: _uuid('new-designated-c'),
        );

        expect(response.ok, isFalse);
        expect(response.errorCode, 'workspace_not_found');
        expect(response.message, contains('workspace missing'));
        expect(service.lastMutation, isNull);
      },
    );
  });
}

WorkspaceTreeService _buildService({
  WorkspaceCreateFolderInvoker? workspaceCreateFolderInvoker,
  WorkspaceDeleteFolderInvoker? workspaceDeleteFolderInvoker,
  WorkspaceRenameNodeInvoker? workspaceRenameNodeInvoker,
  WorkspaceMoveNodeInvoker? workspaceMoveNodeInvoker,
  WorkspaceResolveDesignatedInvoker? workspaceResolveDesignatedInvoker,
  WorkspaceReassignDesignatedInvoker? workspaceReassignDesignatedInvoker,
  WorkspaceGetDefaultInvoker? workspaceGetDefaultInvoker,
  WorkspaceGetAncestorPathInvoker? workspaceGetAncestorPathInvoker,
  WorkspaceCreateNoteAndGetAtomId? createNoteAndGetAtomId,
  WorkspacePrepare? prepare,
}) {
  return WorkspaceTreeService(
    workspaceDeleteFolderInvoker:
        workspaceDeleteFolderInvoker ??
        ({required nodeId, required mode}) async =>
            const rust_api.WorkspaceActionResponse(ok: true, message: 'ok'),
    workspaceCreateFolderInvoker:
        workspaceCreateFolderInvoker ??
        ({parentNodeId, required name}) async =>
            const rust_api.WorkspaceNodeResponse(ok: true, message: 'ok'),
    workspaceRenameNodeInvoker:
        workspaceRenameNodeInvoker ??
        ({required nodeId, required newName}) async =>
            const rust_api.WorkspaceActionResponse(ok: true, message: 'ok'),
    workspaceMoveNodeInvoker:
        workspaceMoveNodeInvoker ??
        ({required nodeId, newParentId, targetOrder}) async =>
            const rust_api.WorkspaceActionResponse(ok: true, message: 'ok'),
    workspaceListChildrenInvoker: ({parentNodeId}) async =>
        const rust_api.WorkspaceListChildrenResponse(
          ok: true,
          message: 'ok',
          items: <rust_api.WorkspaceNodeItem>[],
        ),
    workspaceResolveDesignatedInvoker:
        workspaceResolveDesignatedInvoker ??
        ({required caller, required workspaceId, required role}) async =>
            rust_api.DesignatedFolderResponse(
              ok: true,
              message: 'ok',
              nodeUuid: '$role-node',
            ),
    workspaceReassignDesignatedInvoker:
        workspaceReassignDesignatedInvoker ??
        ({
          required caller,
          required workspaceId,
          required role,
          required newNodeUuid,
        }) async =>
            const rust_api.WorkspaceActionResponse(ok: true, message: 'ok'),
    workspaceGetDefaultInvoker:
        workspaceGetDefaultInvoker ??
        ({required caller}) async => const rust_api.WorkspaceInfoResponse(
          ok: true,
          message: 'ok',
          workspace: rust_api.WorkspaceInfo(
            workspaceId: 'workspace-root',
            name: 'Default',
            isDefault: true,
          ),
        ),
    workspaceGetAncestorPathInvoker: workspaceGetAncestorPathInvoker,
    prepare: prepare ?? () async {},
    createNoteAndGetAtomId:
        createNoteAndGetAtomId ??
        ({parentNodeId}) async =>
            (atomId: 'atom-1', errorCode: null, errorMessage: null),
    flushPendingSave: () async => true,
    onDeleteSuccess: () async {},
    noteById: (_) => null,
    listItems: () => const <rust_api.AtomListItem>[],
  );
}

rust_api.AncestorPathResponse _ancestorResponse(String parentId) {
  return rust_api.AncestorPathResponse(
    ok: true,
    message: 'ok',
    segments: <rust_api.PathSegment>[
      rust_api.PathSegment(nodeUuid: parentId, displayName: 'Parent'),
    ],
  );
}

String _uuid(String seed) {
  final normalized = seed.codeUnits
      .map((unit) => unit.toRadixString(16).padLeft(2, '0'))
      .join()
      .padRight(32, '0')
      .substring(0, 32);
  return '${normalized.substring(0, 8)}-'
      '${normalized.substring(8, 12)}-'
      '4${normalized.substring(13, 16)}-'
      '8${normalized.substring(17, 20)}-'
      '${normalized.substring(20, 32)}';
}
