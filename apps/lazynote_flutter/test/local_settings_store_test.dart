import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';
import 'package:lazynote_flutter/core/settings/ui_language.dart';

void main() {
  tearDown(() {
    LocalSettingsStore.resetForTesting();
  });

  test('creates default settings.json when missing', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;

    await LocalSettingsStore.ensureInitialized();

    final file = File(settingsPath);
    expect(await file.exists(), isTrue);
    final content = await file.readAsString();
    expect(content, contains('"schema_version": 1'));
    expect(content, contains('"result_limit": 10'));
    expect(content, contains('"use_single_entry_as_home": false'));
    expect(content, contains('"collapsed_height": 72'));
    expect(content, contains('"expanded_max_height": 420'));
    expect(content, contains('"animation_ms": 180'));
    expect(content, contains('"language": "system"'));
  });

  test('backfills missing keys without overriding existing values', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    final existing = File(settingsPath);
    await existing.parent.create(recursive: true);
    await existing.writeAsString('''
{
  "schema_version": 1,
  "custom": true,
  "entry": {
    "result_limit": 25
  }
}
''');

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    final content = await existing.readAsString();
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    expect(decoded['custom'], isTrue);
    expect(decoded['schema_version'], 1);

    final entry = decoded['entry'] as Map<String, dynamic>;
    expect(entry['result_limit'], 25);
    expect(entry['use_single_entry_as_home'], isFalse);
    expect(entry['expand_on_focus'], isTrue);

    final ui = entry['ui'] as Map<String, dynamic>;
    expect(ui['collapsed_height'], 72);
    expect(ui['expanded_max_height'], 420);
    expect(ui['animation_ms'], 180);

    final logging = decoded['logging'] as Map<String, dynamic>;
    expect(logging.containsKey('level_override'), isTrue);
    final uiRoot = decoded['ui'] as Map<String, dynamic>;
    expect(uiRoot['language'], 'system');
  });

  test('loads entry ui tuning from existing settings file', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    final existing = File(settingsPath);
    await existing.parent.create(recursive: true);
    await existing.writeAsString('''
{
  "schema_version": 1,
  "entry": {
    "result_limit": 10,
    "use_single_entry_as_home": false,
    "expand_on_focus": true,
    "ui": {
      "collapsed_height": 80,
      "expanded_max_height": 500,
      "animation_ms": 220
    }
  }
}
''');

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    expect(LocalSettingsStore.entryUiTuning.collapsedHeight, 80);
    expect(LocalSettingsStore.entryUiTuning.expandedMaxHeight, 500);
    expect(LocalSettingsStore.entryUiTuning.animationMs, 220);
    expect(LocalSettingsStore.loggingLevelOverride, isNull);
  });

  test(
    'loads validated logging level override as persisted-only field',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lazynote-settings-',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final settingsPath =
          '${tempDir.path}${Platform.pathSeparator}settings.json';
      final existing = File(settingsPath);
      await existing.parent.create(recursive: true);
      await existing.writeAsString('''
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
    "level_override": "debug"
  }
}
''');

      LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
      await LocalSettingsStore.ensureInitialized();

      expect(LocalSettingsStore.loggingLevelOverride, 'debug');
    },
  );

  test('invalid logging level override falls back to null', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    final existing = File(settingsPath);
    await existing.parent.create(recursive: true);
    await existing.writeAsString('''
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
    "level_override": "verbose"
  }
}
''');

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    expect(LocalSettingsStore.loggingLevelOverride, isNull);
  });

  test('loads ui.language from settings file', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    final existing = File(settingsPath);
    await existing.parent.create(recursive: true);
    await existing.writeAsString('''
{
  "schema_version": 1,
  "entry": {
    "ui": {
      "collapsed_height": 72,
      "expanded_max_height": 420,
      "animation_ms": 180
    }
  },
  "ui": {
    "language": "zh-CN"
  }
}
''');

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    expect(LocalSettingsStore.uiLanguage, UiLanguage.zhCn);
  });

  test('saveUiLanguage persists value to settings file', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    final persisted = await LocalSettingsStore.saveUiLanguage(UiLanguage.en);
    expect(persisted, isTrue);
    expect(LocalSettingsStore.uiLanguage, UiLanguage.en);

    final decoded =
        jsonDecode(await File(settingsPath).readAsString())
            as Map<String, dynamic>;
    final uiRoot = decoded['ui'] as Map<String, dynamic>;
    expect(uiRoot['language'], 'en');
  });

  test('schema_version > 1 falls back to defaults', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    final existing = File(settingsPath);
    await existing.parent.create(recursive: true);
    await existing.writeAsString('''
{
  "schema_version": 999,
  "entry": {
    "ui": {
      "collapsed_height": 100,
      "expanded_max_height": 600,
      "animation_ms": 300
    }
  },
  "logging": {
    "level_override": "trace"
  }
}
''');

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    expect(LocalSettingsStore.entryUiTuning.collapsedHeight, 72);
    expect(LocalSettingsStore.entryUiTuning.expandedMaxHeight, 420);
    expect(LocalSettingsStore.entryUiTuning.animationMs, 180);
    expect(LocalSettingsStore.loggingLevelOverride, isNull);
    expect(LocalSettingsStore.uiLanguage, UiLanguage.system);
  });

  test('schema_version > 1 does not rewrite settings file', () async {
    final tempDir = await Directory.systemTemp.createTemp('lazynote-settings-');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final settingsPath =
        '${tempDir.path}${Platform.pathSeparator}settings.json';
    final existing = File(settingsPath);
    await existing.parent.create(recursive: true);
    final original = '''
{
  "schema_version": 999,
  "custom_future_flag": true,
  "entry": {}
}
''';
    await existing.writeAsString(original);

    LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
    await LocalSettingsStore.ensureInitialized();

    final after = await existing.readAsString();
    expect(after, original);
  });

  test(
    'recovers settings from leftover temp file when settings.json is missing',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lazynote-settings-',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final settingsPath =
          '${tempDir.path}${Platform.pathSeparator}settings.json';
      final recovery = File('$settingsPath.tmp.123');
      await recovery.parent.create(recursive: true);
      await recovery.writeAsString('''
{
  "schema_version": 1,
  "entry": {
    "ui": {
      "collapsed_height": 88,
      "expanded_max_height": 500,
      "animation_ms": 210
    }
  },
  "logging": {
    "level_override": "debug"
  }
}
''');

      LocalSettingsStore.settingsFilePathResolver = () async => settingsPath;
      await LocalSettingsStore.ensureInitialized();

      expect(await File(settingsPath).exists(), isTrue);
      expect(await recovery.exists(), isFalse);
      expect(LocalSettingsStore.entryUiTuning.collapsedHeight, 88);
      expect(LocalSettingsStore.entryUiTuning.expandedMaxHeight, 500);
      expect(LocalSettingsStore.entryUiTuning.animationMs, 210);
      expect(LocalSettingsStore.loggingLevelOverride, 'debug');
    },
  );
}
