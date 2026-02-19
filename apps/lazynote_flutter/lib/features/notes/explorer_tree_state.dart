import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

/// Async loader for workspace tree children by parent id.
typedef ExplorerChildrenLoader =
    Future<rust_api.WorkspaceListChildrenResponse> Function({
      String? parentNodeId,
    });

/// In-memory lazy tree state for workspace explorer.
class ExplorerTreeState extends ChangeNotifier {
  ExplorerTreeState({required ExplorerChildrenLoader childrenLoader})
    : _childrenLoader = childrenLoader;

  final ExplorerChildrenLoader _childrenLoader;

  static const String _rootKey = '__root__';

  final Map<String, List<rust_api.WorkspaceNodeItem>> _childrenByParent =
      <String, List<rust_api.WorkspaceNodeItem>>{};
  final Set<String> _loadingParents = <String>{};
  final Map<String, String> _errorByParent = <String, String>{};
  final Set<String> _expandedFolders = <String>{};
  final Map<String, int> _requestVersionByParent = <String, int>{};

  /// Returns whether folder is expanded.
  bool isExpanded(String folderId) => _expandedFolders.contains(folderId);

  /// Returns whether parent children are loading.
  bool isLoading(String? parentNodeId) =>
      _loadingParents.contains(_parentKey(parentNodeId));

  /// Returns whether parent children were loaded at least once.
  bool hasLoaded(String? parentNodeId) =>
      _childrenByParent.containsKey(_parentKey(parentNodeId));

  /// Returns parent-level load error text when present.
  String? errorMessageFor(String? parentNodeId) =>
      _errorByParent[_parentKey(parentNodeId)];

  /// Returns loaded children for given parent (or null when not loaded yet).
  List<rust_api.WorkspaceNodeItem>? childrenFor(String? parentNodeId) =>
      _childrenByParent[_parentKey(parentNodeId)];

  /// Loads root children once.
  Future<void> loadRoot({bool force = false}) =>
      _loadChildren(parentNodeId: null, force: force);

  /// Reloads root and clears cached expansion/children state.
  Future<void> resetAndReloadRoot() async {
    _childrenByParent.clear();
    _loadingParents.clear();
    _errorByParent.clear();
    _expandedFolders.clear();
    _requestVersionByParent.clear();
    notifyListeners();
    await loadRoot(force: true);
  }

  /// Clears all cached tree state without triggering a reload.
  void clear() {
    _childrenByParent.clear();
    _loadingParents.clear();
    _errorByParent.clear();
    _expandedFolders.clear();
    _requestVersionByParent.clear();
    notifyListeners();
  }

  /// Expands/collapses one folder and lazy-loads children on first expansion.
  Future<void> toggleFolder(String folderId) async {
    if (_expandedFolders.remove(folderId)) {
      notifyListeners();
      return;
    }
    _expandedFolders.add(folderId);
    notifyListeners();
    if (!hasLoaded(folderId)) {
      await _loadChildren(parentNodeId: folderId, force: false);
    }
  }

  /// Expands one folder if currently collapsed.
  Future<void> ensureExpanded(String folderId) async {
    if (_expandedFolders.contains(folderId)) {
      return;
    }
    _expandedFolders.add(folderId);
    notifyListeners();
    if (!hasLoaded(folderId)) {
      await _loadChildren(parentNodeId: folderId, force: false);
    }
  }

  /// Retries loading one parent children branch.
  Future<void> retryParent(String? parentNodeId) =>
      _loadChildren(parentNodeId: parentNodeId, force: true);

  Future<void> _loadChildren({
    required String? parentNodeId,
    required bool force,
  }) async {
    final parentKey = _parentKey(parentNodeId);
    if (!force) {
      if (_loadingParents.contains(parentKey)) {
        return;
      }
      if (_childrenByParent.containsKey(parentKey)) {
        return;
      }
    }

    final requestVersion = (_requestVersionByParent[parentKey] ?? 0) + 1;
    _requestVersionByParent[parentKey] = requestVersion;
    _loadingParents.add(parentKey);
    _errorByParent.remove(parentKey);
    notifyListeners();

    try {
      final response = await _childrenLoader(parentNodeId: parentNodeId);
      if (_requestVersionByParent[parentKey] != requestVersion) {
        return;
      }

      if (!response.ok) {
        _errorByParent[parentKey] = _formatFailure(
          errorCode: response.errorCode,
          message: response.message,
        );
        return;
      }

      final sorted = List<rust_api.WorkspaceNodeItem>.from(response.items)
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          if (order != 0) {
            return order;
          }
          return a.nodeId.compareTo(b.nodeId);
        });
      _childrenByParent[parentKey] =
          List<rust_api.WorkspaceNodeItem>.unmodifiable(sorted);
      _errorByParent.remove(parentKey);
    } catch (error) {
      if (_requestVersionByParent[parentKey] != requestVersion) {
        return;
      }
      _errorByParent[parentKey] = 'Tree load failed unexpectedly: $error';
    } finally {
      if (_requestVersionByParent[parentKey] == requestVersion) {
        _loadingParents.remove(parentKey);
        notifyListeners();
      }
    }
  }

  String _parentKey(String? parentNodeId) => parentNodeId ?? _rootKey;

  String _formatFailure({required String? errorCode, required String message}) {
    final normalized = message.trim();
    if (errorCode == null || errorCode.trim().isEmpty) {
      return normalized.isEmpty ? 'Failed to load workspace tree.' : normalized;
    }
    if (normalized.isEmpty) {
      return '[$errorCode] Failed to load workspace tree.';
    }
    return '[$errorCode] $normalized';
  }
}
