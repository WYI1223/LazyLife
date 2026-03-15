import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gate A tracks PR-0410 designated-folder atom_ref routing tests', () {
    final repoRoot = Directory.current.parent.parent;
    final gateScript = File('${repoRoot.path}/tools/ci/gate_checks.dart');
    final content = gateScript.readAsStringSync();

    expect(
      content,
      contains(
        'note_create_without_parent_routes_atom_ref_to_inbox_designated_folder',
      ),
    );
    expect(
      content,
      contains('entry_create_note_routes_atom_ref_to_inbox_designated_folder'),
    );
    expect(
      content,
      contains('entry_create_task_routes_atom_ref_to_tasks_designated_folder'),
    );
    expect(
      content,
      contains('entry_schedule_routes_atom_ref_to_calendar_designated_folder'),
    );

    expect(
      content,
      isNot(contains('note_create_without_parent_places_atom_ref_at_root')),
    );
    expect(
      content,
      isNot(contains('entry_create_note_places_atom_ref_at_root')),
    );
    expect(
      content,
      isNot(contains('entry_create_task_places_atom_ref_at_root')),
    );
    expect(content, isNot(contains('entry_schedule_places_atom_ref_at_root')));
  });
}
