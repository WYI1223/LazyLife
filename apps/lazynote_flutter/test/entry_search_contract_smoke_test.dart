import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as bindings;
import 'package:lazynote_flutter/core/bindings/frb_generated.dart';

class _EntrySearchContractSmokeApi implements RustLibApi {
  String? lastText;
  String? lastKind;
  int? lastLimit;

  @override
  Future<bindings.EntrySearchResponse> crateApiEntrySearch({
    required String text,
    String? kind,
    int? limit,
  }) async {
    lastText = text;
    lastKind = kind;
    lastLimit = limit;
    return bindings.EntrySearchResponse(
      ok: true,
      errorCode: null,
      items: [
        bindings.EntrySearchItem(
          atomId: 'atom-${kind ?? 'all'}',
          kind: kind ?? 'note',
          snippet: 'snippet $text',
        ),
      ],
      message: 'Found 1 result(s).',
      appliedLimit: limit ?? 10,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected API call in entry-search smoke test: ${invocation.memberName}',
    );
  }
}

void main() {
  tearDown(() {
    RustLib.dispose();
  });

  test(
    'entrySearch forwards optional kind through generated binding',
    () async {
      final mockApi = _EntrySearchContractSmokeApi();
      RustLib.initMock(api: mockApi);

      final filteredResponse = await bindings.entrySearch(
        text: 'ship',
        kind: 'task',
        limit: 12,
      );
      expect(filteredResponse.ok, isTrue);
      expect(filteredResponse.items.single.kind, 'task');
      expect(filteredResponse.appliedLimit, 12);
      expect(mockApi.lastText, 'ship');
      expect(mockApi.lastKind, 'task');
      expect(mockApi.lastLimit, 12);

      final defaultResponse = await bindings.entrySearch(text: 'ship');
      expect(defaultResponse.ok, isTrue);
      expect(mockApi.lastText, 'ship');
      expect(mockApi.lastKind, isNull);
      expect(mockApi.lastLimit, isNull);
    },
  );
}
