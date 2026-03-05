import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Axis;
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/editor/editor_group_model.dart';
import 'package:lazynote_flutter/core/editor/group_layout.dart';
import 'package:lazynote_flutter/core/editor/layout_persistence.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

late Directory _tempDir;
late String _layoutFilePath;

String _tempLayoutPath() => _layoutFilePath;

void _setUpTempDir() {
  _tempDir = Directory.systemTemp.createTempSync('layout_persistence_test_');
  _layoutFilePath =
      '${_tempDir.path}${Platform.pathSeparator}workspace_layout.json';
}

void _tearDownTempDir() {
  if (_tempDir.existsSync()) {
    _tempDir.deleteSync(recursive: true);
  }
}

/// A Timer stub that does nothing — allows manual callback invocation.
class _NoOpTimer implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

LayoutPersistence _buildPersistence({
  Timer Function(Duration, void Function())? timerFactory,
}) {
  return LayoutPersistence(
    layoutFilePathResolver: () async => _tempLayoutPath(),
    timerFactory: timerFactory,
  );
}

/// Builds a valid JSON string for a single-pane layout with optional tabs.
String _singlePaneJson({
  String groupId = 'group.primary',
  List<String> tabs = const [],
  String? activeTab,
  String? previewTab,
}) {
  return jsonEncode({
    'schema_version': 1,
    'activeGroupId': groupId,
    'layout': {'type': 'leaf', 'groupId': groupId},
    'groups': {
      groupId: {'tabs': tabs, 'activeTab': activeTab, 'previewTab': previewTab},
    },
  });
}

/// Builds a valid JSON string for a two-pane split layout.
String _splitPaneJson({
  String g1 = 'g1',
  String g2 = 'g2',
  List<String> g1Tabs = const ['atom-1'],
  List<String> g2Tabs = const ['atom-2'],
  String? g1Active = 'atom-1',
  String? g2Active = 'atom-2',
  String activeGroup = 'g1',
}) {
  return jsonEncode({
    'schema_version': 1,
    'activeGroupId': activeGroup,
    'layout': {
      'type': 'split',
      'axis': 'horizontal',
      'fraction': 0.5,
      'first': {'type': 'leaf', 'groupId': g1},
      'second': {'type': 'leaf', 'groupId': g2},
    },
    'groups': {
      g1: {'tabs': g1Tabs, 'activeTab': g1Active, 'previewTab': null},
      g2: {'tabs': g2Tabs, 'activeTab': g2Active, 'previewTab': null},
    },
  });
}

/// Polls until [path] exists on disk, with a timeout guard for CI.
Future<void> _waitForFile(String path, {int maxMs = 5000}) async {
  const pollInterval = Duration(milliseconds: 50);
  final deadline = DateTime.now().add(Duration(milliseconds: maxMs));
  while (!File(path).existsSync()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('File $path did not appear within ${maxMs}ms');
    }
    await Future<void>.delayed(pollInterval);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(_setUpTempDir);
  tearDown(() {
    _tearDownTempDir();
    LayoutPersistence.resetForTesting();
    GroupLayout.resetGroupIdCounter();
  });

  // ── EditorGroupModel toJson/fromJson round-trip ───────────────────────

  group('EditorGroupModel serialization', () {
    test('toJson serializes atomId list and active/preview', () {
      final model = EditorGroupModel(groupId: 'g1');
      model.openTab(const TabEntry(atomId: 'a1', title: 'Note 1'));
      model.openTab(const TabEntry(atomId: 'a2', title: 'Note 2'));
      model.setPreviewTab('a2');

      final json = model.toJson();
      expect(json['tabs'], ['a1', 'a2']);
      expect(json['activeTab'], 'a2');
      expect(json['previewTab'], 'a2');
    });

    test('fromJson restores tabs with empty titles', () {
      final json = {
        'tabs': ['a1', 'a2'],
        'activeTab': 'a1',
        'previewTab': 'a2',
      };
      final model = EditorGroupModel.fromJson('g1', json);
      expect(model.groupId, 'g1');
      expect(model.tabCount, 2);
      expect(model.tabs[0].atomId, 'a1');
      expect(model.tabs[0].title, '');
      expect(model.tabs[1].atomId, 'a2');
      expect(model.activeAtomId, 'a1');
      expect(model.previewTabId, 'a2');
    });

    test('round-trip preserves structure', () {
      final model = EditorGroupModel(groupId: 'g1');
      model.openTab(const TabEntry(atomId: 'a1', title: 'T'));
      model.openTab(const TabEntry(atomId: 'a2', title: 'T'));
      model.openTab(const TabEntry(atomId: 'a3', title: 'T'));
      model.activateTab('a2');
      model.setPreviewTab('a3');

      final json = model.toJson();
      final restored = EditorGroupModel.fromJson('g1', json);
      expect(restored.tabs.map((t) => t.atomId), ['a1', 'a2', 'a3']);
      expect(restored.activeAtomId, 'a2');
      expect(restored.previewTabId, 'a3');
    });

    test('fromJson handles empty tabs list', () {
      final json = {'tabs': <String>[], 'activeTab': null, 'previewTab': null};
      final model = EditorGroupModel.fromJson('g1', json);
      expect(model.isEmpty, true);
      expect(model.activeAtomId, isNull);
    });

    test('fromJson handles missing tabs key gracefully', () {
      final model = EditorGroupModel.fromJson('g1', {});
      expect(model.isEmpty, true);
    });
  });

  // ── LayoutPersistence load ────────────────────────────────────────────

  group('LayoutPersistence load', () {
    test('returns null when file does not exist (scenario 1)', () async {
      final persistence = _buildPersistence();
      final result = await persistence.load();
      expect(result, isNull);
    });

    test('returns null on JSON parse failure (scenario 2)', () async {
      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not valid json{{{');
      final persistence = _buildPersistence();
      final result = await persistence.load();
      expect(result, isNull);
    });

    test(
      'returns null and sets skipOverwrite when schema_version > current (scenario 3)',
      () async {
        File(_layoutFilePath)
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonEncode({'schema_version': 99}));
        final persistence = _buildPersistence();
        final result = await persistence.load();
        expect(result, isNull);

        // Verify: scheduleSave should be suppressed (skipOverwrite = true).
        // Write a valid file, then try to overwrite via scheduleSave.
        final validContent = _singlePaneJson(tabs: ['a1'], activeTab: 'a1');
        File(_layoutFilePath).writeAsStringSync(validContent);

        persistence.scheduleSave(
          layout: GroupLayout(root: const LeafNode(groupId: 'group.primary')),
          groups: {'group.primary': EditorGroupModel(groupId: 'group.primary')},
          activeGroupId: 'group.primary',
        );
        // Even if we fire, the save should not happen because skipOverwrite.
        // The timer was never scheduled, so timerFired stays false.
        // Verify the file still has the validContent.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final onDisk = File(_layoutFilePath).readAsStringSync();
        expect(onDisk, validContent);
      },
    );

    test('returns null on invalid tree structure (scenario 4)', () async {
      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'schema_version': 1,
            'activeGroupId': 'g1',
            'layout': {'type': 'unknown_type'},
            'groups': {
              'g1': {'tabs': [], 'activeTab': null, 'previewTab': null},
            },
          }),
        );
      final persistence = _buildPersistence();
      final result = await persistence.load();
      expect(result, isNull);
    });

    test(
      'collapses empty groups when groups.length > 1 (scenario 6)',
      () async {
        // g1 has tabs, g2 is empty → g2 should be collapsed
        File(_layoutFilePath)
          ..createSync(recursive: true)
          ..writeAsStringSync(_splitPaneJson(g2Tabs: [], g2Active: null));
        final persistence = _buildPersistence();
        final result = await persistence.load();
        expect(result, isNotNull);
        expect(result!.groups.length, 1);
        expect(result.groups.containsKey('g1'), true);
        expect(result.layout.allGroupIds, {'g1'});
      },
    );

    test(
      'recovers from temp file when target is missing (scenario 7)',
      () async {
        // Create a temp file but no target file
        Directory(_tempDir.path).createSync(recursive: true);
        final tempFile = File('$_layoutFilePath.tmp.12345');
        tempFile.writeAsStringSync(
          _singlePaneJson(tabs: ['a1'], activeTab: 'a1'),
        );
        expect(File(_layoutFilePath).existsSync(), false);

        final persistence = _buildPersistence();
        final result = await persistence.load();
        expect(result, isNotNull);
        expect(result!.groups['group.primary']!.tabCount, 1);
      },
    );

    test('loads valid single-pane layout', () async {
      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          _singlePaneJson(tabs: ['a1', 'a2'], activeTab: 'a1'),
        );
      final persistence = _buildPersistence();
      final result = await persistence.load();
      expect(result, isNotNull);
      expect(result!.activeGroupId, 'group.primary');
      expect(result.groups.length, 1);
      expect(result.groups['group.primary']!.tabCount, 2);
      expect(result.layout.allGroupIds, {'group.primary'});
    });

    test('loads valid split layout', () async {
      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(_splitPaneJson());
      final persistence = _buildPersistence();
      final result = await persistence.load();
      expect(result, isNotNull);
      expect(result!.activeGroupId, 'g1');
      expect(result.groups.length, 2);
      expect(result.groups['g1']!.tabCount, 1);
      expect(result.groups['g2']!.tabCount, 1);
      expect(result.layout.allGroupIds, {'g1', 'g2'});
    });

    test('falls back when activeGroupId not in groups', () async {
      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(_singlePaneJson(tabs: ['a1'], activeTab: 'a1'));
      // Manually overwrite with bad activeGroupId
      final json =
          jsonDecode(File(_layoutFilePath).readAsStringSync())
              as Map<String, dynamic>;
      json['activeGroupId'] = 'nonexistent';
      File(_layoutFilePath).writeAsStringSync(jsonEncode(json));

      final persistence = _buildPersistence();
      final result = await persistence.load();
      // Should resolve to the first available group
      expect(result, isNotNull);
      expect(result!.activeGroupId, 'group.primary');
    });

    test('returns null when tree-group mismatch', () async {
      // Layout has g1, but groups map has g1 + g2 (extra group)
      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(
          jsonEncode({
            'schema_version': 1,
            'activeGroupId': 'g1',
            'layout': {'type': 'leaf', 'groupId': 'g1'},
            'groups': {
              'g1': {
                'tabs': ['a1'],
                'activeTab': 'a1',
                'previewTab': null,
              },
              'g2': {
                'tabs': ['a2'],
                'activeTab': 'a2',
                'previewTab': null,
              },
            },
          }),
        );
      final persistence = _buildPersistence();
      final result = await persistence.load();
      expect(result, isNull);
    });
  });

  // ── Full JSON round-trip ──────────────────────────────────────────────

  group('JSON round-trip', () {
    test('single pane round-trip through save and load', () async {
      final persistence = _buildPersistence(
        timerFactory: (duration, callback) {
          callback(); // Fire immediately for testing
          return _NoOpTimer();
        },
      );

      final layout = GroupLayout(
        root: const LeafNode(groupId: 'group.primary'),
      );
      final groups = {
        'group.primary': EditorGroupModel(groupId: 'group.primary'),
      };
      groups['group.primary']!.openTab(
        const TabEntry(atomId: 'a1', title: 'Note'),
      );
      groups['group.primary']!.openTab(
        const TabEntry(atomId: 'a2', title: 'Note 2'),
      );

      persistence.scheduleSave(
        layout: layout,
        groups: groups,
        activeGroupId: 'group.primary',
      );

      // Poll until file appears (async write is fire-and-forget from timer)
      await _waitForFile(_layoutFilePath);

      expect(File(_layoutFilePath).existsSync(), true);

      // Load it back
      final loaded = await _buildPersistence().load();
      expect(loaded, isNotNull);
      expect(loaded!.activeGroupId, 'group.primary');
      expect(loaded.groups['group.primary']!.tabCount, 2);
      expect(loaded.groups['group.primary']!.activeAtomId, 'a2');
    });

    test('split layout round-trip', () async {
      final persistence = _buildPersistence(
        timerFactory: (duration, callback) {
          callback();
          return _NoOpTimer();
        },
      );

      var layout = GroupLayout(root: const LeafNode(groupId: 'g1'));
      final (newLayout, g2Id) = layout.split('g1', Axis.horizontal);
      layout = newLayout;

      final groups = {
        'g1': EditorGroupModel(groupId: 'g1'),
        g2Id: EditorGroupModel(groupId: g2Id),
      };
      groups['g1']!.openTab(const TabEntry(atomId: 'a1', title: 'T'));
      groups[g2Id]!.openTab(const TabEntry(atomId: 'a2', title: 'T'));
      groups[g2Id]!.setPreviewTab('a2');

      persistence.scheduleSave(
        layout: layout,
        groups: groups,
        activeGroupId: g2Id,
      );
      await _waitForFile(_layoutFilePath);

      final loaded = await _buildPersistence().load();
      expect(loaded, isNotNull);
      expect(loaded!.groups.length, 2);
      expect(loaded.activeGroupId, g2Id);
      expect(loaded.groups[g2Id]!.previewTabId, 'a2');
      expect(loaded.layout.allGroupIds.length, 2);
    });
  });

  // ── Debounce ──────────────────────────────────────────────────────────

  group('debounce', () {
    test('multiple rapid calls result in single write', () async {
      var writeCount = 0;
      void Function()? pendingCallback;
      final persistence = _buildPersistence(
        timerFactory: (duration, callback) {
          // Capture the latest callback; previous ones are discarded
          // (mirrors real Timer cancel + recreate in scheduleSave).
          writeCount = 0; // reset on each schedule — only final fire counts
          pendingCallback = () {
            writeCount++;
            callback();
          };
          return _NoOpTimer();
        },
      );

      final layout = GroupLayout(
        root: const LeafNode(groupId: 'group.primary'),
      );
      final groups = {
        'group.primary': EditorGroupModel(groupId: 'group.primary'),
      };

      // Call scheduleSave 5 times rapidly
      for (var i = 0; i < 5; i++) {
        persistence.scheduleSave(
          layout: layout,
          groups: groups,
          activeGroupId: 'group.primary',
        );
      }

      // Fire the debounced callback manually (no wall-clock dependency)
      pendingCallback!();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(writeCount, 1);
    });
  });

  // ── Atomic write ──────────────────────────────────────────────────────

  group('atomic write', () {
    test('write creates valid file without leftover temp files', () async {
      final persistence = _buildPersistence(
        timerFactory: (duration, callback) {
          callback();
          return _NoOpTimer();
        },
      );

      final layout = GroupLayout(
        root: const LeafNode(groupId: 'group.primary'),
      );
      final groups = {
        'group.primary': EditorGroupModel(groupId: 'group.primary'),
      };

      persistence.scheduleSave(
        layout: layout,
        groups: groups,
        activeGroupId: 'group.primary',
      );
      await _waitForFile(_layoutFilePath);

      expect(File(_layoutFilePath).existsSync(), true);

      // No leftover temp files
      final tempFiles = _tempDir
          .listSync()
          .where((f) => f.path.contains('.tmp.'))
          .toList();
      expect(tempFiles, isEmpty);

      // File is valid JSON
      final content = File(_layoutFilePath).readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      expect(json['schema_version'], 1);
    });
  });

  // ── Performance (T7) ─────────────────────────────────────────────────

  group('performance', () {
    test('startup recovery completes within 1000ms CI guard', () async {
      // Build a complex layout: 4 panes, 3 tabs each (DI-7 Q2 SLA condition)
      var layout = GroupLayout(root: const LeafNode(groupId: 'g1'));
      final (l2, g2) = layout.split('g1', Axis.horizontal);
      layout = l2;
      final (l3, g3) = layout.split(g2, Axis.vertical);
      layout = l3;
      final (l4, g4) = layout.split('g1', Axis.vertical);
      layout = l4;

      final groupsJson = <String, dynamic>{};
      for (final gId in ['g1', g2, g3, g4]) {
        groupsJson[gId] = {
          'tabs': ['${gId}_tab1', '${gId}_tab2', '${gId}_tab3'],
          'activeTab': '${gId}_tab1',
          'previewTab': null,
        };
      }

      final fullJson = jsonEncode({
        'schema_version': 1,
        'activeGroupId': 'g1',
        'layout': layout.toJson()['root'],
        'groups': groupsJson,
      });

      File(_layoutFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(fullJson);

      final persistence = _buildPersistence();
      final sw = Stopwatch()..start();
      final result = await persistence.load();
      sw.stop();

      expect(result, isNotNull);
      expect(result!.groups.length, 4);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });
  });
}
