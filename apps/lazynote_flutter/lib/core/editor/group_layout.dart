// Recursive pane split layout tree for the editor workbench.
//
// Implements DI-2 D5 binary tree model with immutable rebuild semantics.
// Invariants I1-I7 are enforced by construction and operation methods.
//
// PR-RB-06: First landing of core/editor/ infrastructure.
// Design sources: DI-2 D5/D6, S2 Phase 2, group-layout module spec.
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Axis;

// ---------------------------------------------------------------------------
// Layout tree nodes (sealed class hierarchy — I1: binary)
// ---------------------------------------------------------------------------

/// Base class for layout tree nodes.
sealed class LayoutNode {
  const LayoutNode();
}

/// Internal node: splits space between two children along [axis].
///
/// [fraction] ∈ (0.0, 1.0) exclusive — the share allocated to [first].
/// [second] gets the remaining `1 - fraction`.
@immutable
class SplitNode extends LayoutNode {
  const SplitNode({
    required this.first,
    required this.second,
    required this.axis,
    required this.fraction,
  }) : assert(
         fraction > 0.0 && fraction < 1.0,
         'fraction must be in (0.0, 1.0) exclusive',
       );

  final LayoutNode first;
  final LayoutNode second;
  final Axis axis;

  /// Share of space for [first]; ∈ (0.0, 1.0) exclusive (I3).
  final double fraction;
}

/// Leaf node: references one [EditorGroupModel] by [groupId].
@immutable
class LeafNode extends LayoutNode {
  const LeafNode({required this.groupId});

  final String groupId;
}

// ---------------------------------------------------------------------------
// Resolve result types
// ---------------------------------------------------------------------------

/// Position and tree path of a single drag divider.
@immutable
class DividerInfo {
  const DividerInfo({required this.rect, required this.path});

  /// Screen-space rect of the divider.
  final Rect rect;

  /// Tree path to the owning [SplitNode] (list of child indices: 0=first, 1=second).
  final List<int> path;
}

/// Output of [GroupLayout.resolve]: per-leaf rects + divider positions.
@immutable
class LayoutResolveResult {
  const LayoutResolveResult({required this.leafRects, required this.dividers});

  /// Pixel rect for each leaf, keyed by groupId.
  final Map<String, Rect> leafRects;

  /// Divider positions for drag-resize interaction.
  final List<DividerInfo> dividers;
}

// ---------------------------------------------------------------------------
// GroupLayout — immutable wrapper with operations
// ---------------------------------------------------------------------------

/// Maximum number of panes (DI-3 D9).
const int maxPaneCount = 8;

/// Minimum pixel extent per pane axis (I4).
const double minPaneExtent = 200.0;

/// Thickness of divider in resolve calculations.
const double dividerThickness = 4.0;

/// Immutable recursive pane layout tree.
///
/// All mutation methods return a new [GroupLayout] (immutable rebuild).
@immutable
class GroupLayout {
  const GroupLayout({required this.root});

  /// Root of the layout tree (I5: non-null, at least 1 node).
  final LayoutNode root;

  // ── Queries ──────────────────────────────────────────────────────────

  /// All leaf groupIds in the tree (I2: unique).
  Set<String> get allGroupIds {
    final result = <String>{};
    _collectGroupIds(root, result);
    return result;
  }

  static void _collectGroupIds(LayoutNode node, Set<String> out) {
    switch (node) {
      case LeafNode(:final groupId):
        out.add(groupId);
      case SplitNode(:final first, :final second):
        _collectGroupIds(first, out);
        _collectGroupIds(second, out);
    }
  }

  /// Checks whether [groupId] can be split along [axis] without violating
  /// the 8-pane limit or the 200×200 minimum size constraint.
  bool canSplit(String groupId, Axis axis, Size containerSize) {
    if (allGroupIds.length >= maxPaneCount) return false;
    final (candidateLayout, _) = split(groupId, axis);
    final result = candidateLayout.resolve(containerSize);
    return result.leafRects.values.every(
      (rect) => rect.width >= minPaneExtent && rect.height >= minPaneExtent,
    );
  }

  // ── Structural operations (immutable rebuild) ────────────────────────

  /// Splits the leaf with [groupId] into a [SplitNode] along [axis].
  ///
  /// Returns the new layout and the generated groupId for the new pane.
  /// The original leaf becomes [SplitNode.first]; the new leaf is [second].
  (GroupLayout, String) split(String groupId, Axis axis) {
    final newGroupId = _generateGroupId(groupId);
    final newRoot = _splitNode(root, groupId, axis, newGroupId);
    return (GroupLayout(root: newRoot), newGroupId);
  }

  /// Removes the leaf with [groupId], collapsing its parent [SplitNode]
  /// to the sibling node.
  ///
  /// If [groupId] is the only leaf (root), throws [StateError].
  GroupLayout closeGroup(String groupId) {
    if (root is LeafNode) {
      throw StateError('Cannot close the last remaining group');
    }
    final newRoot = _closeNode(root, groupId);
    return GroupLayout(root: newRoot);
  }

  /// Updates the [fraction] of the [SplitNode] at [path].
  ///
  /// [path] is a list of child indices (0=first, 1=second) from the root.
  /// An empty path targets the root node itself (which must be a SplitNode).
  GroupLayout resizeAt(List<int> path, double newFraction) {
    assert(
      newFraction > 0.0 && newFraction < 1.0,
      'newFraction must be in (0.0, 1.0) exclusive',
    );
    final newRoot = _resizeNode(root, path, 0, newFraction);
    return GroupLayout(root: newRoot);
  }

  // ── Resolve (DI-2 D6: top-down) ─────────────────────────────────────

  /// Resolves absolute pixel rects for all leaves and dividers.
  LayoutResolveResult resolve(Size containerSize) {
    final leafRects = <String, Rect>{};
    final dividers = <DividerInfo>[];
    _resolveNode(
      root,
      Rect.fromLTWH(0, 0, containerSize.width, containerSize.height),
      leafRects,
      dividers,
      const <int>[],
    );
    return LayoutResolveResult(leafRects: leafRects, dividers: dividers);
  }

  static void _resolveNode(
    LayoutNode node,
    Rect available,
    Map<String, Rect> leafRects,
    List<DividerInfo> dividers,
    List<int> currentPath,
  ) {
    switch (node) {
      case LeafNode(:final groupId):
        leafRects[groupId] = available;
      case SplitNode(:final first, :final second, :final axis, :final fraction):
        final double totalExtent;
        if (axis == Axis.horizontal) {
          totalExtent = available.width;
        } else {
          totalExtent = available.height;
        }
        final usable = totalExtent - dividerThickness;
        final firstExtent = usable * fraction;
        final secondExtent = usable * (1 - fraction);

        final Rect firstRect;
        final Rect dividerRect;
        final Rect secondRect;

        if (axis == Axis.horizontal) {
          firstRect = Rect.fromLTWH(
            available.left,
            available.top,
            firstExtent,
            available.height,
          );
          dividerRect = Rect.fromLTWH(
            available.left + firstExtent,
            available.top,
            dividerThickness,
            available.height,
          );
          secondRect = Rect.fromLTWH(
            available.left + firstExtent + dividerThickness,
            available.top,
            secondExtent,
            available.height,
          );
        } else {
          firstRect = Rect.fromLTWH(
            available.left,
            available.top,
            available.width,
            firstExtent,
          );
          dividerRect = Rect.fromLTWH(
            available.left,
            available.top + firstExtent,
            available.width,
            dividerThickness,
          );
          secondRect = Rect.fromLTWH(
            available.left,
            available.top + firstExtent + dividerThickness,
            available.width,
            secondExtent,
          );
        }

        dividers.add(DividerInfo(rect: dividerRect, path: currentPath));
        _resolveNode(first, firstRect, leafRects, dividers, [
          ...currentPath,
          0,
        ]);
        _resolveNode(second, secondRect, leafRects, dividers, [
          ...currentPath,
          1,
        ]);
    }
  }

  // ── Serialization (forward compat for PR-RB-07 DI-3) ────────────────

  /// Serializes the layout tree to JSON.
  Map<String, dynamic> toJson() {
    return {'schema_version': 1, 'root': _nodeToJson(root)};
  }

  /// Deserializes a layout tree from JSON.
  ///
  /// Throws [FormatException] on invalid/unsupported schema.
  static GroupLayout fromJson(Map<String, dynamic> json) {
    final version = json['schema_version'] as int?;
    if (version == null || version != 1) {
      throw const FormatException(
        'Unsupported or missing schema_version in GroupLayout JSON',
      );
    }
    final rootJson = json['root'] as Map<String, dynamic>;
    return GroupLayout(root: _nodeFromJson(rootJson));
  }

  static Map<String, dynamic> _nodeToJson(LayoutNode node) {
    switch (node) {
      case LeafNode(:final groupId):
        return {'type': 'leaf', 'groupId': groupId};
      case SplitNode(:final first, :final second, :final axis, :final fraction):
        return {
          'type': 'split',
          'axis': axis == Axis.horizontal ? 'horizontal' : 'vertical',
          'fraction': fraction,
          'first': _nodeToJson(first),
          'second': _nodeToJson(second),
        };
    }
  }

  static LayoutNode _nodeFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'leaf':
        return LeafNode(groupId: json['groupId'] as String);
      case 'split':
        final axisStr = json['axis'] as String;
        final axis = axisStr == 'horizontal' ? Axis.horizontal : Axis.vertical;
        final fraction = (json['fraction'] as num).toDouble();
        return SplitNode(
          first: _nodeFromJson(json['first'] as Map<String, dynamic>),
          second: _nodeFromJson(json['second'] as Map<String, dynamic>),
          axis: axis,
          fraction: fraction,
        );
      default:
        throw FormatException('Unknown LayoutNode type: $type');
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────

  static int _groupIdCounter = 0;

  static String _generateGroupId(String baseGroupId) {
    _groupIdCounter++;
    return 'group.$_groupIdCounter';
  }

  /// Resets the group ID counter. Only for testing.
  @visibleForTesting
  static void resetGroupIdCounter() {
    _groupIdCounter = 0;
  }

  static LayoutNode _splitNode(
    LayoutNode node,
    String targetGroupId,
    Axis axis,
    String newGroupId,
  ) {
    switch (node) {
      case LeafNode(:final groupId) when groupId == targetGroupId:
        return SplitNode(
          first: LeafNode(groupId: groupId),
          second: LeafNode(groupId: newGroupId),
          axis: axis,
          fraction: 0.5,
        );
      case LeafNode():
        return node;
      case SplitNode(:final first, :final second, :final axis, :final fraction):
        final newFirst = _splitNode(first, targetGroupId, axis, newGroupId);
        if (!identical(newFirst, first)) {
          return SplitNode(
            first: newFirst,
            second: second,
            axis: axis,
            fraction: fraction,
          );
        }
        final newSecond = _splitNode(second, targetGroupId, axis, newGroupId);
        if (!identical(newSecond, second)) {
          return SplitNode(
            first: first,
            second: newSecond,
            axis: axis,
            fraction: fraction,
          );
        }
        return node;
    }
  }

  static LayoutNode _closeNode(LayoutNode node, String targetGroupId) {
    switch (node) {
      case LeafNode():
        throw StateError('Group $targetGroupId not found in layout tree');
      case SplitNode(:final first, :final second, :final axis, :final fraction):
        // Check if direct child is the target leaf
        if (first case LeafNode(:final groupId) when groupId == targetGroupId) {
          return second;
        }
        if (second case LeafNode(
          :final groupId,
        ) when groupId == targetGroupId) {
          return first;
        }
        // Recurse into children
        final newFirst = _tryCloseNode(first, targetGroupId);
        if (newFirst != null) {
          return SplitNode(
            first: newFirst,
            second: second,
            axis: axis,
            fraction: fraction,
          );
        }
        final newSecond = _tryCloseNode(second, targetGroupId);
        if (newSecond != null) {
          return SplitNode(
            first: first,
            second: newSecond,
            axis: axis,
            fraction: fraction,
          );
        }
        throw StateError('Group $targetGroupId not found in layout tree');
    }
  }

  /// Returns the rebuilt subtree if [targetGroupId] was found and closed,
  /// or null if the target was not in this subtree.
  static LayoutNode? _tryCloseNode(LayoutNode node, String targetGroupId) {
    switch (node) {
      case LeafNode():
        return null;
      case SplitNode(:final first, :final second, :final axis, :final fraction):
        if (first case LeafNode(:final groupId) when groupId == targetGroupId) {
          return second;
        }
        if (second case LeafNode(
          :final groupId,
        ) when groupId == targetGroupId) {
          return first;
        }
        final newFirst = _tryCloseNode(first, targetGroupId);
        if (newFirst != null) {
          return SplitNode(
            first: newFirst,
            second: second,
            axis: axis,
            fraction: fraction,
          );
        }
        final newSecond = _tryCloseNode(second, targetGroupId);
        if (newSecond != null) {
          return SplitNode(
            first: first,
            second: newSecond,
            axis: axis,
            fraction: fraction,
          );
        }
        return null;
    }
  }

  static LayoutNode _resizeNode(
    LayoutNode node,
    List<int> path,
    int depth,
    double newFraction,
  ) {
    if (depth == path.length) {
      if (node is! SplitNode) {
        throw StateError('Path targets a LeafNode, not a SplitNode');
      }
      return SplitNode(
        first: node.first,
        second: node.second,
        axis: node.axis,
        fraction: newFraction,
      );
    }
    if (node is! SplitNode) {
      throw StateError('Path is deeper than tree structure');
    }
    final direction = path[depth];
    if (direction == 0) {
      return SplitNode(
        first: _resizeNode(node.first, path, depth + 1, newFraction),
        second: node.second,
        axis: node.axis,
        fraction: node.fraction,
      );
    } else {
      return SplitNode(
        first: node.first,
        second: _resizeNode(node.second, path, depth + 1, newFraction),
        axis: node.axis,
        fraction: node.fraction,
      );
    }
  }
}
