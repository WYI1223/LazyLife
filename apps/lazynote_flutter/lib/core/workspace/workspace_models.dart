// TRANSIENT: This file is temporarily in lib/core/workspace/.
// PR-RB-06 will absorb its layout logic into lib/core/editor/group_layout.dart.
// See: DI-1 Q5, S2 Phase 2, PR-RB-06 T15.

import 'package:flutter/foundation.dart';

/// Root split orientation for v0.2 non-recursive layout.
enum WorkspaceSplitDirection { horizontal, vertical }

/// Stable result codes for split command handling.
enum WorkspaceSplitResult {
  ok,
  paneNotFound,
  maxPanesReached,
  directionLocked,
  minSizeBlocked,
}

/// Stable result codes for close-pane merge command handling.
enum WorkspaceMergeResult { ok, singlePaneBlocked, paneNotFound }

/// Minimal layout state shape kept split-ready for v0.2/v0.3.
@immutable
class WorkspaceLayoutState {
  /// Creates one immutable workspace layout snapshot.
  WorkspaceLayoutState({
    required List<String> paneOrder,
    required List<double> paneFractions,
    required this.splitDirection,
    required this.primaryPaneId,
  }) : paneOrder = List.unmodifiable(List<String>.from(paneOrder)),
       paneFractions = List.unmodifiable(List<double>.from(paneFractions));

  /// Ordered pane ids from left to right.
  final List<String> paneOrder;

  /// Relative pane size fractions aligned with [paneOrder].
  final List<double> paneFractions;

  /// Root split orientation for current pane set.
  final WorkspaceSplitDirection splitDirection;

  /// Default pane for single-pane baseline.
  final String primaryPaneId;

  /// Returns the baseline single-pane layout used by current UI.
  factory WorkspaceLayoutState.singlePane() {
    return WorkspaceLayoutState(
      paneOrder: <String>['pane.primary'],
      paneFractions: <double>[1.0],
      splitDirection: WorkspaceSplitDirection.horizontal,
      primaryPaneId: 'pane.primary',
    );
  }

  /// Returns one copied layout snapshot with selective field updates.
  WorkspaceLayoutState copyWith({
    List<String>? paneOrder,
    List<double>? paneFractions,
    WorkspaceSplitDirection? splitDirection,
    String? primaryPaneId,
  }) {
    return WorkspaceLayoutState(
      paneOrder: paneOrder ?? this.paneOrder,
      paneFractions: paneFractions ?? this.paneFractions,
      splitDirection: splitDirection ?? this.splitDirection,
      primaryPaneId: primaryPaneId ?? this.primaryPaneId,
    );
  }
}
