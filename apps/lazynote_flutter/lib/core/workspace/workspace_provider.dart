// TRANSIENT: This file is temporarily in lib/core/workspace/.
// PR-RB-06 will absorb its layout logic into lib/core/editor/group_layout.dart.
// See: DI-1 Q5, S2 Phase 2, PR-RB-06 T15.

import 'package:flutter/foundation.dart';
import 'package:lazynote_flutter/core/workspace/workspace_models.dart';

/// Workspace pane layout owner.
///
/// After PR-0258 this class manages pane split/merge layout only.
/// Tab, draft, and save state are owned by NotesCoordinator and its managers.
class WorkspaceProvider extends ChangeNotifier {
  /// Hard cap for v0.2 non-recursive split baseline.
  static const int maxPaneCount = 4;

  /// Minimum pixel size for each pane after split.
  static const double minPaneExtent = 200;

  WorkspaceProvider() {
    _activePaneId = _layoutState.primaryPaneId;
  }

  WorkspaceLayoutState _layoutState = WorkspaceLayoutState.singlePane();
  late String _activePaneId;
  int _nextPaneSequence = 1;

  /// Current workspace layout snapshot.
  WorkspaceLayoutState get layoutState => _layoutState;

  /// Active pane identifier.
  String get activePaneId => _activePaneId;

  /// Switches the active pane pointer.
  void switchActivePane(String paneId) {
    if (_activePaneId == paneId) {
      return;
    }
    if (!_layoutState.paneOrder.contains(paneId)) {
      return;
    }
    _activePaneId = paneId;
    notifyListeners();
  }

  /// Splits the active pane in root layout (v0.2 non-recursive baseline).
  ///
  /// The caller should pass the available size in the split axis:
  /// - horizontal: content width
  /// - vertical: content height
  WorkspaceSplitResult splitActivePane({
    required WorkspaceSplitDirection direction,
    required double containerExtent,
  }) {
    final paneOrder = _layoutState.paneOrder;
    final paneCount = paneOrder.length;
    if (paneCount >= maxPaneCount) {
      return WorkspaceSplitResult.maxPanesReached;
    }
    final activeIndex = paneOrder.indexOf(_activePaneId);
    if (activeIndex < 0) {
      return WorkspaceSplitResult.paneNotFound;
    }
    if (paneCount > 1 && _layoutState.splitDirection != direction) {
      return WorkspaceSplitResult.directionLocked;
    }
    if (!_hasMinExtentForPaneCount(
      paneCount: paneCount + 1,
      containerExtent: containerExtent,
    )) {
      return WorkspaceSplitResult.minSizeBlocked;
    }

    final nextOrder = List<String>.from(_layoutState.paneOrder);
    final nextFractions = List<double>.from(_layoutState.paneFractions);
    final activeFraction = nextFractions[activeIndex];
    final splitFraction = activeFraction / 2;
    final newPaneId = _newPaneId();
    nextOrder.insert(activeIndex + 1, newPaneId);
    nextFractions[activeIndex] = splitFraction;
    nextFractions.insert(activeIndex + 1, splitFraction);

    if (!_hasMinExtentForFractions(
      paneFractions: nextFractions,
      containerExtent: containerExtent,
    )) {
      return WorkspaceSplitResult.minSizeBlocked;
    }

    _layoutState = _layoutState.copyWith(
      paneOrder: nextOrder,
      paneFractions: _normalizeFractions(nextFractions),
      splitDirection: direction,
    );
    _activePaneId = newPaneId;
    notifyListeners();
    return WorkspaceSplitResult.ok;
  }

  /// Closes current active pane and merges it into adjacent pane.
  ///
  /// Merge target policy:
  /// - prefer previous pane in layout order
  /// - when closing first pane, use next pane
  WorkspaceMergeResult closeActivePane() {
    final paneOrder = _layoutState.paneOrder;
    if (paneOrder.length <= 1) {
      return WorkspaceMergeResult.singlePaneBlocked;
    }

    final closingPaneId = _activePaneId;
    final closingIndex = paneOrder.indexOf(closingPaneId);
    if (closingIndex < 0) {
      return WorkspaceMergeResult.paneNotFound;
    }

    final targetIndex = closingIndex > 0 ? closingIndex - 1 : 1;
    final targetPaneId = paneOrder[targetIndex];
    _activePaneId = targetPaneId;

    final nextOrder = List<String>.from(paneOrder)..removeAt(closingIndex);
    final nextFractions = List<double>.from(_layoutState.paneFractions)
      ..removeAt(closingIndex);
    _layoutState = _layoutState.copyWith(
      paneOrder: nextOrder,
      paneFractions: _normalizeFractions(nextFractions),
    );
    notifyListeners();
    return WorkspaceMergeResult.ok;
  }

  String _newPaneId() {
    while (true) {
      final paneId = 'pane.split.$_nextPaneSequence';
      _nextPaneSequence += 1;
      if (!_layoutState.paneOrder.contains(paneId)) {
        return paneId;
      }
    }
  }

  static bool _hasMinExtentForPaneCount({
    required int paneCount,
    required double containerExtent,
  }) {
    if (!containerExtent.isFinite || containerExtent <= 0) {
      return false;
    }
    return containerExtent >= (paneCount * minPaneExtent);
  }

  static bool _hasMinExtentForFractions({
    required List<double> paneFractions,
    required double containerExtent,
  }) {
    for (final fraction in paneFractions) {
      if ((fraction * containerExtent) < minPaneExtent) {
        return false;
      }
    }
    return true;
  }

  static List<double> _normalizeFractions(List<double> paneFractions) {
    final sum = paneFractions.fold<double>(0, (total, item) => total + item);
    if (sum == 0) {
      return paneFractions;
    }
    return paneFractions.map((item) => item / sum).toList(growable: false);
  }
}
