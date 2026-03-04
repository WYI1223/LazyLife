import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/features/notes/notes_coordinator.dart';

void main() {
  rust_api.AtomListItem note({
    required String atomId,
    required String content,
    required List<String> tags,
  }) {
    return rust_api.AtomListItem(
      viewHint: 'note',
      title: content.replaceFirst('# ', ''),
      contentType: 'markdown',
      atomId: atomId,
      content: content,
      previewText: null,
      previewImage: null,
      updatedAt: 1,
      tags: tags,
    );
  }

  late NotesCoordinator controller;
  late Map<String, rust_api.AtomListItem> store;
  late Map<String, List<String>> ancestorPaths;

  setUp(() {
    store = {
      'note-1': note(
        atomId: 'note-1',
        content: '# Work Doc',
        tags: const ['work'],
      ),
      'note-2': note(
        atomId: 'note-2',
        content: '# Home Doc',
        tags: const ['home'],
      ),
      'note-3': note(
        atomId: 'note-3',
        content: '# Work Task',
        tags: const ['work'],
      ),
    };

    ancestorPaths = {
      'note-1': ['Projects', 'Engineering'],
      'note-2': [],
      'note-3': ['Projects'],
    };

    controller = NotesCoordinator(
      prepare: () async {},
      tagsListInvoker: () async {
        return const rust_api.TagsListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          tags: ['home', 'work'],
        );
      },
      notesListInvoker: ({tag, limit, offset}) async {
        final items = store.values
            .where((item) => tag == null || item.tags.contains(tag))
            .toList();
        return rust_api.AtomListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          appliedLimit: 50,
          items: items,
        );
      },
      noteGetInvoker: ({required atomId}) async {
        return rust_api.AtomItemResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          item: store[atomId],
        );
      },
      workspaceAncestorPathInvoker: ({required atomId}) async {
        return rust_api.WorkspaceAncestorPathResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          path: ancestorPaths[atomId] ?? [],
        );
      },
    );
  });

  tearDown(() => controller.dispose());

  test('applyTagFilter populates tagResults and tagBreadcrumbs', () async {
    await controller.loadNotes();
    await controller.applyTagFilter('work');

    // Allow async breadcrumb loading to complete.
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectedTag, 'work');
    expect(controller.tagResults.length, 2);
    expect(controller.tagResults.map((e) => e.atomId).toSet(), {
      'note-1',
      'note-3',
    });
    expect(controller.tagBreadcrumbs['note-1'], ['Projects', 'Engineering']);
    expect(controller.tagBreadcrumbs['note-3'], ['Projects']);
    expect(controller.tagResultsLoading, false);
  });

  test('clearTagFilter resets tag results state', () async {
    await controller.loadNotes();
    await controller.applyTagFilter('work');
    await Future<void>.delayed(Duration.zero);

    expect(controller.tagResults, isNotEmpty);

    await controller.clearTagFilter();

    expect(controller.selectedTag, isNull);
    expect(controller.tagResults, isEmpty);
    expect(controller.tagBreadcrumbs, isEmpty);
    expect(controller.tagResultsLoading, false);
  });

  test('switching tags replaces previous tag results', () async {
    await controller.loadNotes();
    await controller.applyTagFilter('work');
    await Future<void>.delayed(Duration.zero);

    expect(controller.tagResults.length, 2);

    await controller.applyTagFilter('home');
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectedTag, 'home');
    expect(controller.tagResults.length, 1);
    expect(controller.tagResults.first.atomId, 'note-2');
    expect(controller.tagBreadcrumbs['note-2'], isEmpty);
  });

  test('ancestor path failure is non-fatal', () async {
    // Dispose the setUp controller before replacing it.
    // tearDown will dispose the new one.
    controller.dispose();
    controller = NotesCoordinator(
      prepare: () async {},
      tagsListInvoker: () async {
        return const rust_api.TagsListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          tags: ['work'],
        );
      },
      notesListInvoker: ({tag, limit, offset}) async {
        final items = store.values
            .where((item) => tag == null || item.tags.contains(tag))
            .toList();
        return rust_api.AtomListResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          appliedLimit: 50,
          items: items,
        );
      },
      noteGetInvoker: ({required atomId}) async {
        return rust_api.AtomItemResponse(
          ok: true,
          errorCode: null,
          message: 'ok',
          item: store[atomId],
        );
      },
      workspaceAncestorPathInvoker: ({required atomId}) async {
        throw Exception('network error');
      },
    );
    await controller.loadNotes();
    await controller.applyTagFilter('work');
    await Future<void>.delayed(Duration.zero);

    // Results loaded despite breadcrumb failures; paths are empty lists.
    expect(controller.tagResults.length, 2);
    expect(controller.tagBreadcrumbs.values.every((p) => p.isEmpty), true);
    expect(controller.tagResultsLoading, false);
  });
}
