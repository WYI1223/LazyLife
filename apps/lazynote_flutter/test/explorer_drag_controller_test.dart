import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/explorer_drag_controller.dart';

rust_api.WorkspaceNodeItem _node({
  required String nodeId,
  required String kind,
  String? parentNodeId,
  String? atomId,
  int sortOrder = 0,
}) {
  return rust_api.WorkspaceNodeItem(
    nodeId: nodeId,
    kind: kind,
    parentNodeId: parentNodeId,
    atomId: atomId,
    displayName: nodeId,
    sortOrder: sortOrder,
  );
}

void main() {
  final controller = ExplorerDragController();
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String? normalizeParent(String? parentNodeId) {
    final normalized = parentNodeId?.trim();
    if (normalized == null ||
        normalized.isEmpty ||
        normalized == '__root__' ||
        normalized == '__uncategorized__') {
      return null;
    }
    return normalized;
  }

  bool isStableNodeId(String nodeId) => uuid.hasMatch(nodeId.trim());

  bool isSyntheticRootNodeId(String nodeId) =>
      nodeId.trim() == '__uncategorized__';

  test('same-parent drop is rejected', () {
    const parentId = '11111111-1111-4111-8111-111111111111';
    const nodeA = '22222222-2222-4222-8222-222222222222';
    const nodeB = '33333333-3333-4333-8333-333333333333';

    final plan = controller.planForRowDrop(
      payload: const ExplorerDragPayload(
        nodeId: nodeB,
        kind: 'note_ref',
        sourceParentNodeId: parentId,
      ),
      targetNode: _node(
        nodeId: nodeA,
        kind: 'note_ref',
        parentNodeId: parentId,
        atomId: 'note-a',
      ),
      normalizeParent: normalizeParent,
      isStableNodeId: isStableNodeId,
      isSyntheticRootNodeId: isSyntheticRootNodeId,
    );

    expect(plan, isNull);
  });

  test('cross-parent drop onto folder resolves move-to-folder plan', () {
    const sourceParent = '11111111-1111-4111-8111-111111111111';
    const targetFolder = '22222222-2222-4222-8222-222222222222';
    const noteRef = '33333333-3333-4333-8333-333333333333';

    final plan = controller.planForRowDrop(
      payload: const ExplorerDragPayload(
        nodeId: noteRef,
        kind: 'note_ref',
        sourceParentNodeId: sourceParent,
      ),
      targetNode: _node(nodeId: targetFolder, kind: 'folder'),
      normalizeParent: normalizeParent,
      isStableNodeId: isStableNodeId,
      isSyntheticRootNodeId: isSyntheticRootNodeId,
    );

    expect(plan, isNotNull);
    expect(plan!.newParentNodeId, targetFolder);
  });

  test('drop onto child folder under same parent is allowed', () {
    const parentId = '11111111-1111-4111-8111-111111111111';
    const childFolder = '22222222-2222-4222-8222-222222222222';
    const noteRef = '33333333-3333-4333-8333-333333333333';

    final plan = controller.planForRowDrop(
      payload: const ExplorerDragPayload(
        nodeId: noteRef,
        kind: 'note_ref',
        sourceParentNodeId: parentId,
      ),
      targetNode: _node(
        nodeId: childFolder,
        kind: 'folder',
        parentNodeId: parentId,
      ),
      normalizeParent: normalizeParent,
      isStableNodeId: isStableNodeId,
      isSyntheticRootNodeId: isSyntheticRootNodeId,
    );

    expect(plan, isNotNull);
    expect(plan!.newParentNodeId, childFolder);
  });

  test('same-parent cross-kind drop is rejected', () {
    const parentId = '11111111-1111-4111-8111-111111111111';
    const folderNode = '22222222-2222-4222-8222-222222222222';
    const noteRef = '33333333-3333-4333-8333-333333333333';

    final plan = controller.planForRowDrop(
      payload: const ExplorerDragPayload(
        nodeId: folderNode,
        kind: 'folder',
        sourceParentNodeId: parentId,
      ),
      targetNode: _node(
        nodeId: noteRef,
        kind: 'note_ref',
        parentNodeId: parentId,
        atomId: 'note-a',
      ),
      normalizeParent: normalizeParent,
      isStableNodeId: isStableNodeId,
      isSyntheticRootNodeId: isSyntheticRootNodeId,
    );

    expect(plan, isNull);
  });

  test('root-lane drop is rejected when source already at root', () {
    const payload = ExplorerDragPayload(
      nodeId: '33333333-3333-4333-8333-333333333333',
      kind: 'note_ref',
      sourceParentNodeId: null,
    );
    expect(controller.planForRootDrop(payload: payload), isNull);
  });
}
