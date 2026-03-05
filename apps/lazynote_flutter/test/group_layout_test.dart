import 'dart:ui';

import 'package:flutter/widgets.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/group_layout.dart';

void main() {
  setUp(() => GroupLayout.resetGroupIdCounter());

  // ---------------------------------------------------------------------------
  // Split correctness
  // ---------------------------------------------------------------------------

  group('split', () {
    test('split produces SplitNode with correct axis and 0.5 fraction', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (newLayout, newId) = layout.split('g0', Axis.horizontal);

      final root = newLayout.root as SplitNode;
      expect(root.axis, Axis.horizontal);
      expect(root.fraction, 0.5);
      expect((root.first as LeafNode).groupId, 'g0');
      expect((root.second as LeafNode).groupId, newId);
    });

    test('split vertical produces vertical axis', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (newLayout, _) = layout.split('g0', Axis.vertical);

      final root = newLayout.root as SplitNode;
      expect(root.axis, Axis.vertical);
    });

    test('split generates unique group IDs', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (layout2, id1) = layout.split('g0', Axis.horizontal);
      final (_, id2) = layout2.split('g0', Axis.vertical);

      expect(id1, isNot(equals(id2)));
    });

    test('split non-existent groupId returns unchanged layout', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (newLayout, _) = layout.split('nonexistent', Axis.horizontal);

      // Root is still a leaf since target wasn't found
      expect(newLayout.root, isA<LeafNode>());
    });
  });

  // ---------------------------------------------------------------------------
  // Close correctness
  // ---------------------------------------------------------------------------

  group('closeGroup', () {
    test('close collapses SplitNode to sibling', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, newId) = layout.split('g0', Axis.horizontal);

      final closed = splitLayout.closeGroup(newId);
      expect(closed.root, isA<LeafNode>());
      expect((closed.root as LeafNode).groupId, 'g0');
    });

    test('close first child promotes second child', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, _) = layout.split('g0', Axis.horizontal);

      final closed = splitLayout.closeGroup('g0');
      expect(closed.root, isA<LeafNode>());
      // Second child promoted to root
    });

    test('close last remaining group throws StateError (I1)', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      expect(() => layout.closeGroup('g0'), throwsStateError);
    });

    test('close non-existent groupId throws StateError', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, _) = layout.split('g0', Axis.horizontal);
      expect(() => splitLayout.closeGroup('nonexistent'), throwsStateError);
    });
  });

  // ---------------------------------------------------------------------------
  // allGroupIds traversal
  // ---------------------------------------------------------------------------

  group('allGroupIds', () {
    test('single leaf returns one ID', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      expect(layout.allGroupIds, {'g0'});
    });

    test('after split returns both IDs', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, newId) = layout.split('g0', Axis.horizontal);
      expect(splitLayout.allGroupIds, {'g0', newId});
    });

    test('deep nesting returns all leaf IDs', () {
      var layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final ids = <String>{'g0'};

      // Build 4-pane layout: g0 → split → split → split
      final (l1, id1) = layout.split('g0', Axis.horizontal);
      ids.add(id1);
      layout = l1;

      final (l2, id2) = layout.split('g0', Axis.vertical);
      ids.add(id2);
      layout = l2;

      final (l3, id3) = layout.split(id1, Axis.horizontal);
      ids.add(id3);
      layout = l3;

      expect(layout.allGroupIds, ids);
      expect(layout.allGroupIds.length, 4);
    });
  });

  // ---------------------------------------------------------------------------
  // Deep nesting (4+ pane)
  // ---------------------------------------------------------------------------

  group('deep nesting', () {
    test('4-pane layout resolves all leaf rects', () {
      var layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (l1, id1) = layout.split('g0', Axis.horizontal);
      layout = l1;
      final (l2, id2) = layout.split('g0', Axis.vertical);
      layout = l2;
      final (l3, id3) = layout.split(id1, Axis.vertical);
      layout = l3;

      final result = layout.resolve(const Size(1000, 800));
      expect(result.leafRects.length, 4);
      expect(result.leafRects.keys, containsAll(['g0', id1, id2, id3]));

      // All rects have positive dimensions
      for (final rect in result.leafRects.values) {
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
    });

    test('divider count equals split count', () {
      var layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (l1, _) = layout.split('g0', Axis.horizontal);
      layout = l1;
      final (l2, _) = layout.split('g0', Axis.vertical);
      layout = l2;

      final result = layout.resolve(const Size(1000, 800));
      // 3 leaves = 2 splits = 2 dividers
      expect(result.dividers.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // Rapid split/close sequence
  // ---------------------------------------------------------------------------

  group('rapid split/close sequence', () {
    test('split then immediately close restores original topology', () {
      final original = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (split1, id1) = original.split('g0', Axis.horizontal);
      final restored = split1.closeGroup(id1);

      expect(restored.allGroupIds, {'g0'});
      expect(restored.root, isA<LeafNode>());
    });

    test('multiple split/close cycles maintain invariants', () {
      var layout = GroupLayout(root: LeafNode(groupId: 'g0'));

      // Split → close → split → close
      for (var i = 0; i < 5; i++) {
        final (splitLayout, newId) = layout.split('g0', Axis.horizontal);
        expect(splitLayout.allGroupIds.length, 2);
        layout = splitLayout.closeGroup(newId);
        expect(layout.allGroupIds.length, 1);
      }

      expect(layout.allGroupIds, {'g0'});
    });
  });

  // ---------------------------------------------------------------------------
  // Resize
  // ---------------------------------------------------------------------------

  group('resizeAt', () {
    test('resize updates fraction at root SplitNode', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, _) = layout.split('g0', Axis.horizontal);

      final resized = splitLayout.resizeAt(const [], 0.3);
      final root = resized.root as SplitNode;
      expect(root.fraction, 0.3);
    });

    test('resize rejects out-of-bound fraction via assertion', () {
      final layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, _) = layout.split('g0', Axis.horizontal);

      expect(
        () => splitLayout.resizeAt(const [], 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => splitLayout.resizeAt(const [], 1.0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Serialization round-trip
  // ---------------------------------------------------------------------------

  group('serialization', () {
    test('toJson/fromJson round-trip preserves structure', () {
      var layout = GroupLayout(root: LeafNode(groupId: 'g0'));
      final (splitLayout, _) = layout.split('g0', Axis.horizontal);
      final (deepLayout, _) = splitLayout.split('g0', Axis.vertical);

      final json = deepLayout.toJson();
      final restored = GroupLayout.fromJson(json);

      expect(restored.allGroupIds, deepLayout.allGroupIds);
    });

    test('fromJson rejects invalid schema version', () {
      expect(
        () => GroupLayout.fromJson({'schema_version': 99, 'root': {}}),
        throwsFormatException,
      );
    });
  });
}
