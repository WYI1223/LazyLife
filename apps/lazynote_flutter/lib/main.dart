import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:lazynote_flutter/app/app.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';

/// Application entrypoint.
///
/// Startup policy:
/// - Do not block first frame; run bootstrap in background.
/// - Bootstrap order in background: settings init -> Rust logging bootstrap.
/// - Continue app launch even if logging init reports failure.
/// - TODO(vnext): when any setting affects first-frame UI (home route/theme/
///   locale), split settings loading into critical (pre-runApp) and
///   non-critical (background) phases.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_bootstrapLocalRuntime());
  runApp(const LazyNoteApp());
}

Future<void> _bootstrapLocalRuntime() async {
  try {
    await LocalSettingsStore.ensureInitialized();
    await RustBridge.bootstrapLogging();
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
