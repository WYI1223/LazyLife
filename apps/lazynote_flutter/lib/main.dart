import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/rust_bridge.dart';

typedef LoadRustHealth = Future<RustHealthSnapshot> Function();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.loadRustHealth = RustBridge.runHealthCheck});

  final LoadRustHealth loadRustHealth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LazyNote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: RustHealthPage(loadRustHealth: loadRustHealth),
    );
  }
}

class RustHealthPage extends StatefulWidget {
  const RustHealthPage({super.key, required this.loadRustHealth});

  final LoadRustHealth loadRustHealth;

  @override
  State<RustHealthPage> createState() => _RustHealthPageState();
}

class _RustHealthPageState extends State<RustHealthPage> {
  late Future<RustHealthSnapshot> _healthFuture;

  @override
  void initState() {
    super.initState();
    _healthFuture = widget.loadRustHealth();
  }

  void _reload() {
    setState(() {
      _healthFuture = widget.loadRustHealth();
    });
  }

  String _buildErrorHint(Object error) {
    final text = error.toString();
    if (text.contains('Failed to load dynamic library')) {
      return '$text\n\nHint: run `cd crates && cargo build -p lazynote_ffi --release` first.';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LazyNote FRB Smoke')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<RustHealthSnapshot>(
            future: _healthFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing Rust bridge...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 40,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rust bridge initialization failed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildErrorHint(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
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
                  const Text(
                    'Rust bridge connected',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('ping: ${health.ping}'),
                  Text('coreVersion: ${health.coreVersion}'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _reload,
                    child: const Text('Refresh'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
