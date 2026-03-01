/// CI architecture guardrail script for LazyNote Flutter app.
///
/// Checks:
/// 1. Rule E — cross-feature imports in `lib/features/`
/// 2. File size — warning >1,500 lines, failure >2,200 lines
/// 3. Structural layer — managers must not import widgets, coordinator
///    must not import FFI bindings directly
/// 4. Docs cross-reference — broken markdown links in `docs/`
///
/// Usage (from `apps/lazynote_flutter/`):
///   dart run ../../tools/ci/architecture_check.dart
///
/// Exit code 0 = pass, 1 = violations found.
import 'dart:io';

// ---------------------------------------------------------------------------
// Configuration
// ---------------------------------------------------------------------------

/// App root resolved relative to this script's location.
final Directory _appRoot = () {
  // Script lives at tools/ci/architecture_check.dart.
  // App root is ../../apps/lazynote_flutter relative to script.
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = scriptDir.parent.parent;
  return Directory('${repoRoot.path}/apps/lazynote_flutter');
}();

final Directory _libDir = Directory('${_appRoot.path}/lib');
final Directory _featuresDir = Directory('${_appRoot.path}/lib/features');

const int _warnLineThreshold = 1500;
const int _failLineThreshold = 2200;

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  if (!_featuresDir.existsSync()) {
    stderr.writeln(
      'ERROR: features directory not found at ${_featuresDir.path}',
    );
    exit(1);
  }

  final ruleEAllowlist = _loadRuleEAllowlist();
  final fileSizeExemptions = _loadFileSizeExemptions();

  var hasFailure = false;

  // ── Check 1: Rule E ────────────────────────────────────────────────────
  stdout.writeln('=== Rule E: cross-feature imports ===');
  final violations = _checkRuleE(ruleEAllowlist);
  if (violations.isNotEmpty) {
    for (final v in violations) {
      stderr.writeln('VIOLATION: ${v.file}  imports  ${v.importPath}');
      stderr.writeln('  feature pair: ${v.sourceFeature} → ${v.targetFeature}');
    }
    hasFailure = true;
  }

  final allowedCount = _countAllowlisted(ruleEAllowlist);
  stdout.writeln(
    'Rule E result: ${violations.length} violation(s), '
    '$allowedCount allowlisted exemption(s)',
  );

  // ── Check 2: File size ─────────────────────────────────────────────────
  stdout.writeln('\n=== File size check ===');
  final sizeResult = _checkFileSize(fileSizeExemptions);
  if (sizeResult.hasFailure) {
    hasFailure = true;
  }
  stdout.writeln(
    'File size result: ${sizeResult.warnings} warning(s), '
    '${sizeResult.failures} failure(s), '
    '${sizeResult.exemptions} exemption(s)',
  );

  // ── Check 3: Structural layer ──────────────────────────────────────────
  stdout.writeln('\n=== Structural layer check ===');
  final structuralViolations = _checkStructuralLayer();
  if (structuralViolations.isNotEmpty) {
    for (final msg in structuralViolations) {
      stderr.writeln('VIOLATION: $msg');
    }
    hasFailure = true;
  }
  stdout.writeln(
    'Structural layer result: ${structuralViolations.length} violation(s)',
  );

  // ── Check 4: Docs cross-reference ──────────────────────────────────────
  stdout.writeln('\n=== Docs cross-reference check ===');
  final docsLinkAllowlist = _loadDocsLinkAllowlist();
  final docsResult = _checkDocsCrossReferences(docsLinkAllowlist);
  if (docsResult.failures > 0) {
    hasFailure = true;
  }
  stdout.writeln(
    'Docs link result: ${docsResult.failures} broken link(s), '
    '${docsResult.warnings} warning(s), '
    '${docsResult.allowlisted} allowlisted',
  );

  // ── Summary ────────────────────────────────────────────────────────────
  stdout.writeln('\n=== Summary ===');
  if (hasFailure) {
    stderr.writeln('FAILED — architecture violations detected.');
    exit(1);
  } else {
    stdout.writeln('PASSED — no architecture violations.');
  }
}

// ---------------------------------------------------------------------------
// Rule E check
// ---------------------------------------------------------------------------

class _RuleEViolation {
  final String file;
  final String importPath;
  final String sourceFeature;
  final String targetFeature;

  _RuleEViolation({
    required this.file,
    required this.importPath,
    required this.sourceFeature,
    required this.targetFeature,
  });
}

/// Legal import prefixes for files under `lib/features/`.
/// Anything matching these is NOT a cross-feature violation.
final _legalPrefixes = [
  'dart:',
  'package:flutter',
  'package:lazynote_flutter/core/',
  'package:lazynote_flutter/shared/',
  'package:lazynote_flutter/app/',
  'package:lazynote_flutter/l10n/',
];

List<_RuleEViolation> _checkRuleE(Map<String, Set<String>> allowlist) {
  final violations = <_RuleEViolation>[];
  final featureDirs = _featuresDir.listSync().whereType<Directory>().toList();

  for (final featureDir in featureDirs) {
    final featureName = featureDir.path.split('/').last.split(r'\').last;
    final dartFiles = featureDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ') &&
            !trimmed.startsWith("import '") &&
            !trimmed.startsWith('import "')) {
          continue;
        }

        final importPath = _extractImportPath(trimmed);
        if (importPath == null) continue;

        // Skip legal imports.
        if (_isLegalImport(importPath, featureName, file.path)) continue;

        // Check if it's a cross-feature import (package: or resolved relative).
        final targetFeature =
            _extractTargetFeature(importPath) ??
            _extractTargetFeatureFromRelative(file.path, importPath);
        if (targetFeature == null) continue;
        if (targetFeature == featureName) continue;

        // Check allowlist.
        final pair = '$featureName → $targetFeature';
        if (allowlist.containsKey(pair)) continue;

        final relPath = _relativePath(file.path);
        violations.add(
          _RuleEViolation(
            file: relPath,
            importPath: importPath,
            sourceFeature: featureName,
            targetFeature: targetFeature,
          ),
        );
      }
    }
  }

  return violations;
}

String? _extractImportPath(String line) {
  // import 'path'; or import "path";
  final singleQuote = RegExp(r"import\s+'([^']+)'");
  final doubleQuote = RegExp(r'import\s+"([^"]+)"');
  final match = singleQuote.firstMatch(line) ?? doubleQuote.firstMatch(line);
  return match?.group(1);
}

bool _isLegalImport(String importPath, String featureName, String filePath) {
  for (final prefix in _legalPrefixes) {
    if (importPath.startsWith(prefix)) return true;
  }
  // Relative imports: resolve against the file's directory and check
  // whether the resolved path lands inside a different feature.
  if (!importPath.startsWith('package:')) {
    final resolved = _resolveRelativeImport(filePath, importPath);
    if (resolved != null) {
      final target = _extractTargetFeatureFromPath(resolved);
      if (target != null && target != featureName) {
        return false; // Cross-feature relative import.
      }
    }
    return true;
  }
  // Same-feature package imports are legal.
  if (importPath.startsWith(
    'package:lazynote_flutter/features/$featureName/',
  )) {
    return true;
  }
  // Third-party packages (not lazynote_flutter) are legal.
  if (importPath.startsWith('package:') &&
      !importPath.startsWith('package:lazynote_flutter/')) {
    return true;
  }
  return false;
}

String? _extractTargetFeature(String importPath) {
  final match = RegExp(
    r'package:lazynote_flutter/features/([^/]+)/',
  ).firstMatch(importPath);
  return match?.group(1);
}

/// Resolves a relative import path against the importing file's directory.
/// Returns a normalized absolute path, or null if resolution fails.
String? _resolveRelativeImport(String filePath, String importPath) {
  final normalized = filePath.replaceAll(r'\', '/');
  final lastSlash = normalized.lastIndexOf('/');
  if (lastSlash < 0) return null;
  final dir = normalized.substring(0, lastSlash);
  // Normalize by resolving .. and .
  final segments = '$dir/$importPath'.split('/');
  final resolved = <String>[];
  for (final seg in segments) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else {
      resolved.add(seg);
    }
  }
  return resolved.join('/');
}

/// Extracts a feature name from a resolved absolute file path.
String? _extractTargetFeatureFromPath(String resolvedPath) {
  final normalized = resolvedPath.replaceAll(r'\', '/');
  final marker = '/lib/features/';
  final idx = normalized.indexOf(marker);
  if (idx < 0) return null;
  final afterMarker = normalized.substring(idx + marker.length);
  final slash = afterMarker.indexOf('/');
  if (slash < 0) return null;
  return afterMarker.substring(0, slash);
}

/// Extracts a target feature from a relative import by resolving it first.
String? _extractTargetFeatureFromRelative(String filePath, String importPath) {
  final resolved = _resolveRelativeImport(filePath, importPath);
  if (resolved == null) return null;
  return _extractTargetFeatureFromPath(resolved);
}

int _countAllowlisted(Map<String, Set<String>> allowlist) {
  return allowlist.length;
}

// ---------------------------------------------------------------------------
// File size check
// ---------------------------------------------------------------------------

class _FileSizeResult {
  int warnings = 0;
  int failures = 0;
  int exemptions = 0;
  bool hasFailure = false;
}

_FileSizeResult _checkFileSize(Set<String> exemptions) {
  final result = _FileSizeResult();
  final dartFiles = _libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final lineCount = file.readAsLinesSync().length;
    final relPath = _relativePath(file.path);

    if (lineCount > _failLineThreshold) {
      if (exemptions.contains(relPath)) {
        stdout.writeln(
          '  EXEMPTED: $relPath ($lineCount lines, exceeds $_failLineThreshold)',
        );
        result.exemptions++;
      } else {
        stderr.writeln(
          '  FAIL: $relPath ($lineCount lines, exceeds $_failLineThreshold)',
        );
        result.failures++;
        result.hasFailure = true;
      }
    } else if (lineCount > _warnLineThreshold) {
      if (exemptions.contains(relPath)) {
        stdout.writeln(
          '  EXEMPTED: $relPath ($lineCount lines, exceeds $_warnLineThreshold)',
        );
        result.exemptions++;
      } else {
        stdout.writeln(
          '  WARNING: $relPath ($lineCount lines, exceeds $_warnLineThreshold)',
        );
        result.warnings++;
      }
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// Structural layer check
// ---------------------------------------------------------------------------

List<String> _checkStructuralLayer() {
  final violations = <String>[];

  // Rule: managers/ files must not import Flutter widgets.
  final managersDir = Directory('${_featuresDir.path}/notes/managers');
  if (managersDir.existsSync()) {
    for (final file
        in managersDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ')) continue;
        final path = _extractImportPath(trimmed);
        if (path == null) continue;
        if (path == 'package:flutter/material.dart' ||
            path == 'package:flutter/widgets.dart' ||
            path == 'package:flutter/cupertino.dart') {
          violations.add(
            '${_relativePath(file.path)} imports Flutter widgets ($path) '
            '— managers must be widget-free',
          );
        }
      }
    }
  }

  // Rule: coordinator must not import raw FRB bindings directly.
  // Allowed: api.dart (response types for invoker typedefs),
  //          rust_bridge.dart (facade used for default `prepare` callback).
  // Forbidden: frb_generated.dart / frb_generated.io.dart (raw FRB layer).
  // Check both the library file and part file.
  final coordFiles = [
    File('${_featuresDir.path}/notes/notes_coordinator.dart'),
    File('${_featuresDir.path}/notes/notes_coordinator_impl.dart'),
  ];
  for (final coordFile in coordFiles) {
    if (!coordFile.existsSync()) continue;
    final lines = coordFile.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('import ')) continue;
      final path = _extractImportPath(trimmed);
      if (path == null) continue;
      if (path.contains('frb_generated')) {
        violations.add(
          '${_relativePath(coordFile.path)} imports raw FRB bindings ($path) '
          '— coordinator should use injected invokers',
        );
      }
    }
  }

  return violations;
}

// ---------------------------------------------------------------------------
// Docs cross-reference check (Check 4)
// ---------------------------------------------------------------------------

final Directory _repoRoot = () {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  return scriptDir.parent.parent;
}();

final Directory _docsDir = Directory('${_repoRoot.path}/docs');

/// Regex to extract markdown links: [text](path)
/// Captures the path portion, ignoring anchor fragments.
final RegExp _mdLinkPattern = RegExp(r'\[([^\]]*)\]\(([^)#\s]+)');

class _DocsLinkResult {
  int failures = 0;
  int warnings = 0;
  int allowlisted = 0;
}

_DocsLinkResult _checkDocsCrossReferences(List<String> allowlistPatterns) {
  final result = _DocsLinkResult();

  if (!_docsDir.existsSync()) {
    stderr.writeln('WARNING: docs/ directory not found, skipping Check 4');
    return result;
  }

  final mdFiles = _docsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'));

  for (final file in mdFiles) {
    final filePath = file.path.replaceAll(r'\', '/');
    final fileDir = filePath.substring(0, filePath.lastIndexOf('/'));
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      for (final match in _mdLinkPattern.allMatches(lines[i])) {
        final linkTarget = match.group(2)!;

        // Skip external URLs, mailto, and file: protocol.
        if (linkTarget.startsWith('http://') ||
            linkTarget.startsWith('https://') ||
            linkTarget.startsWith('mailto:') ||
            linkTarget.startsWith('file:')) {
          continue;
        }

        // Skip bare placeholder words (no path separator or extension).
        // These appear in template/example markdown like [text](url).
        if (!linkTarget.contains('/') && !linkTarget.contains('.')) {
          continue;
        }

        // Resolve relative path from the file's directory.
        final resolved = _resolveDocsPath(fileDir, linkTarget);
        if (resolved == null) continue;

        // Check allowlist patterns.
        if (_isAllowlisted(resolved, allowlistPatterns)) {
          result.allowlisted++;
          continue;
        }

        // Check if target exists.
        final targetFile = File(resolved);
        final targetDir = Directory(resolved);
        if (targetFile.existsSync() || targetDir.existsSync()) {
          continue;
        }

        // For PR specs under releases/ referencing apps/ or lib/ code paths,
        // emit warning instead of failure (code may not exist yet).
        final relFile = _repoRelativePath(filePath);
        final relTarget = _repoRelativePath(resolved);
        if (relFile.startsWith('docs/releases/') &&
            (relTarget.startsWith('apps/') || relTarget.startsWith('lib/'))) {
          stdout.writeln(
            '  WARNING: $relFile:${i + 1} → $relTarget (code path, may not exist yet)',
          );
          result.warnings++;
          continue;
        }

        stderr.writeln('  BROKEN: $relFile:${i + 1} → $relTarget');
        result.failures++;
      }
    }
  }

  return result;
}

/// Resolves a relative link path from a file's directory to an absolute path.
String? _resolveDocsPath(String fileDir, String linkTarget) {
  final segments = '$fileDir/$linkTarget'.split('/');
  final resolved = <String>[];
  for (final seg in segments) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (resolved.isNotEmpty) resolved.removeLast();
    } else {
      resolved.add(seg);
    }
  }
  if (resolved.isEmpty) return null;
  return resolved.join('/');
}

/// Checks if a resolved path matches any allowlist glob pattern.
bool _isAllowlisted(String resolvedPath, List<String> patterns) {
  final relPath = _repoRelativePath(resolvedPath);
  for (final pattern in patterns) {
    if (_globMatch(relPath, pattern)) return true;
  }
  return false;
}

/// Simple glob matching supporting ** (any path segments) and * (single segment).
bool _globMatch(String path, String pattern) {
  // Convert glob to regex.
  var regexStr = '^';
  for (var i = 0; i < pattern.length; i++) {
    if (pattern[i] == '*' && i + 1 < pattern.length && pattern[i + 1] == '*') {
      regexStr += '.*';
      // Skip the next * and optional following /
      i++;
      if (i + 1 < pattern.length && pattern[i + 1] == '/') i++;
    } else if (pattern[i] == '*') {
      regexStr += '[^/]*';
    } else if (pattern[i] == '.') {
      regexStr += r'\.';
    } else {
      regexStr += pattern[i];
    }
  }
  // Allow matching files within directory patterns (e.g., pattern ending with /).
  if (pattern.endsWith('/')) {
    regexStr += '.*';
  }
  regexStr += r'$';
  return RegExp(regexStr).hasMatch(path);
}

/// Returns path relative to repo root.
String _repoRelativePath(String absolutePath) {
  final normalized = absolutePath.replaceAll(r'\', '/');
  final root = _repoRoot.path.replaceAll(r'\', '/');
  if (normalized.startsWith('$root/')) {
    return normalized.substring(root.length + 1);
  }
  return normalized;
}

// ---------------------------------------------------------------------------
// Config loaders
// ---------------------------------------------------------------------------

/// Parses rule_e_allowlist.yaml — expects lines like:
///   - pair: "notes → workspace"
Map<String, Set<String>> _loadRuleEAllowlist() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final file = File('${scriptDir.path}/rule_e_allowlist.yaml');
  if (!file.existsSync()) return {};

  final result = <String, Set<String>>{};
  String? currentPair;
  String? currentReason;

  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- pair:')) {
      // Flush previous entry.
      if (currentPair != null) {
        result[currentPair] = {currentReason ?? ''};
      }
      currentPair = _stripYamlString(trimmed.substring('- pair:'.length));
      currentReason = null;
    } else if (trimmed.startsWith('reason:') && currentPair != null) {
      currentReason = _stripYamlString(trimmed.substring('reason:'.length));
    }
  }
  // Flush last entry.
  if (currentPair != null) {
    result[currentPair] = {currentReason ?? ''};
  }
  return result;
}

/// Parses file_size_exemptions.yaml — expects lines like:
///   - path: "lib/features/notes/note_explorer.dart"
Set<String> _loadFileSizeExemptions() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final file = File('${scriptDir.path}/file_size_exemptions.yaml');
  if (!file.existsSync()) return {};

  final result = <String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- path:')) {
      final path = _stripYamlString(trimmed.substring('- path:'.length));
      if (path.isNotEmpty) result.add(path);
    }
  }
  return result;
}

/// Parses docs_link_allowlist.yaml — expects lines like:
///   - pattern: "docs/reports/**/artifacts/"
List<String> _loadDocsLinkAllowlist() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final file = File('${scriptDir.path}/docs_link_allowlist.yaml');
  if (!file.existsSync()) return [];

  final result = <String>[];
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('- pattern:')) {
      final pattern = _stripYamlString(trimmed.substring('- pattern:'.length));
      if (pattern.isNotEmpty) result.add(pattern);
    }
  }
  return result;
}

/// Strips surrounding quotes and whitespace from a YAML value.
String _stripYamlString(String raw) {
  var s = raw.trim();
  if ((s.startsWith('"') && s.endsWith('"')) ||
      (s.startsWith("'") && s.endsWith("'"))) {
    s = s.substring(1, s.length - 1);
  }
  return s.trim();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _relativePath(String absolutePath) {
  final normalized = absolutePath.replaceAll(r'\', '/');
  final root = _appRoot.path.replaceAll(r'\', '/');
  if (normalized.startsWith(root)) {
    return normalized.substring(root.length + 1);
  }
  return normalized;
}
