import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/bindings/frb_generated.dart';

class RustHealthSnapshot {
  const RustHealthSnapshot({required this.ping, required this.coreVersion});

  final String ping;
  final String coreVersion;
}

class RustBridge {
  static bool _initialized = false;

  static ExternalLibrary? _resolveWorkspaceLibrary() {
    final dynamicLibraryFileName = switch (Platform.operatingSystem) {
      'windows' => 'lazynote_ffi.dll',
      'linux' => 'liblazynote_ffi.so',
      'macos' => 'liblazynote_ffi.dylib',
      _ => null,
    };

    if (dynamicLibraryFileName == null) {
      return null;
    }

    final candidates = <String>[
      '../../crates/target/release/$dynamicLibraryFileName',
      '../../crates/lazynote_ffi/target/release/$dynamicLibraryFileName',
    ];

    for (final relativePath in candidates) {
      final filePath = Directory.current.uri.resolve(relativePath).toFilePath();
      if (File(filePath).existsSync()) {
        return ExternalLibrary.open(filePath);
      }
    }

    return null;
  }

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    final externalLibrary = _resolveWorkspaceLibrary();
    if (externalLibrary != null) {
      await RustLib.init(externalLibrary: externalLibrary);
    } else {
      await RustLib.init();
    }

    _initialized = true;
  }

  static Future<RustHealthSnapshot> runHealthCheck() async {
    await init();
    return RustHealthSnapshot(
      ping: rust_api.ping(),
      coreVersion: rust_api.coreVersion(),
    );
  }
}
