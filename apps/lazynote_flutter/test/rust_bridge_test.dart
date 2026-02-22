import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/diagnostics/dart_event_logger.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';

void main() {
  tearDown(() {
    RustBridge.resetForTesting();
    LocalSettingsStore.resetForTesting();
    DartEventLogger.resetForTesting();
  });

  test('init de-duplicates concurrent calls', () async {
    RustBridge.resetForTesting();
    RustBridge.candidateLibraryPathsOverride = const [];

    var initCalls = 0;
    final blocker = Completer<void>();
    RustBridge.rustLibInit = (_) async {
      initCalls += 1;
      await blocker.future;
    };

    final futures = <Future<void>>[
      RustBridge.init(),
      RustBridge.init(),
      RustBridge.init(),
    ];

    expect(initCalls, 1);
    blocker.complete();
    await Future.wait(futures);

    await RustBridge.init();
    expect(initCalls, 1);
  });

  test('init does not retry after first failure', () async {
    RustBridge.resetForTesting();
    RustBridge.candidateLibraryPathsOverride = const [];

    var initAttempts = 0;
    RustBridge.rustLibInit = (_) async {
      initAttempts += 1;
      throw StateError('first init failed');
    };

    await expectLater(RustBridge.init(), throwsA(isA<StateError>()));
    await expectLater(
      RustBridge.init(),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('RustBridge init permanently failed'),
        ),
      ),
    );
    expect(initAttempts, 1);
  });

  test(
    'init-after-failure does not re-enter RustLib.init concurrently',
    () async {
      RustBridge.resetForTesting();
      RustBridge.candidateLibraryPathsOverride = const [];

      var initAttempts = 0;
      RustBridge.rustLibInit = (_) async {
        initAttempts += 1;
        throw StateError('init failed');
      };

      await expectLater(RustBridge.init(), throwsA(isA<StateError>()));
      final outcomes = await Future.wait([
        RustBridge.init().then((_) => false).catchError((_) => true),
        RustBridge.init().then((_) => false).catchError((_) => true),
      ]);

      expect(outcomes.every((v) => v), isTrue);
      expect(initAttempts, 1);
    },
  );

  test('falls back to next candidate if opening library fails', () async {
    RustBridge.resetForTesting();
    RustBridge.operatingSystem = () => 'windows';
    RustBridge.candidateLibraryPathsOverride = const [
      'first_candidate.dll',
      'second_candidate.dll',
    ];
    RustBridge.fileExists = (_) => true;

    final openedCandidates = <String>[];
    final logMessages = <String>[];

    RustBridge.externalLibraryOpener = (path) {
      openedCandidates.add(path);
      throw StateError('cannot open $path');
    };
    RustBridge.logger = ({required message, error, stackTrace}) {
      logMessages.add('$message | $error');
    };
    RustBridge.rustLibInit = (_) async {};

    await RustBridge.init();

    expect(openedCandidates, const [
      'first_candidate.dll',
      'second_candidate.dll',
    ]);
    expect(logMessages.length, 2);
  });

  test('packaged build probes executable directory first', () async {
    RustBridge.resetForTesting();
    RustBridge.operatingSystem = () => 'windows';
    RustBridge.resolvedExecutablePathResolver = () =>
        r'D:\bundle\lazynote_flutter.exe';

    final bundledDll = r'D:\bundle\lazynote_ffi.dll';
    RustBridge.fileExists = (path) => path == bundledDll;

    final openedCandidates = <String>[];
    RustBridge.externalLibraryOpener = (path) {
      openedCandidates.add(path);
      throw StateError('cannot open $path');
    };
    RustBridge.logger = ({required message, error, stackTrace}) {};
    RustBridge.rustLibInit = (_) async {};

    await RustBridge.init();

    expect(openedCandidates, [bundledDll]);
  });

  test('bootstrapLogging de-duplicates concurrent calls', () async {
    RustBridge.resetForTesting();
    RustBridge.candidateLibraryPathsOverride = const [];

    var dbPathCalls = 0;
    var logDirCalls = 0;
    RustBridge.entryDbPathResolver = () async {
      dbPathCalls += 1;
      return '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
    };
    RustBridge.logDirPathResolver = () async {
      logDirCalls += 1;
      return '${Directory.systemTemp.path}${Platform.pathSeparator}logs';
    };

    var initLoggingCalls = 0;
    var configureCalls = 0;
    RustBridge.rustLibInit = (_) async {};
    RustBridge.configureEntryDbPathCall = ({required dbPath}) {
      configureCalls += 1;
      return '';
    };
    RustBridge.initLoggingCall = ({required level, required logDir}) {
      initLoggingCalls += 1;
      return '';
    };

    final futures = <Future<RustLoggingInitSnapshot>>[
      RustBridge.bootstrapLogging(),
      RustBridge.bootstrapLogging(),
      RustBridge.bootstrapLogging(),
    ];

    final snapshots = await Future.wait(futures);
    expect(dbPathCalls, 1);
    expect(logDirCalls, 1);
    expect(configureCalls, 1);
    expect(initLoggingCalls, 1);
    expect(snapshots.every((snapshot) => snapshot.isSuccess), isTrue);
  });

  test('ensureEntryDbPathConfigured de-duplicates concurrent calls', () async {
    RustBridge.resetForTesting();
    RustBridge.candidateLibraryPathsOverride = const [];

    var dbPathCalls = 0;
    var configureCalls = 0;
    RustBridge.entryDbPathResolver = () async {
      dbPathCalls += 1;
      return '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
    };
    RustBridge.rustLibInit = (_) async {};
    RustBridge.configureEntryDbPathCall = ({required dbPath}) {
      configureCalls += 1;
      return '';
    };

    await Future.wait([
      RustBridge.ensureEntryDbPathConfigured(),
      RustBridge.ensureEntryDbPathConfigured(),
      RustBridge.ensureEntryDbPathConfigured(),
    ]);

    expect(dbPathCalls, 1);
    expect(configureCalls, 1);

    await RustBridge.ensureEntryDbPathConfigured();
    expect(configureCalls, 1);
  });

  test('bootstrapLogging returns failure snapshot on init error', () async {
    RustBridge.resetForTesting();
    RustBridge.entryDbPathResolver = () async =>
        '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
    RustBridge.logDirPathResolver = () async =>
        '${Directory.systemTemp.path}${Platform.pathSeparator}logs';
    RustBridge.configureEntryDbPathCall = ({required dbPath}) => '';
    RustBridge.rustLibInit = (_) async {
      throw StateError('ffi init failed');
    };

    final snapshot = await RustBridge.bootstrapLogging();
    expect(snapshot.isSuccess, isFalse);
    expect(snapshot.errorMessage, contains('ffi init failed'));
  });

  test(
    'bootstrapLogging returns failure when entry db path config fails',
    () async {
      RustBridge.resetForTesting();
      final logMessages = <String>[];
      RustBridge.entryDbPathResolver = () async =>
          '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
      RustBridge.logDirPathResolver = () async =>
          '${Directory.systemTemp.path}${Platform.pathSeparator}logs';
      RustBridge.rustLibInit = (_) async {};
      RustBridge.logger = ({required message, error, stackTrace}) {
        logMessages.add(message);
      };
      RustBridge.configureEntryDbPathCall = ({required dbPath}) =>
          'db path denied';
      var initLoggingCalls = 0;
      RustBridge.initLoggingCall = ({required level, required logDir}) {
        initLoggingCalls += 1;
        return '';
      };

      final snapshot = await RustBridge.bootstrapLogging();
      expect(snapshot.isSuccess, isFalse);
      expect(snapshot.errorMessage, contains('db path denied'));
      expect(initLoggingCalls, 0);
      expect(
        logMessages.any((m) => m.contains('entry-db-path configure failed')),
        isTrue,
      );
    },
  );

  test('bootstrapLogging labels logging init failures clearly', () async {
    RustBridge.resetForTesting();
    final logMessages = <String>[];
    RustBridge.entryDbPathResolver = () async =>
        '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
    RustBridge.logDirPathResolver = () async =>
        '${Directory.systemTemp.path}${Platform.pathSeparator}logs';
    RustBridge.rustLibInit = (_) async {};
    RustBridge.logger = ({required message, error, stackTrace}) {
      logMessages.add(message);
    };
    RustBridge.configureEntryDbPathCall = ({required dbPath}) => '';
    RustBridge.initLoggingCall = ({required level, required logDir}) =>
        'logging denied';

    final snapshot = await RustBridge.bootstrapLogging();
    expect(snapshot.isSuccess, isFalse);
    expect(snapshot.errorMessage, contains('logging denied'));
    expect(logMessages.any((m) => m.contains('logging-init failed')), isTrue);
  });

  test('bootstrapLogging uses logging level override when configured', () async {
    RustBridge.resetForTesting();
    LocalSettingsStore.resetForTesting();

    final tempDir = await Directory.systemTemp.createTemp(
      'lazynote-rust-bridge-settings-',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    await File(settingsPath).writeAsString('''
{
  "schema_version": 1,
  "entry": {
    "ui": {
      "collapsed_height": 72,
      "expanded_max_height": 420,
      "animation_ms": 180
    }
  },
  "logging": {
    "level_override": "trace"
  }
}
''');

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    RustBridge.entryDbPathResolver = () async =>
        '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
    RustBridge.logDirPathResolver = () async =>
        '${Directory.systemTemp.path}${Platform.pathSeparator}logs';
    RustBridge.rustLibInit = (_) async {};
    RustBridge.configureEntryDbPathCall = ({required dbPath}) => '';

    var capturedLevel = '';
    RustBridge.initLoggingCall = ({required level, required logDir}) {
      capturedLevel = level;
      return '';
    };
    RustBridge.defaultLogLevelResolver = () => 'info';

    final snapshot = await RustBridge.bootstrapLogging();
    expect(snapshot.isSuccess, isTrue);
    expect(snapshot.level, 'trace');
    expect(capturedLevel, 'trace');
  });

  test(
    'bootstrapLogging remains non-blocking when dart event logging throws',
    () async {
      RustBridge.resetForTesting();
      DartEventLogger.resetForTesting();

      RustBridge.entryDbPathResolver = () async =>
          '${Directory.systemTemp.path}${Platform.pathSeparator}data${Platform.pathSeparator}entry.sqlite3';
      RustBridge.logDirPathResolver = () async =>
          '${Directory.systemTemp.path}${Platform.pathSeparator}logs';
      RustBridge.rustLibInit = (_) async {};
      RustBridge.configureEntryDbPathCall = ({required dbPath}) => '';
      RustBridge.initLoggingCall = ({required level, required logDir}) => '';
      DartEventLogger.invoker =
          ({
            required String level,
            required String eventName,
            required String module,
            required String message,
          }) {
            throw StateError('log_dart_event unavailable');
          };

      final snapshot = await RustBridge.bootstrapLogging();
      expect(snapshot.isSuccess, isTrue);
    },
  );
}
