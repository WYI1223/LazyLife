import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lazynote_flutter/app/app.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';

/// Application entrypoint.
///
/// Startup policy:
/// - Attempt logging bootstrap first.
/// - Do not block first frame; run bootstrap in background.
/// - Continue app launch even if logging init reports failure.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(RustBridge.bootstrapLogging());
  runApp(const LazyNoteApp());
}
