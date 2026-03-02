import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:lazynote_flutter/app/app.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/reminders/reminder_lifecycle.dart';
import 'package:lazynote_flutter/core/reminders/reminder_scheduler.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';

/// Application entrypoint.
///
/// Startup policy:
/// - Locale-affecting settings are loaded before first frame.
/// - Non-critical bootstrap continues in background.
/// - Background bootstrap order: Rust logging -> reminders init -> startup recovery.
/// - Continue app launch even if logging init reports failure.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapCriticalSettings();

  // S7: initialize lifecycle callbacks before any controller is constructed.
  ReminderLifecycle.initialize(
    ReminderLifecycle(
      onSchedule: (atomId) async {
        try {
          await RustBridge.init();
          final response = await rust_api.noteGet(atomId: atomId);
          if (response.ok && response.item != null) {
            await ReminderScheduler.scheduleReminderForAtom(response.item!);
          }
        } catch (_) {
          // Reminder scheduling must not propagate failures to callers.
        }
      },
      onCancel: (atomId) async {
        try {
          await ReminderScheduler.cancelReminderForAtom(atomId);
        } catch (_) {
          // Reminder cancellation must not propagate failures to callers.
        }
      },
    ),
  );

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
    // S7: startup recovery — re-schedule reminders for all timed atoms
    await ReminderScheduler.recoverOnStartup();
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
