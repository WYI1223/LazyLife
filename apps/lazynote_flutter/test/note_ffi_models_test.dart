import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart';

void main() {
  test('AtomListItem supports nullable preview fields', () {
    const item = AtomListItem(
      atomId: 'atom-1',
      kind: 'note',
      content: 'content',
      previewText: null,
      previewImage: null,
      updatedAt: 123,
      tags: ['work'],
    );

    expect(item.previewText, isNull);
    expect(item.previewImage, isNull);
    expect(item.tags, ['work']);
  });

  test('AtomItemResponse carries preview fields when present', () {
    const note = AtomListItem(
      atomId: 'atom-2',
      kind: 'note',
      content: '# title',
      previewText: 'title',
      previewImage: 'cover.png',
      updatedAt: 456,
      tags: ['important', 'work'],
    );
    const response = AtomItemResponse(
      ok: true,
      errorCode: null,
      message: 'ok',
      item: note,
    );

    expect(response.ok, isTrue);
    expect(response.item, isNotNull);
    expect(response.item!.previewText, 'title');
    expect(response.item!.previewImage, 'cover.png');
  });

  test('AtomListResponse tolerates mixed preview nullability', () {
    const response = AtomListResponse(
      ok: true,
      errorCode: null,
      message: 'Loaded',
      appliedLimit: 10,
      items: [
        AtomListItem(
          atomId: 'atom-a',
          kind: 'note',
          content: 'a',
          previewText: 'summary a',
          previewImage: null,
          updatedAt: 1,
          tags: ['work'],
        ),
        AtomListItem(
          atomId: 'atom-b',
          kind: 'note',
          content: 'b',
          previewText: null,
          previewImage: 'b.png',
          updatedAt: 2,
          tags: ['home'],
        ),
      ],
    );

    expect(response.ok, isTrue);
    expect(response.items.length, 2);
    expect(response.items[0].previewImage, isNull);
    expect(response.items[1].previewText, isNull);
  });
}
