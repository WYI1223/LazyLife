import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

/// Standalone diagnostics page wrapper.
class RustDiagnosticsPage extends StatelessWidget {
  const RustDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workbenchSectionRustDiagnostics)),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: RustDiagnosticsContent(),
        ),
      ),
    );
  }
}

/// Reusable diagnostics content that can be embedded in Workbench left pane.
class RustDiagnosticsContent extends StatefulWidget {
  const RustDiagnosticsContent({super.key});

  @override
  State<RustDiagnosticsContent> createState() => _RustDiagnosticsContentState();
}

class _RustDiagnosticsContentState extends State<RustDiagnosticsContent> {
  late Future<RustHealthSnapshot> _healthFuture;

  @override
  void initState() {
    super.initState();
    _healthFuture = RustBridge.runHealthCheck();
  }

  void _reload() {
    setState(() {
      _healthFuture = RustBridge.runHealthCheck();
    });
  }

  String _buildErrorHint(Object error) {
    final text = error.toString();
    if (text.contains('Failed to load dynamic library')) {
      return '$text\n\nHint: run `cd crates && cargo build -p lazynote_ffi --release` first.';
    }
    return text;
  }

  Widget _buildLoggingStatus() {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = RustBridge.latestLoggingInitSnapshot;
    if (snapshot == null) {
      return Text(l10n.loggingInitStatusNotAttempted);
    }

    final statusText = snapshot.isSuccess ? 'ok' : 'error';
    final errorText = snapshot.errorMessage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.loggingInitStatusValue(statusText)),
            Text(l10n.loggingInitLevelValue(snapshot.level)),
            Text(l10n.loggingInitLogDirValue(snapshot.logDir)),
            if (errorText != null) Text(l10n.loggingInitErrorValue(errorText)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<RustHealthSnapshot>(
      future: _healthFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.rustDiagnosticsInitializing),
              const SizedBox(height: 16),
              _buildLoggingStatus(),
            ],
          );
        }

        if (snapshot.hasError) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                l10n.rustDiagnosticsInitFailed,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _buildErrorHint(snapshot.error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _reload, child: Text(l10n.retryButton)),
              const SizedBox(height: 16),
              _buildLoggingStatus(),
            ],
          );
        }

        final health = snapshot.data!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.rustDiagnosticsConnected,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(l10n.rustDiagnosticsPingValue(health.ping)),
            Text(l10n.rustDiagnosticsCoreVersionValue(health.coreVersion)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: Text(l10n.refreshButton)),
            const SizedBox(height: 16),
            _buildLoggingStatus(),
          ],
        );
      },
    );
  }
}
