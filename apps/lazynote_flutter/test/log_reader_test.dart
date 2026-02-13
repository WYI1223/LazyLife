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
}
