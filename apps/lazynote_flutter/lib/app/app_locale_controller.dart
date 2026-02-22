import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';
import 'package:lazynote_flutter/core/settings/ui_language.dart';

/// Runtime locale controller for app-level language switching.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController({UiLanguage initialLanguage = UiLanguage.system})
    : _language = initialLanguage;

  UiLanguage _language;

  /// Current language preference value.
  UiLanguage get language => _language;

  /// Effective locale override used by [MaterialApp.locale].
  ///
  /// `null` means follow platform/system locale.
  Locale? get localeOverride {
    return switch (_language) {
      UiLanguage.system => null,
      UiLanguage.en => const Locale('en'),
      UiLanguage.zhCn => const Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    };
  }

  /// Applies and persists a new language value.
  ///
  /// Returns `true` when persistence succeeds; returns `false` and reverts
  /// in-memory language when persistence fails.
  Future<bool> setLanguage(UiLanguage nextLanguage) async {
    if (nextLanguage == _language) {
      return true;
    }

    final previousLanguage = _language;
    _language = nextLanguage;
    notifyListeners();

    final persisted = await LocalSettingsStore.saveUiLanguage(nextLanguage);
    if (persisted) {
      return true;
    }

    _language = previousLanguage;
    notifyListeners();
    return false;
  }
}
