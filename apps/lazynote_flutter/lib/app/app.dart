import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/app/routes.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';
import 'package:lazynote_flutter/features/entry/entry_shell_page.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

/// Root app shell for the Windows-first UI stage.
class LazyNoteApp extends StatefulWidget {
  const LazyNoteApp({super.key, this.localeController});

  final AppLocaleController? localeController;

  @override
  State<LazyNoteApp> createState() => _LazyNoteAppState();
}

class _LazyNoteAppState extends State<LazyNoteApp> {
  late final AppLocaleController _localeController;
  late final bool _ownsLocaleController;

  @override
  void initState() {
    super.initState();
    _ownsLocaleController = widget.localeController == null;
    _localeController =
        widget.localeController ??
        AppLocaleController(initialLanguage: LocalSettingsStore.uiLanguage);
  }

  @override
  void dispose() {
    if (_ownsLocaleController) {
      _localeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'LazyNote',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: _localeController.localeOverride,
          initialRoute: AppRoutes.workbench,
          routes: {
            AppRoutes.workbench: (_) =>
                EntryShellPage(localeController: _localeController),
            AppRoutes.entry: (_) =>
                EntryShellPage(localeController: _localeController),
            AppRoutes.notes: (_) => EntryShellPage(
              initialSection: WorkbenchSection.notes,
              localeController: _localeController,
            ),
            AppRoutes.tasks: (_) => EntryShellPage(
              initialSection: WorkbenchSection.tasks,
              localeController: _localeController,
            ),
            AppRoutes.settings: (_) => EntryShellPage(
              initialSection: WorkbenchSection.settings,
              localeController: _localeController,
            ),
            AppRoutes.rustDiagnostics: (_) => EntryShellPage(
              initialSection: WorkbenchSection.rustDiagnostics,
              localeController: _localeController,
            ),
          },
        );
      },
    );
  }
}
