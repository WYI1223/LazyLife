import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;
import 'package:lazynote_flutter/core/bindings/frb_generated.dart';

class RustHealthSnapshot {
  const RustHealthSnapshot({required this.ping, required this.coreVersion});

  final String ping;
  final String coreVersion;
}

class RustBridge {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }

    await RustLib.init();
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
