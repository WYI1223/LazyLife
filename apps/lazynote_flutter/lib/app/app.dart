import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/app/routes.dart';
import 'package:lazynote_flutter/app/section_registry.dart';
import 'package:lazynote_flutter/app/ui_slots/first_party_ui_slots.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_registry.dart';
import 'package:lazynote_flutter/core/settings/local_settings_store.dart';
import 'package:lazynote_flutter/features/calendar/calendar_page.dart';
import 'package:lazynote_flutter/features/diagnostics/rust_diagnostics_page.dart';
import 'package:lazynote_flutter/features/entry/entry_shell_page.dart';
import 'package:lazynote_flutter/features/notes/notes_coordinator.dart';
import 'package:lazynote_flutter/features/notes/notes_page.dart';
import 'package:lazynote_flutter/features/settings/settings_capability_page.dart';
import 'package:lazynote_flutter/features/tasks/tasks_page.dart';
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
  late final NotesCoordinator _notesCoordinator;
  late final UiSlotRegistry _uiSlotRegistry;
  late final SectionRegistry _sectionRegistry;

  @override
  void initState() {
    super.initState();
    _ownsLocaleController = widget.localeController == null;
    _localeController =
        widget.localeController ??
        AppLocaleController(initialLanguage: LocalSettingsStore.uiLanguage);
    _notesCoordinator = NotesCoordinator();
    _uiSlotRegistry = createFirstPartyUiSlotRegistry();
    _sectionRegistry = _buildSectionRegistry();
  }

  @override
  void dispose() {
    _notesCoordinator.dispose();
    if (_ownsLocaleController) {
      _localeController.dispose();
    }
    super.dispose();
  }

  SectionRegistry _buildSectionRegistry() {
    final registry = SectionRegistry(
      listenable: _notesCoordinator.workspaceProvider,
    );

    registry.register(
      SectionRegistration(
        id: WorkbenchSectionIds.notes,
        builder: (context, onBack) => NotesPage(
          controller: _notesCoordinator,
          onBackToWorkbench: onBack,
          uiSlotRegistry: _uiSlotRegistry,
        ),
        titleBuilder: (context) {
          final l10n = AppLocalizations.of(context)!;
          final workspace = _notesCoordinator.workspaceProvider;
          final openTabs =
              workspace.openTabsByPane[workspace.activePaneId] ??
              const <String>[];
          return openTabs.isEmpty
              ? l10n.workbenchSectionNotes
              : l10n.workbenchSectionNotesWithCount(openTabs.length);
        },
      ),
    );

    registry.register(
      SectionRegistration(
        id: WorkbenchSectionIds.tasks,
        builder: (context, onBack) => TasksPage(onBackToWorkbench: onBack),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.workbenchSectionTasks,
      ),
    );

    registry.register(
      SectionRegistration(
        id: WorkbenchSectionIds.calendar,
        builder: (context, onBack) => CalendarPage(onBackToWorkbench: onBack),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.workbenchSectionCalendar,
      ),
    );

    registry.register(
      SectionRegistration(
        id: WorkbenchSectionIds.settings,
        builder: (context, onBack) => SettingsCapabilityPage(
          onBackToWorkbench: onBack,
          localeController: _localeController,
        ),
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.workbenchSectionSettings,
      ),
    );

    registry.register(
      SectionRegistration(
        id: WorkbenchSectionIds.rustDiagnostics,
        builder: (context, onBack) {
          final l10n = AppLocalizations.of(context)!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.workbenchSectionRustDiagnostics,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const RustDiagnosticsContent(),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onBack,
                child: Text(l10n.backToWorkbenchButton),
              ),
            ],
          );
        },
        titleBuilder: (context) =>
            AppLocalizations.of(context)!.workbenchSectionRustDiagnostics,
      ),
    );

    return registry;
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
            AppRoutes.workbench: (_) => EntryShellPage(
              localeController: _localeController,
              sectionRegistry: _sectionRegistry,
              uiSlotRegistry: _uiSlotRegistry,
            ),
            AppRoutes.entry: (_) => EntryShellPage(
              localeController: _localeController,
              sectionRegistry: _sectionRegistry,
              uiSlotRegistry: _uiSlotRegistry,
            ),
            AppRoutes.notes: (_) => EntryShellPage(
              initialSection: WorkbenchSectionIds.notes,
              localeController: _localeController,
              sectionRegistry: _sectionRegistry,
              uiSlotRegistry: _uiSlotRegistry,
            ),
            AppRoutes.tasks: (_) => EntryShellPage(
              initialSection: WorkbenchSectionIds.tasks,
              localeController: _localeController,
              sectionRegistry: _sectionRegistry,
              uiSlotRegistry: _uiSlotRegistry,
            ),
            AppRoutes.settings: (_) => EntryShellPage(
              initialSection: WorkbenchSectionIds.settings,
              localeController: _localeController,
              sectionRegistry: _sectionRegistry,
              uiSlotRegistry: _uiSlotRegistry,
            ),
            AppRoutes.rustDiagnostics: (_) => EntryShellPage(
              initialSection: WorkbenchSectionIds.rustDiagnostics,
              localeController: _localeController,
              sectionRegistry: _sectionRegistry,
              uiSlotRegistry: _uiSlotRegistry,
            ),
          },
        );
      },
    );
  }
}
