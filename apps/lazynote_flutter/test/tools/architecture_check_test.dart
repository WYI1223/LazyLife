import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late _ArchitectureCheckHarness harness;

  setUp(() {
    harness = _ArchitectureCheckHarness();
  });

  tearDown(() {
    harness.dispose();
  });

  test('detects cross-feature duplication', () async {
    harness.writeFeatureFile(
      featureName: 'pr0407_dup_source',
      relativePath: 'dup_source.dart',
      content: _buildDuplicateFixture('DupSource'),
    );
    harness.writeFeatureFile(
      featureName: 'pr0407_dup_target',
      relativePath: 'dup_target.dart',
      content: _buildDuplicateFixture('DupTarget'),
    );

    final result = await harness.runArchitectureCheck();

    expect(result.exitCode, isNonZero);
    expect(result.output, contains('Cross-feature code duplication'));
    expect(result.output, contains('WHAT:'));
    expect(result.output, contains('WHY:'));
    expect(result.output, contains('REFERENCE:'));
    expect(result.output, contains('HOW:'));
  });

  test('suppresses allowlisted duplication pairs', () async {
    harness.writeFeatureFile(
      featureName: 'pr0407_allow_source',
      relativePath: 'dup_source.dart',
      content: _buildDuplicateFixture('AllowSource'),
    );
    harness.writeFeatureFile(
      featureName: 'pr0407_allow_target',
      relativePath: 'dup_target.dart',
      content: _buildDuplicateFixture('AllowTarget'),
    );
    harness.writeDuplicationAllowlist('''
- fileA: "lib/features/pr0407_allow_source/dup_source.dart"
  fileB: "lib/features/pr0407_allow_target/dup_target.dart"
  reason: "fixture allowlist"
''');

    final result = await harness.runArchitectureCheck();

    expect(result.exitCode, 0);
    expect(result.output, contains('Duplication result:'));
    expect(result.output, contains('1 allowlisted pair'));
    expect(
      result.output,
      isNot(contains('Cross-feature code duplication detected')),
    );
  });

  test('prints Rule E guidance for cross-feature imports', () async {
    harness.writeFeatureFile(
      featureName: 'pr0407_rulee_target',
      relativePath: 'target.dart',
      content: 'class RuleETarget {}\n',
    );
    harness.writeFeatureFile(
      featureName: 'pr0407_rulee_source',
      relativePath: 'source.dart',
      content: '''
import 'package:lazynote_flutter/features/pr0407_rulee_target/target.dart';

class RuleESource {
  RuleETarget build() => RuleETarget();
}
''',
    );

    final result = await harness.runArchitectureCheck();

    expect(result.exitCode, isNonZero);
    expect(result.output, contains('Rule E'));
    expect(result.output, contains('REFERENCE:'));
    expect(result.output, contains('HOW:'));
  });

  test('prints structural guidance for manager widget imports', () async {
    harness.writeExistingAppFile(
      'lib/features/notes/managers/pr0407_structural_manager.dart',
      '''
import 'package:flutter/material.dart';

class Pr0407StructuralManager {
  const Pr0407StructuralManager();

  Widget build() => const SizedBox.shrink();
}
''',
    );

    final result = await harness.runArchitectureCheck();

    expect(result.exitCode, isNonZero);
    expect(result.output, contains('managers must be widget-free'));
    expect(result.output, contains('REFERENCE:'));
    expect(result.output, contains('HOW:'));
  });

  test('prints file-size guidance for oversized files', () async {
    harness.writeFeatureFile(
      featureName: 'pr0407_big_file',
      relativePath: 'oversized.dart',
      content: _buildOversizedFixture(),
    );

    final result = await harness.runArchitectureCheck();

    expect(result.exitCode, isNonZero);
    expect(result.output, contains('exceeds 2200'));
    expect(result.output, contains('HOW:'));
  });
}

String _buildDuplicateFixture(String className) {
  final lines = List<String>.generate(
    110,
    (index) =>
        "    buffer.writeln('shared-line-${index.toString().padLeft(3, '0')}');",
  ).join('\n');
  return '''
class $className {
  String build() {
    final buffer = StringBuffer();
$lines
    return buffer.toString();
  }
}
''';
}

String _buildOversizedFixture() {
  final body = List<String>.generate(
    2205,
    (index) => 'class OversizedLine$index {}',
  ).join('\n');
  return '$body\n';
}

class _ArchitectureCheckHarness {
  _ArchitectureCheckHarness()
    : repoRoot = Directory.current.parent.parent,
      appRoot = Directory.current;

  final Directory repoRoot;
  final Directory appRoot;
  final Map<String, String?> _backups = <String, String?>{};
  final Set<String> _createdFeatureDirs = <String>{};

  void writeFeatureFile({
    required String featureName,
    required String relativePath,
    required String content,
  }) {
    final featureDir = Directory('${appRoot.path}/lib/features/$featureName');
    if (!featureDir.existsSync()) {
      featureDir.createSync(recursive: true);
      _createdFeatureDirs.add(featureDir.path);
    }
    _writeFile('${featureDir.path}/$relativePath', content);
  }

  void writeExistingAppFile(String relativePath, String content) {
    _writeFile('${appRoot.path}/$relativePath', content);
  }

  void writeDuplicationAllowlist(String content) {
    _writeFile('${repoRoot.path}/tools/ci/duplication_allowlist.yaml', content);
  }

  Future<_CheckResult> runArchitectureCheck() async {
    final dartExecutable = _resolveDartExecutable();
    final result = await Process.run(dartExecutable, const [
      'run',
      '../../tools/ci/architecture_check.dart',
    ], workingDirectory: appRoot.path);
    final stdoutText = (result.stdout as String?) ?? '';
    final stderrText = (result.stderr as String?) ?? '';
    final output = [
      stdoutText,
      stderrText,
    ].where((part) => part.trim().isNotEmpty).join('\n').trim();
    return _CheckResult(result.exitCode, output);
  }

  String _resolveDartExecutable() {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null && flutterRoot.isNotEmpty) {
      final candidate = File('$flutterRoot/bin/dart.bat');
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }
    return 'dart.bat';
  }

  void dispose() {
    final backupEntries = _backups.entries.toList().reversed;
    for (final entry in backupEntries) {
      final file = File(entry.key);
      final backup = entry.value;
      if (backup == null) {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } else {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(backup);
      }
    }

    final featureDirs = _createdFeatureDirs.toList().reversed;
    for (final dirPath in featureDirs) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    }
  }

  void _writeFile(String filePath, String content) {
    if (!_backups.containsKey(filePath)) {
      final file = File(filePath);
      _backups[filePath] = file.existsSync() ? file.readAsStringSync() : null;
    }
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }
}

class _CheckResult {
  const _CheckResult(this.exitCode, this.output);

  final int exitCode;
  final String output;
}
