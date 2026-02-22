/// Supported UI language values persisted in local settings.
enum UiLanguage {
  system,
  en,
  zhCn;

  /// Stable persisted value in `settings.json`.
  String get storageValue {
    return switch (this) {
      UiLanguage.system => 'system',
      UiLanguage.en => 'en',
      UiLanguage.zhCn => 'zh-CN',
    };
  }

  /// Parses persisted value into known language enum.
  static UiLanguage parse(Object? value) {
    if (value is! String) {
      return UiLanguage.system;
    }

    final normalized = value.trim();
    return switch (normalized) {
      'en' => UiLanguage.en,
      'zh-CN' || 'zh_CN' || 'zh-cn' || 'zh' => UiLanguage.zhCn,
      'system' => UiLanguage.system,
      _ => UiLanguage.system,
    };
  }
}
