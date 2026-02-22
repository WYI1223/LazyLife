import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lazynote_flutter/features/settings/settings_capability_page.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  testWidgets('settings page renders deny-by-default snapshot', (tester) async {
    await tester.pumpWidget(
      wrap(SettingsCapabilityPage(onBackToWorkbench: nullCallback)),
    );

    expect(
      find.byKey(const Key('settings_capability_page_root')),
      findsOneWidget,
    );
    expect(
      find.text('Extension capability audit (v0.2 baseline)'),
      findsOneWidget,
    );
    expect(
      find.text('No runtime permissions declared (deny-by-default).'),
      findsOneWidget,
    );
  });

  testWidgets('settings page renders declared capabilities as chips', (
    tester,
  ) async {
    const customExtensions = <ExtensionCapabilitySnapshot>[
      ExtensionCapabilitySnapshot(
        extensionId: 'builtin.sync.provider',
        runtimeCapabilities: <RuntimeCapabilityDescriptor>[
          RuntimeCapabilityDescriptor(
            id: 'network',
            label: 'Network',
            description: 'Allow network access.',
          ),
          RuntimeCapabilityDescriptor(
            id: 'calendar',
            label: 'Calendar',
            description: 'Allow calendar access.',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      wrap(
        SettingsCapabilityPage(
          onBackToWorkbench: nullCallback,
          extensions: customExtensions,
        ),
      ),
    );

    expect(find.text('builtin.sync.provider'), findsOneWidget);
    expect(find.text('network'), findsOneWidget);
    expect(find.text('calendar'), findsOneWidget);
  });
}

void nullCallback() {}
