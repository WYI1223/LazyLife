import 'dart:async';
import 'dart:collection';

import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

typedef WorkspaceChildrenPrepare = Future<void> Function();

typedef WorkspaceChildrenListInvoker =
    Future<rust_api.WorkspaceListChildrenResponse> Function({
      String? parentNodeId,
    });

typedef WorkspaceChildrenNoteById =
    rust_api.AtomListItem? Function(String atomId);

typedef WorkspaceChildrenItemsReader = List<rust_api.AtomListItem> Function();

class WorkspaceTreeChildrenLoader {
  static const String uncategorizedFolderNodeId = '__uncategorized__';
  static const String uncategorizedFolderDisplayName = 'Uncategorized';

  WorkspaceTreeChildrenLoader({
    required WorkspaceChildrenPrepare prepare,
    required WorkspaceChildrenListInvoker listChildrenInvoker,
    required WorkspaceChildrenNoteById noteById,
    required WorkspaceChildrenItemsReader listItems,
  }) : _prepare = prepare,
       _listChildrenInvoker = listChildrenInvoker,
       _noteById = noteById,
       _listItems = listItems;

  final WorkspaceChildrenPrepare _prepare;
  final WorkspaceChildrenListInvoker _listChildrenInvoker;
  final WorkspaceChildrenNoteById _noteById;
  final WorkspaceChildrenItemsReader _listItems;

  Future<rust_api.WorkspaceListChildrenResponse> listWorkspaceChildren({
    String? parentNodeId,
  }) async {
    if (parentNodeId == uncategorizedFolderNodeId) {
      return _listProjectedUncategorizedChildren();
    }
    try {
      await _prepare();
      final response = await _listChildrenInvoker(parentNodeId: parentNodeId);
      return _decorateWorkspaceChildren(
        parentNodeId: parentNodeId,
        response: response,
      );
    } catch (error) {
      if (_shouldUseWorkspaceTreeSyntheticFallback(error)) {
        return _fallbackWorkspaceChildren(parentNodeId: parentNodeId);
      }
      return rust_api.WorkspaceListChildrenResponse(
        ok: false,
        errorCode: 'internal_error',
        message: 'Workspace tree load failed unexpectedly: $error',
        items: const <rust_api.WorkspaceNodeItem>[],
      );
    }
  }

  rust_api.WorkspaceListChildrenResponse _decorateWorkspaceChildren({
    required String? parentNodeId,
    required rust_api.WorkspaceListChildrenResponse response,
  }) {
    if (!response.ok || parentNodeId != null) {
      return response;
    }
    final items = response.items
        .where((item) => item.kind != 'note_ref')
        .toList(growable: true);
    final hasUncategorized = items.any(
      (item) =>
          item.kind == 'folder' && item.nodeId == uncategorizedFolderNodeId,
    );
    if (!hasUncategorized) {
      items.insert(
        0,
        const rust_api.WorkspaceNodeItem(
          nodeId: uncategorizedFolderNodeId,
          kind: 'folder',
          parentNodeId: null,
          atomId: null,
          displayName: uncategorizedFolderDisplayName,
          sortOrder: -1,
        ),
      );
    }
    return rust_api.WorkspaceListChildrenResponse(
      ok: response.ok,
      errorCode: response.errorCode,
      message: response.message,
      items: items,
    );
  }

  Future<rust_api.WorkspaceListChildrenResponse>
  _listProjectedUncategorizedChildren() async {
    try {
      await _prepare();
      final referencedAtomIds = <String>{};
      final visitedFolderIds = <String>{};
      final pendingParentIds = Queue<String?>()..add(null);
      List<rust_api.WorkspaceNodeItem>? rootItems;

      while (pendingParentIds.isNotEmpty) {
        final parentNodeId = pendingParentIds.removeFirst();
        final response = await _listChildrenInvoker(parentNodeId: parentNodeId);
        if (!response.ok) {
          return rust_api.WorkspaceListChildrenResponse(
            ok: false,
            errorCode: response.errorCode,
            message: response.message,
            items: const <rust_api.WorkspaceNodeItem>[],
          );
        }
        if (parentNodeId == null) {
          rootItems = response.items;
        }
        for (final item in response.items) {
          if (item.kind == 'note_ref') {
            final atomId = item.atomId?.trim();
            if (atomId != null && atomId.isNotEmpty) {
              referencedAtomIds.add(atomId);
            }
            continue;
          }
          if (item.kind != 'folder') {
            continue;
          }
          final folderId = item.nodeId.trim();
          if (folderId.isEmpty || folderId == uncategorizedFolderNodeId) {
            continue;
          }
          if (visitedFolderIds.add(folderId)) {
            pendingParentIds.add(folderId);
          }
        }
      }

      final projectedRows = <_ProjectedUncategorizedRow>[];
      final projectedAtomIds = <String>{};
      for (final item in rootItems ?? const <rust_api.WorkspaceNodeItem>[]) {
        if (item.kind != 'note_ref') {
          continue;
        }
        final atomId = item.atomId?.trim();
        if (atomId == null || atomId.isEmpty) {
          continue;
        }
        if (!projectedAtomIds.add(atomId)) {
          continue;
        }
        final note = _noteById(atomId);
        final projectedDisplayName = note == null
            ? (item.displayName.trim().isEmpty ? 'Untitled' : item.displayName)
            : note.title.isNotEmpty
            ? note.title
            : 'Untitled';
        projectedRows.add(
          _ProjectedUncategorizedRow(
            nodeId: item.nodeId,
            atomId: atomId,
            displayName: projectedDisplayName,
            updatedAt: note?.updatedAt ?? 0,
          ),
        );
      }

      for (final note in _listItems()) {
        final atomId = note.atomId.trim();
        if (atomId.isEmpty || referencedAtomIds.contains(atomId)) {
          continue;
        }
        if (!projectedAtomIds.add(atomId)) {
          continue;
        }
        projectedRows.add(
          _ProjectedUncategorizedRow(
            nodeId: 'note_ref_uncategorized_${note.atomId}',
            atomId: atomId,
            displayName: note.title.isNotEmpty ? note.title : 'Untitled',
            updatedAt: note.updatedAt,
          ),
        );
      }

      projectedRows.sort(_compareProjectedUncategorizedRow);
      final projectedItems = <rust_api.WorkspaceNodeItem>[];
      for (var index = 0; index < projectedRows.length; index += 1) {
        final row = projectedRows[index];
        projectedItems.add(
          rust_api.WorkspaceNodeItem(
            nodeId: row.nodeId,
            kind: 'note_ref',
            parentNodeId: uncategorizedFolderNodeId,
            atomId: row.atomId,
            displayName: row.displayName,
            sortOrder: index,
          ),
        );
      }
      return rust_api.WorkspaceListChildrenResponse(
        ok: true,
        errorCode: null,
        message: 'synthetic_uncategorized',
        items: projectedItems,
      );
    } catch (error) {
      if (_shouldUseWorkspaceTreeSyntheticFallback(error)) {
        return _legacySyntheticUncategorizedChildren();
      }
      return rust_api.WorkspaceListChildrenResponse(
        ok: false,
        errorCode: 'internal_error',
        message: 'Workspace tree load failed unexpectedly: $error',
        items: const <rust_api.WorkspaceNodeItem>[],
      );
    }
  }

  rust_api.WorkspaceListChildrenResponse
  _legacySyntheticUncategorizedChildren() {
    final items = <rust_api.WorkspaceNodeItem>[];
    final sortedNotes = List<rust_api.AtomListItem>.from(_listItems())
      ..sort((left, right) {
        final byUpdated = right.updatedAt.compareTo(left.updatedAt);
        if (byUpdated != 0) {
          return byUpdated;
        }
        return left.atomId.compareTo(right.atomId);
      });
    for (var index = 0; index < sortedNotes.length; index += 1) {
      final note = sortedNotes[index];
      items.add(
        rust_api.WorkspaceNodeItem(
          nodeId: 'note_ref_uncategorized_${note.atomId}',
          kind: 'note_ref',
          parentNodeId: uncategorizedFolderNodeId,
          atomId: note.atomId,
          displayName: note.title.isNotEmpty ? note.title : 'Untitled',
          sortOrder: index,
        ),
      );
    }
    return rust_api.WorkspaceListChildrenResponse(
      ok: true,
      errorCode: null,
      message: 'synthetic_uncategorized_legacy',
      items: items,
    );
  }

  rust_api.WorkspaceListChildrenResponse _fallbackWorkspaceChildren({
    String? parentNodeId,
  }) {
    if (parentNodeId == null) {
      final rootItems = <rust_api.WorkspaceNodeItem>[
        const rust_api.WorkspaceNodeItem(
          nodeId: uncategorizedFolderNodeId,
          kind: 'folder',
          parentNodeId: null,
          atomId: null,
          displayName: uncategorizedFolderDisplayName,
          sortOrder: -1,
        ),
        const rust_api.WorkspaceNodeItem(
          nodeId: 'projects',
          kind: 'folder',
          parentNodeId: null,
          atomId: null,
          displayName: 'Projects',
          sortOrder: 0,
        ),
        const rust_api.WorkspaceNodeItem(
          nodeId: 'notes',
          kind: 'folder',
          parentNodeId: null,
          atomId: null,
          displayName: 'Notes',
          sortOrder: 1,
        ),
        const rust_api.WorkspaceNodeItem(
          nodeId: 'personal',
          kind: 'folder',
          parentNodeId: null,
          atomId: null,
          displayName: 'Personal',
          sortOrder: 2,
        ),
      ];
      return rust_api.WorkspaceListChildrenResponse(
        ok: true,
        errorCode: null,
        message: 'fallback',
        items: rootItems,
      );
    }

    if (parentNodeId == 'notes') {
      final noteItems = <rust_api.WorkspaceNodeItem>[];
      var order = 0;
      for (final item in _listItems()) {
        noteItems.add(
          rust_api.WorkspaceNodeItem(
            nodeId: 'note_ref_notes_${item.atomId}',
            kind: 'note_ref',
            parentNodeId: 'notes',
            atomId: item.atomId,
            displayName: item.title.isNotEmpty ? item.title : 'Untitled',
            sortOrder: order,
          ),
        );
        order += 1;
      }
      return rust_api.WorkspaceListChildrenResponse(
        ok: true,
        errorCode: null,
        message: 'fallback',
        items: noteItems,
      );
    }

    return const rust_api.WorkspaceListChildrenResponse(
      ok: true,
      errorCode: null,
      message: 'fallback',
      items: <rust_api.WorkspaceNodeItem>[],
    );
  }

  bool _shouldUseWorkspaceTreeSyntheticFallback(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('missingpluginexception')) {
      return true;
    }
    final mentionsRustBridge =
        text.contains('rustlib') ||
        text.contains('rust bridge') ||
        text.contains('no implementation found for method');
    final looksLikeInitGap =
        text.contains('not initialized') ||
        text.contains('initialize') ||
        text.contains('init');
    return mentionsRustBridge && looksLikeInitGap;
  }
}

class _ProjectedUncategorizedRow {
  const _ProjectedUncategorizedRow({
    required this.nodeId,
    required this.atomId,
    required this.displayName,
    required this.updatedAt,
  });

  final String nodeId;
  final String atomId;
  final String displayName;
  final int updatedAt;
}

int _compareProjectedUncategorizedRow(
  _ProjectedUncategorizedRow left,
  _ProjectedUncategorizedRow right,
) {
  final byUpdatedAt = right.updatedAt.compareTo(left.updatedAt);
  if (byUpdatedAt != 0) {
    return byUpdatedAt;
  }
  final byAtomId = left.atomId.compareTo(right.atomId);
  if (byAtomId != 0) {
    return byAtomId;
  }
  return left.nodeId.compareTo(right.nodeId);
}
