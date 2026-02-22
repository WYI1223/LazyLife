import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as bindings;
import 'package:lazynote_flutter/core/diagnostics/dart_event_logger.dart';

void main() {
  tearDown(() {
    DartEventLogger.resetForTesting();
  });

  test('tryLog forwards payload when FFI accepts request', () {
    var callCount = 0;
    String? loggedLevel;
    String? loggedEventName;
    String? loggedModule;
    String? loggedMessage;

    DartEventLogger.invoker =
        ({
          required String level,
          required String eventName,
          required String module,
          required String message,
        }) {
          callCount += 1;
          loggedLevel = level;
          loggedEventName = eventName;
          loggedModule = module;
          loggedMessage = message;
          return const bindings.LogDartEventResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
          );
        };

    final result = DartEventLogger.tryLog(
      level: 'INFO',
      eventName: 'diagnostics.logs.open_folder.ok',
      module: 'diagnostics.debug_logs_panel',
      message: 'Diagnostics log folder opened.',
    );

    expect(result, isTrue);
    expect(callCount, 1);
    expect(loggedLevel, 'info');
    expect(loggedEventName, 'diagnostics.logs.open_folder.ok');
    expect(loggedModule, 'diagnostics.debug_logs_panel');
    expect(loggedMessage, 'Diagnostics log folder opened.');
  });

  test('tryLog never throws when FFI invocation throws', () {
    DartEventLogger.invoker =
        ({
          required String level,
          required String eventName,
          required String module,
          required String message,
        }) {
          throw StateError('bridge down');
        };

    expect(
      () => DartEventLogger.tryLog(
        level: 'warn',
        eventName: 'rust_bridge.health_check.error',
        module: 'core.rust_bridge',
        message: 'Rust health check failed.',
      ),
      returnsNormally,
    );
    expect(
      DartEventLogger.tryLog(
        level: 'warn',
        eventName: 'rust_bridge.health_check.error',
        module: 'core.rust_bridge',
        message: 'Rust health check failed.',
      ),
      isFalse,
    );
  });

  test('tryLog dedupe suppresses repeated event in dedupe window', () {
    var callCount = 0;
    var now = DateTime(2026, 2, 22, 12, 0, 0);
    DartEventLogger.now = () => now;
    DartEventLogger.invoker =
        ({
          required String level,
          required String eventName,
          required String module,
          required String message,
        }) {
          callCount += 1;
          return const bindings.LogDartEventResponse(
            ok: true,
            errorCode: null,
            message: 'ok',
          );
        };

    expect(
      DartEventLogger.tryLog(
        level: 'info',
        eventName: 'rust_bridge.logging_bootstrap.ok',
        module: 'core.rust_bridge',
        message: 'Rust logging bootstrap completed successfully.',
      ),
      isTrue,
    );
    expect(
      DartEventLogger.tryLog(
        level: 'info',
        eventName: 'rust_bridge.logging_bootstrap.ok',
        module: 'core.rust_bridge',
        message: 'Rust logging bootstrap completed successfully.',
      ),
      isFalse,
    );
    expect(callCount, 1);

    now = now.add(const Duration(seconds: 3));
    expect(
      DartEventLogger.tryLog(
        level: 'info',
        eventName: 'rust_bridge.logging_bootstrap.ok',
        module: 'core.rust_bridge',
        message: 'Rust logging bootstrap completed successfully.',
      ),
      isTrue,
    );
    expect(callCount, 2);
  });
}
