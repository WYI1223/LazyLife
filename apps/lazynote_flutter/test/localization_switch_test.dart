import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';
import 'package:lazynote_flutter/core/settings/ui_language.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

Future<String> _createTempSettingsPath() async {
  final tempDir = await Directory.systemTemp.createTemp(
    'lazynote-locale-switch-',
  );
  return '${tempDir.path}${Platform.pathSeparator}settings.json';
}

Future<void> _writeSettings({
  required String path,
  required String language,
  int schemaVersion = 1,
}) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString('''
{
  "schema_version": $schemaVersion,
  "entry": {
    "ui": {
      "collapsed_height": 72,
      "expanded_max_height": 420,
      "animation_ms": 180
    }
  },
  "ui": {
    "language": "$language"
  }
}
''');
}

class _LocaleProbeApp extends StatelessWidget {
  const _LocaleProbeApp({required this.controller});

  final AppLocaleController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: controller.localeOverride,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Text(
                  l10n.lazyNoteWorkbenchTitle,
                  key: const Key('locale_probe_title'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> _pumpProbe(
  WidgetTester tester, {
  required AppLocaleController controller,
}) async {
  await tester.pumpWidget(_LocaleProbeApp(controller: controller));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

void main() {
  tearDown(() {
    LocalSettingsStore.resetForTesting();
  });

  testWidgets('runtime switch updates app strings and persists preference', (
    tester,
  ) async {
    final settingsPath = await tester.runAsync(_createTempSettingsPath);
    if (settingsPath == null) {
      fail('Failed to create temp settings path.');
    }
    addTearDown(() async {
      final dir = Directory(File(settingsPath).parent.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    await tester.runAsync(() async {
      await _writeSettings(path: settingsPath, language: 'en');
      LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
      await LocalSettingsStore.ensureInitialized();
    });

    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(dispatcher.clearLocaleTestValue);

    final controller = AppLocaleController(
      initialLanguage: LocalSettingsStore.uiLanguage,
    );
    addTearDown(controller.dispose);

    await _pumpProbe(tester, controller: controller);
    expect(find.text('LazyNote Workbench'), findsOneWidget);

    final switched = await tester.runAsync(
      () => controller.setLanguage(UiLanguage.zhCn),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(switched, isTrue);
    expect(find.text('LazyNote 工作台'), findsOneWidget);
    expect(find.text('LazyNote Workbench'), findsNothing);

    final decoded =
        jsonDecode(
              await tester.runAsync(() => File(settingsPath).readAsString()) ??
                  '{}',
            )
            as Map<String, dynamic>;
    final uiRoot = decoded['ui'] as Map<String, dynamic>;
    expect(uiRoot['language'], 'zh-CN');
  });

  testWidgets('runtime switch rolls back when persistence fails', (
    tester,
  ) async {
    final settingsPath = await tester.runAsync(_createTempSettingsPath);
    if (settingsPath == null) {
      fail('Failed to create temp settings path.');
    }
    addTearDown(() async {
      final dir = Directory(File(settingsPath).parent.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });

    // schema_version > 1 keeps file immutable and causes saveUiLanguage=false.
    await tester.runAsync(() async {
      await _writeSettings(
        path: settingsPath,
        language: 'system',
        schemaVersion: 999,
      );
      LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
      await LocalSettingsStore.ensureInitialized();
    });

    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(dispatcher.clearLocaleTestValue);

    final controller = AppLocaleController(
      initialLanguage: LocalSettingsStore.uiLanguage,
    );
    addTearDown(controller.dispose);

    await _pumpProbe(tester, controller: controller);
    expect(find.text('LazyNote Workbench'), findsOneWidget);

    final switched = await tester.runAsync(
      () => controller.setLanguage(UiLanguage.zhCn),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(switched, isFalse);
    expect(controller.language, UiLanguage.system);
    expect(find.text('LazyNote Workbench'), findsOneWidget);
    expect(find.text('LazyNote 工作台'), findsNothing);
  });
}
