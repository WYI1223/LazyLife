// Layout and tab state persistence for the editor workbench.
//
// Two-layer architecture (DI-3):
// - Data conversion: GroupLayout.toJson()/fromJson() + EditorGroupModel.toJson()/fromJson()
// - File I/O: this class — read/write + 1s debounce + atomic write + recovery
//
// PR-RB-07: DI-3 layout persistence implementation.
// Design sources: DI-3 D7/D8/D9, layout-persistence module spec.
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:lazynote_flutter/core/editor/editor_group_model.dart';
import 'package:lazynote_flutter/core/editor/group_layout.dart';
import 'package:lazynote_flutter/core/local_paths.dart';

// ---------------------------------------------------------------------------
// LayoutSnapshot — immutable result of Phase 1 recovery
// ---------------------------------------------------------------------------

/// Snapshot of persisted layout state for Phase 1 recovery.
@immutable
class LayoutSnapshot {
  const LayoutSnapshot({
    required this.layout,
    required this.groups,
    required this.activeGroupId,
  });

  final GroupLayout layout;
  final Map<String, EditorGroupModel> groups;
  final String activeGroupId;
}

// ---------------------------------------------------------------------------
// LayoutPersistence
// ---------------------------------------------------------------------------

/// File I/O for workspace layout persistence.
///
/// Reads/writes `workspace_layout.json` with 1s debounce, atomic write,
/// and 7-scenario corruption recovery. Follows the same atomic write pattern
/// as [LocalSettingsStore].
class LayoutPersistence {
  LayoutPersistence({
    required Future<String> Function() layoutFilePathResolver,
    Timer Function(Duration, void Function())? timerFactory,
  }) : _layoutFilePathResolver = layoutFilePathResolver,
       _timerFactory = timerFactory;

  final Future<String> Function() _layoutFilePathResolver;
  final Timer Function(Duration, void Function())? _timerFactory;
  Timer? _debounceTimer;

  /// When true, save is suppressed (file has higher schema_version).
  bool _skipOverwrite = false;

  static const _debounceDuration = Duration(seconds: 1);
  static const _currentSchemaVersion = 1;

  // ── Singleton bootstrap (mirrors LocalSettingsStore pattern) ───────────

  static LayoutPersistence? _instance;

  /// Singleton instance, available after [ensureInitialized].
  static LayoutPersistence? get instance => _instance;

  LayoutSnapshot? _loadedSnapshot;

  /// Snapshot loaded during [ensureInitialized], or null if no valid file.
  ///
  /// Returns the snapshot exactly once — subsequent calls return null.
  /// This prevents reuse of mutable [EditorGroupModel] objects across
  /// multiple [EditorShellService] lifetimes (groups are disposed by the
  /// service; a second consumer would receive already-disposed objects).
  LayoutSnapshot? consumeLoadedSnapshot() {
    final snapshot = _loadedSnapshot;
    _loadedSnapshot = null;
    return snapshot;
  }

  /// Loads layout from disk during Critical Phase (before first frame).
  static Future<void> ensureInitialized() async {
    if (_instance != null) return;
    final persistence = LayoutPersistence(
      layoutFilePathResolver: LocalPaths.resolveWorkspaceLayoutFilePath,
    );
    persistence._loadedSnapshot = await persistence.load();
    _instance = persistence;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  // ── Phase 1: Load (Critical Phase — sync-blocking) ────────────────────

  /// Loads persisted layout state from disk.
  ///
  /// Returns the restored state or null if file is missing/corrupt.
  /// On corruption, logs a warning and returns null (caller creates default).
  Future<LayoutSnapshot?> load() async {
    try {
      final path = await _layoutFilePathResolver();
      final file = File(path);

      // Recovery scenario 7: temp file residuals
      await _recoverFromTempFileIfNeeded(file);

      // Recovery scenario 1: file missing
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // Recovery scenario 3: schema_version > current
      final version = json['schema_version'] as int?;
      if (version == null) {
        dev.log(
          'Missing schema_version in workspace_layout.json',
          name: 'LayoutPersistence',
        );
        return null;
      }
      if (version > _currentSchemaVersion) {
        dev.log(
          'workspace_layout.json has schema_version $version > '
          '$_currentSchemaVersion; falling back to default layout '
          'without overwriting file.',
          name: 'LayoutPersistence',
        );
        _skipOverwrite = true;
        return null;
      }

      // Parse layout tree (scenario 4: invalid tree structure)
      final layoutJson = {'schema_version': version, 'root': json['layout']};
      final layout = GroupLayout.fromJson(layoutJson);

      // Parse activeGroupId
      final activeGroupId = json['activeGroupId'] as String?;
      if (activeGroupId == null) {
        dev.log(
          'Missing activeGroupId in workspace_layout.json',
          name: 'LayoutPersistence',
        );
        return null;
      }

      // Parse groups
      final groupsJson = json['groups'] as Map<String, dynamic>?;
      if (groupsJson == null) {
        dev.log(
          'Missing groups in workspace_layout.json',
          name: 'LayoutPersistence',
        );
        return null;
      }

      final groups = <String, EditorGroupModel>{};
      for (final entry in groupsJson.entries) {
        final groupData = entry.value as Map<String, dynamic>;
        groups[entry.key] = EditorGroupModel.fromJson(entry.key, groupData);
      }

      // Recovery scenario 6: empty groups collapse (paneCount >= 1 invariant)
      var currentLayout = layout;
      final emptyGroupIds = groups.entries
          .where((e) => e.value.isEmpty)
          .map((e) => e.key)
          .toList();
      for (final emptyId in emptyGroupIds) {
        if (groups.length > 1) {
          groups[emptyId]?.dispose();
          groups.remove(emptyId);
          try {
            currentLayout = currentLayout.closeGroup(emptyId);
          } on StateError {
            // Already removed or last node — ignore
          }
        }
      }

      // Validate: activeGroupId must exist in groups
      final resolvedActiveGroupId = groups.containsKey(activeGroupId)
          ? activeGroupId
          : groups.keys.first;

      // Validate: tree leaves must match group keys
      final treeGroupIds = currentLayout.allGroupIds;
      if (treeGroupIds.length != groups.length ||
          !treeGroupIds.containsAll(groups.keys)) {
        dev.log(
          'Tree leaves do not match group keys in workspace_layout.json',
          name: 'LayoutPersistence',
        );
        return null;
      }

      return LayoutSnapshot(
        layout: currentLayout,
        groups: groups,
        activeGroupId: resolvedActiveGroupId,
      );
    } on FormatException catch (e) {
      // Recovery scenarios 2 & 4: JSON parse error or invalid tree
      dev.log(
        'Failed to parse workspace_layout.json: $e',
        name: 'LayoutPersistence',
      );
      return null;
    } catch (e) {
      dev.log(
        'Unexpected error loading workspace_layout.json: $e',
        name: 'LayoutPersistence',
      );
      return null;
    }
  }

  // ── Ongoing: Debounced save ───────────────────────────────────────────

  /// Schedules a debounced save of the current layout state.
  ///
  /// All structural changes (split/resize/tab operations) should trigger this.
  /// The actual write happens 1s after the last call (DI-3 D7).
  void scheduleSave({
    required GroupLayout layout,
    required Map<String, EditorGroupModel> groups,
    required String activeGroupId,
  }) {
    if (_skipOverwrite) return;

    _debounceTimer?.cancel();

    // Capture state now — groups are mutable, so serialize immediately
    final content = _serializeState(layout, groups, activeGroupId);

    _debounceTimer = (_timerFactory ?? Timer.new)(_debounceDuration, () {
      _save(content);
    });
  }

  /// Cancels pending debounce timer.
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  // ── Internal ──────────────────────────────────────────────────────────

  String _serializeState(
    GroupLayout layout,
    Map<String, EditorGroupModel> groups,
    String activeGroupId,
  ) {
    final layoutData = layout.toJson();
    final groupsJson = <String, dynamic>{};
    for (final entry in groups.entries) {
      groupsJson[entry.key] = entry.value.toJson();
    }
    final json = {
      'schema_version': _currentSchemaVersion,
      'activeGroupId': activeGroupId,
      'layout': layoutData['root'],
      'groups': groupsJson,
    };
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Future<void> _save(String content) async {
    try {
      final path = await _layoutFilePathResolver();
      final target = File(path);
      await _writeFileWithTempReplace(target, content);
    } catch (e) {
      dev.log(
        'Failed to save workspace_layout.json: $e',
        name: 'LayoutPersistence',
      );
    }
  }

  /// Atomic write: temp file -> rename (with Windows fallback).
  ///
  /// Reuses the same pattern as LocalSettingsStore._writeFileWithTempReplace().
  static Future<void> _writeFileWithTempReplace(
    File target,
    String content,
  ) async {
    await target.parent.create(recursive: true);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final temp = File('${target.path}.tmp.$timestamp');
    await temp.writeAsString(content, flush: true);

    try {
      await temp.rename(target.path);
      return;
    } catch (_) {
      if (await target.exists()) {
        await target.delete();
      }
      await temp.rename(target.path);
    }
  }

  /// Recovers from leftover temp files when the target is missing.
  static Future<void> _recoverFromTempFileIfNeeded(File target) async {
    if (await target.exists()) return;
    if (!await target.parent.exists()) return;

    final tempPrefix = '${target.path}.tmp';
    final candidates = <File>[];
    await for (final entity in target.parent.list(followLinks: false)) {
      if (entity is File && entity.path.startsWith(tempPrefix)) {
        candidates.add(entity);
      }
    }

    if (candidates.isEmpty) return;

    File? newest;
    var newestModified = DateTime.fromMillisecondsSinceEpoch(0);
    for (final candidate in candidates) {
      final modified = await candidate.lastModified();
      if (newest == null || modified.isAfter(newestModified)) {
        newest = candidate;
        newestModified = modified;
      }
    }

    if (newest == null) return;

    try {
      await newest.rename(target.path);
      dev.log(
        'Recovered workspace_layout.json from leftover temp file.',
        name: 'LayoutPersistence',
      );
    } catch (e) {
      dev.log(
        'Failed to recover workspace_layout.json from temp file: $e',
        name: 'LayoutPersistence',
      );
    }
  }
}
