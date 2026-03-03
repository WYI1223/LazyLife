// Per-pane visual state model for editor groups.
//
// Manages one editor pane's tab list, active tab, and preview tab.
// Pure logic model — does not contain content or save state (those belong
// to per-atom EditBuffer).
//
// PR-RB-06: First landing of core/editor/ infrastructure.
// Design sources: DI-1 Q1/Q2, S2 Phase 2, editor-group-model module spec.
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// TabEntry
// ---------------------------------------------------------------------------

/// One tab in an editor group.
///
/// [title] is a stored value updated by [EditorShellService.updateTabTitle],
/// not dynamically derived.
@immutable
class TabEntry {
  const TabEntry({required this.atomId, required this.title});

  /// Atom UUID this tab references.
  final String atomId;

  /// Display title (from atom.title, S1 R8).
  final String title;

  TabEntry copyWith({String? atomId, String? title}) {
    return TabEntry(atomId: atomId ?? this.atomId, title: title ?? this.title);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabEntry && atomId == other.atomId && title == other.title;

  @override
  int get hashCode => Object.hash(atomId, title);
}

// ---------------------------------------------------------------------------
// EditorGroupModel
// ---------------------------------------------------------------------------

/// Per-pane tab list and activation state.
///
/// Draft content and save state are NOT stored here — they belong to
/// per-atom [EditBuffer] instances that are shared across panes.
class EditorGroupModel extends ChangeNotifier {
  EditorGroupModel({required this.groupId});

  /// Unique identifier for this group (matches [LeafNode.groupId]).
  final String groupId;

  final List<TabEntry> _tabs = [];
  String? _activeAtomId;
  String? _previewTabId;

  // ── Public accessors ───────────────────────────────────────────────

  /// Unmodifiable snapshot of the tab list.
  List<TabEntry> get tabs => List.unmodifiable(_tabs);

  /// Currently active tab's atom ID, or null if no tabs.
  String? get activeAtomId => _activeAtomId;

  /// Preview tab atom ID (per-group, not global — DI-1 Q1).
  String? get previewTabId => _previewTabId;

  /// Whether this group has no tabs.
  bool get isEmpty => _tabs.isEmpty;

  /// Number of tabs in this group.
  int get tabCount => _tabs.length;

  /// Whether [atomId] is open in this group.
  bool containsAtom(String atomId) => _tabs.any((tab) => tab.atomId == atomId);

  // ── Tab operations ─────────────────────────────────────────────────

  /// Adds a tab if not already present. Does not activate it.
  void addTab(TabEntry entry) {
    if (containsAtom(entry.atomId)) return;
    _tabs.add(entry);
    notifyListeners();
  }

  /// Removes the tab for [atomId].
  ///
  /// If the removed tab was active, activates an adjacent tab.
  /// Returns true if a tab was actually removed.
  bool removeTab(String atomId) {
    final index = _tabs.indexWhere((t) => t.atomId == atomId);
    if (index < 0) return false;

    _tabs.removeAt(index);

    // Clear preview if the removed tab was the preview
    if (_previewTabId == atomId) {
      _previewTabId = null;
    }

    // Adjust active tab if we removed the active one
    if (_activeAtomId == atomId) {
      if (_tabs.isEmpty) {
        _activeAtomId = null;
      } else {
        final fallback = index.clamp(0, _tabs.length - 1);
        _activeAtomId = _tabs[fallback].atomId;
      }
    }

    notifyListeners();
    return true;
  }

  /// Sets the active tab to [atomId]. No-op if not in tab list.
  void activateTab(String atomId) {
    if (!containsAtom(atomId)) return;
    if (_activeAtomId == atomId) return;
    _activeAtomId = atomId;
    notifyListeners();
  }

  /// Opens a tab and makes it active. If already present, just activates.
  void openTab(TabEntry entry) {
    if (!containsAtom(entry.atomId)) {
      // If there's a preview tab that should be replaced
      _tabs.add(entry);
    }
    _activeAtomId = entry.atomId;
    notifyListeners();
  }

  /// Marks [atomId] as the preview tab.
  void setPreviewTab(String atomId) {
    if (!containsAtom(atomId)) return;
    _previewTabId = atomId;
    notifyListeners();
  }

  /// Pins the preview tab (clears preview status).
  void pinPreviewTab(String atomId) {
    if (_previewTabId != atomId) return;
    _previewTabId = null;
    notifyListeners();
  }

  /// Replaces the current preview tab with a new entry.
  ///
  /// Returns the replaced preview tab's atomId, or null if no replacement.
  String? replacePreviewTab(TabEntry newEntry) {
    final oldPreviewId = _previewTabId;
    if (oldPreviewId == null || !containsAtom(oldPreviewId)) {
      // No preview to replace — just add
      openTab(newEntry);
      _previewTabId = newEntry.atomId;
      return null;
    }

    final index = _tabs.indexWhere((t) => t.atomId == oldPreviewId);
    if (index >= 0) {
      _tabs[index] = newEntry;
    }
    _previewTabId = newEntry.atomId;
    _activeAtomId = newEntry.atomId;
    notifyListeners();
    return oldPreviewId;
  }

  /// Updates the title for all tabs matching [atomId].
  void updateTitle(String atomId, String newTitle) {
    var changed = false;
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].atomId == atomId && _tabs[i].title != newTitle) {
        _tabs[i] = _tabs[i].copyWith(title: newTitle);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Removes all tabs except [atomId]. Returns true if any were removed.
  bool closeOtherTabs(String atomId) {
    if (!containsAtom(atomId)) return false;
    final kept = _tabs.where((t) => t.atomId == atomId).toList();
    if (kept.length == _tabs.length) return false;
    _tabs
      ..clear()
      ..addAll(kept);
    _activeAtomId = atomId;
    if (_previewTabId != null && _previewTabId != atomId) {
      _previewTabId = null;
    }
    notifyListeners();
    return true;
  }

  /// Removes all tabs to the right of [atomId].
  bool closeTabsToRight(String atomId) {
    final index = _tabs.indexWhere((t) => t.atomId == atomId);
    if (index < 0 || index == _tabs.length - 1) return false;

    final removed = _tabs.sublist(index + 1);
    _tabs.removeRange(index + 1, _tabs.length);

    // Fix preview if removed
    if (_previewTabId != null &&
        removed.any((t) => t.atomId == _previewTabId)) {
      _previewTabId = null;
    }

    // Fix active if removed
    if (_activeAtomId != null &&
        removed.any((t) => t.atomId == _activeAtomId)) {
      _activeAtomId = atomId;
    }

    notifyListeners();
    return true;
  }

  // ── Serialization (PR-RB-07 DI-3) ─────────────────────────────────────

  /// Serializes tab state to JSON for layout persistence.
  ///
  /// Only atomId references are persisted — titles are reloaded in Phase 2.
  Map<String, dynamic> toJson() {
    return {
      'tabs': _tabs.map((t) => t.atomId).toList(),
      'activeTab': _activeAtomId,
      'previewTab': _previewTabId,
    };
  }

  /// Restores group state from persisted JSON (Phase 1).
  ///
  /// Tab titles default to empty string — reloaded during Phase 2.
  static EditorGroupModel fromJson(String groupId, Map<String, dynamic> json) {
    final model = EditorGroupModel(groupId: groupId);
    final tabs = (json['tabs'] as List?)?.cast<String>() ?? [];
    for (final atomId in tabs) {
      model._tabs.add(TabEntry(atomId: atomId, title: ''));
    }
    model._activeAtomId = json['activeTab'] as String?;
    model._previewTabId = json['previewTab'] as String?;
    return model;
  }
}
