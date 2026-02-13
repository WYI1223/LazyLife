import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/debug/log_reader.dart';

void main() {
  tearDown(() {
    LogReader.resetForTesting();
  });

  test('openLogFolder surfaces explicit stderr failure', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-log-test-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    LogReader.processRunner = (String executable, List<String> args) async =>
        ProcessResult(1, 1, '', 'simulated failure');

    expect(
      () => LogReader.openLogFolder(tempDir.path),
      throwsA(isA<ProcessException>()),
    );
  });

  test('openLogFolder tolerates explorer non-zero without stderr', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-log-test-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    LogReader.processRunner = (String executable, List<String> args) async =>
        ProcessResult(1, 1, '', '');

    if (Platform.isWindows) {
      await LogReader.openLogFolder(tempDir.path);
      return;
    }

    expect(
      () => LogReader.openLogFolder(tempDir.path),
      throwsA(isA<ProcessException>()),
    );
  });

  test('openLogFolder fails when directory is missing', () async {
    final missingPath = Directory.systemTemp
        .createTempSync('lazynote-log-test-')
        .path;
    await Directory(missingPath).delete(recursive: true);

    LogReader.processRunner = (String executable, List<String> args) async =>
        ProcessResult(1, 1, '', '');

    expect(
      () => LogReader.openLogFolder(missingPath),
      throwsA(isA<ProcessException>()),
    );
  });

  test('readLatestTail uses tail reader for large log files', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-log-tail-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final largeFile = File(
      '${tempDir.path}${Platform.pathSeparator}lazynote-big.log',
    );
    final largeContent = List.filled(300 * 1024, 'a').join();
    await largeFile.writeAsString(largeContent);

    LogReader.logDirPathResolver = () async => tempDir.path;

    var fullReaderCalls = 0;
    var tailReaderCalls = 0;
    LogReader.fileReader = (File file) async {
      fullReaderCalls += 1;
      return 'full';
    };
    LogReader.fileTailReader = (File file, int maxBytes) async {
      tailReaderCalls += 1;
      return 'tail-only-line';
    };

    final snapshot = await LogReader.readLatestTail(maxLines: 50);
    expect(snapshot.tailText, contains('tail-only-line'));
    expect(fullReaderCalls, 0);
    expect(tailReaderCalls, 1);
  });
}
