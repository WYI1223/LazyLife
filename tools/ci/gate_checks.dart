/// Gate verification script for v0.3 release.
///
/// Gate A: Semantic & contract verification
/// - NoteItem zero references (excluding generated bindings)
/// - atom_ref observability via creation entry tests
/// - tasks/calendar zero reminder imports (S7 compliance)
/// - entry zero ExtensionRegistry references (S5 compliance)
///
/// Gate B: Editor infrastructure verification (existence gate — test pass ensured by flutter test CI step)
/// - EditorShellService test file exists
/// - EditBuffer cross-pane test file exists
/// - GroupLayout invariant test file exists
/// - Layout persistence test file exists
///
/// Usage (from `apps/lazynote_flutter/`):
///   dart run ../../tools/ci/gate_checks.dart [--gate-a] [--gate-b] [--all]
///
/// Exit code 0 = pass, 1 = violations found.
import 'dart:io';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

final Directory _repoRoot = () {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  return scriptDir.parent.parent;
}();

final Directory _appRoot = Directory('${_repoRoot.path}/apps/lazynote_flutter');
final Directory _libDir = Directory('${_appRoot.path}/lib');
final Directory _rustFfiDir = Directory(
  '${_repoRoot.path}/crates/lazynote_ffi/src',
);

Iterable<File> rustFfiSourceFilesForGateChecks({Directory? rustFfiDir}) sync* {
  final root = rustFfiDir ?? _rustFfiDir;
  if (!root.existsSync()) {
    return;
  }
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.rs'))
          .toList(growable: false)
        ..sort((a, b) => a.path.compareTo(b.path));
  yield* files;
}

bool rustFfiContainsTestFunctionForGateChecks(
  String testFnName, {
  Directory? rustFfiDir,
}) {
  final needle = 'fn $testFnName()';
  for (final file in rustFfiSourceFilesForGateChecks(rustFfiDir: rustFfiDir)) {
    final content = file.readAsStringSync();
    if (content.contains(needle)) {
      return true;
    }
  }
  return false;
}

// ---------------------------------------------------------------------------
// Gate A checks
// ---------------------------------------------------------------------------

int _violations = 0;

void _checkZeroReferences(
  String label,
  Directory searchDir,
  String pattern, {
  List<String> excludeGlobs = const [],
}) {
  final files = searchDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) {
        for (final glob in excludeGlobs) {
          if (f.path.contains(glob)) return false;
        }
        return true;
      });

  final matches = <String>[];
  for (final file in files) {
    final content = file.readAsStringSync();
    if (content.contains(pattern)) {
      matches.add(file.path);
    }
  }

  if (matches.isEmpty) {
    stdout.writeln('  PASS: $label — 0 matches');
  } else {
    _violations++;
    stderr.writeln('  FAIL: $label — ${matches.length} file(s):');
    for (final m in matches) {
      stderr.writeln('    $m');
    }
  }
}

void _checkTestExists(String label, String relativePath) {
  final file = File('${_appRoot.path}/$relativePath');
  if (file.existsSync()) {
    stdout.writeln('  PASS: $label — exists');
  } else {
    _violations++;
    stderr.writeln('  FAIL: $label — NOT FOUND at $relativePath');
  }
}

void _checkRustTestExists(String label, String testFnName) {
  final rustFiles = rustFfiSourceFilesForGateChecks(
    rustFfiDir: _rustFfiDir,
  ).toList();
  if (rustFiles.isEmpty) {
    _violations++;
    stderr.writeln('  FAIL: $label — lazynote_ffi Rust source files not found');
    return;
  }
  if (rustFfiContainsTestFunctionForGateChecks(
    testFnName,
    rustFfiDir: _rustFfiDir,
  )) {
    stdout.writeln('  PASS: $label — test fn exists');
  } else {
    _violations++;
    stderr.writeln(
      '  FAIL: $label — test fn $testFnName not found in lazynote_ffi/src',
    );
  }
}

bool _runGateA() {
  stdout.writeln('\n=== Gate A: Semantic & Contract Verification ===\n');

  // A1: NoteItem zero references (excluding generated bindings)
  _checkZeroReferences(
    'NoteItem zero references',
    _libDir,
    'NoteItem',
    excludeGlobs: ['bindings', 'frb_generated'],
  );

  // A2: atom_ref observability — Rust integration tests exist for
  // designated-folder routing after PR-0410.
  _checkRustTestExists(
    'atom_ref: note_create with parent',
    'note_create_with_parent_places_atom_ref_under_folder',
  );
  _checkRustTestExists(
    'atom_ref: note_create without parent routes to inbox',
    'note_create_without_parent_routes_atom_ref_to_inbox_designated_folder',
  );
  _checkRustTestExists(
    'atom_ref: entry_create_note routes to inbox',
    'entry_create_note_routes_atom_ref_to_inbox_designated_folder',
  );
  _checkRustTestExists(
    'atom_ref: entry_create_task routes to tasks',
    'entry_create_task_routes_atom_ref_to_tasks_designated_folder',
  );
  _checkRustTestExists(
    'atom_ref: entry_schedule routes to calendar',
    'entry_schedule_routes_atom_ref_to_calendar_designated_folder',
  );

  // A3: Tasks/Calendar zero direct scheduler imports (S7)
  // ReminderLifecycle is the public API (allowed); ReminderScheduler is
  // the internal scheduling component (forbidden in feature modules).
  final tasksDir = Directory('${_libDir.path}/features/tasks');
  final calendarDir = Directory('${_libDir.path}/features/calendar');
  if (tasksDir.existsSync()) {
    _checkZeroReferences(
      'tasks: zero ReminderScheduler refs',
      tasksDir,
      'ReminderScheduler',
    );
  }
  if (calendarDir.existsSync()) {
    _checkZeroReferences(
      'calendar: zero ReminderScheduler refs',
      calendarDir,
      'ReminderScheduler',
    );
  }

  // A4: S5 — entry zero ExtensionRegistry references
  final entryDir = Directory('${_libDir.path}/features/entry');
  if (entryDir.existsSync()) {
    _checkZeroReferences(
      'entry: zero ExtensionRegistry refs',
      entryDir,
      'ExtensionRegistry',
    );
  }

  return true;
}

bool _runGateB() {
  stdout.writeln('\n=== Gate B: Editor Infrastructure Verification ===\n');

  _checkTestExists(
    'EditorShellService tests',
    'test/editor_shell_service_test.dart',
  );
  _checkTestExists('EditBuffer tests', 'test/edit_buffer_test.dart');
  _checkTestExists(
    'GroupLayout invariant tests',
    'test/group_layout_test.dart',
  );
  _checkTestExists(
    'Layout persistence tests',
    'test/layout_persistence_test.dart',
  );
  _checkTestExists('EditorResolver tests', 'test/editor_resolver_test.dart');

  return true;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main(List<String> args) {
  final runAll = args.contains('--all') || args.isEmpty;
  final runA = runAll || args.contains('--gate-a');
  final runB = runAll || args.contains('--gate-b');

  if (runA) _runGateA();
  if (runB) _runGateB();

  stdout.writeln('');
  if (_violations == 0) {
    stdout.writeln('Result: ALL GATES PASS');
    exit(0);
  } else {
    stderr.writeln('Result: $_violations violation(s) found');
    exit(1);
  }
}
