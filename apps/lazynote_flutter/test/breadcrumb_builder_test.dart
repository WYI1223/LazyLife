import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/shared/breadcrumb_builder.dart';

void main() {
  group('formatBreadcrumb', () {
    test('empty path returns default root label', () {
      expect(formatBreadcrumb([]), 'Root');
    });

    test('empty path uses custom root label', () {
      expect(formatBreadcrumb([], rootLabel: '根目录'), '根目录');
    });

    test('single segment returns segment', () {
      expect(formatBreadcrumb(['Projects']), 'Projects');
    });

    test('multiple segments joined with separator', () {
      expect(
        formatBreadcrumb(['Work', 'Engineering', 'Backend']),
        'Work / Engineering / Backend',
      );
    });

    test('two segments joined with separator', () {
      expect(formatBreadcrumb(['Docs', 'Notes']), 'Docs / Notes');
    });
  });
}
