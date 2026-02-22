import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:lazynote_flutter/app/app.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';
import 'package:lazynote_flutter/features/reminders/reminder_scheduler.dart';

/// Application entrypoint.
///
/// Startup policy:
/// - Locale-affecting settings are loaded before first frame.
/// - Non-critical bootstrap continues in background.
/// - Background bootstrap order: Rust logging bootstrap -> reminders init.
/// - Continue app launch even if logging init reports failure.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapCriticalSettings();
  final localeController = AppLocaleController(
    initialLanguage: LocalSettingsStore.uiLanguage,
  );
  unawaited(_bootstrapLocalRuntime());
  runApp(LazyNoteApp(localeController: localeController));
}

Future<void> _bootstrapCriticalSettings() async {
  try {
    await LocalSettingsStore.ensureInitialized();
  } catch (error, stackTrace) {
    // Why: locale resolution should be best-effort and never block app launch.
    dev.log(
      'Critical settings bootstrap failed; continuing with defaults.',
      name: 'Main',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

Future<void> _bootstrapLocalRuntime() async {
  try {
    await RustBridge.bootstrapLogging();
    await ReminderScheduler.ensureInitialized();
  } catch (error, stackTrace) {
    // Why: startup bootstrap must remain non-fatal and never block first frame.
    dev.log(
      'Unexpected bootstrap failure in local runtime startup.',
      name: 'Main',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
