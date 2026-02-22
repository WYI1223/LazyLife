import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as bindings;
import 'package:lazynote_flutter/core/bindings/frb_generated.dart';

class _LogDartEventContractSmokeApi implements RustLibApi {
  String? lastLevel;
  String? lastEventName;
  String? lastModule;
  String? lastMessage;

  @override
  bindings.LogDartEventResponse crateApiLogDartEvent({
    required String level,
    required String eventName,
    required String module,
    required String message,
  }) {
    lastLevel = level;
    lastEventName = eventName;
    lastModule = module;
    lastMessage = message;
    return const bindings.LogDartEventResponse(
      ok: true,
      errorCode: null,
      message: 'Dart event logged.',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected API call in log_dart_event smoke test: ${invocation.memberName}',
    );
  }
}

void main() {
  tearDown(() {
    RustLib.dispose();
  });

  test('logDartEvent forwards sync payload through generated binding', () {
    final mockApi = _LogDartEventContractSmokeApi();
    RustLib.initMock(api: mockApi);

    final response = bindings.logDartEvent(
      level: 'info',
      eventName: 'app.start',
      module: 'workbench',
      message: 'ready',
    );

    expect(response.ok, isTrue);
    expect(response.errorCode, isNull);
    expect(mockApi.lastLevel, 'info');
    expect(mockApi.lastEventName, 'app.start');
    expect(mockApi.lastModule, 'workbench');
    expect(mockApi.lastMessage, 'ready');
  });
}
