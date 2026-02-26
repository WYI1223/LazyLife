import 'package:flutter/material.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/app/section_registry.dart';
import 'package:lazynote_flutter/app/ui_slots/first_party_ui_slots.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_host.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_models.dart';
import 'package:lazynote_flutter/app/ui_slots/ui_slot_registry.dart';
import 'package:lazynote_flutter/features/entry/single_entry_controller.dart';
import 'package:lazynote_flutter/features/entry/single_entry_panel.dart';
import 'package:lazynote_flutter/features/entry/workbench_shell_layout.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

/// Default shell page used to validate new features before wiring final UIs.
///
/// Left-pane routing is handled in-place via state so the right logs panel
/// remains mounted and stable across section switches.
class EntryShellPage extends StatefulWidget {
  const EntryShellPage({
    super.key,
    this.initialSection = WorkbenchSectionIds.home,
    this.sectionRegistry,
    this.uiSlotRegistry,
    this.localeController,
  });

  /// Initial left-pane section to render inside Workbench shell.
  final String initialSection;
  final SectionRegistry? sectionRegistry;
  final UiSlotRegistry? uiSlotRegistry;
  final AppLocaleController? localeController;

  @override
  State<EntryShellPage> createState() => _EntryShellPageState();
}

class _EntryShellPageState extends State<EntryShellPage> {
  // Single Entry is the primary interactive path in Workbench after PR-0009C.
  final SingleEntryController _singleEntryController = SingleEntryController();
  late final UiSlotRegistry _uiSlotRegistry;
  late String _activeSection;
  bool _showSingleEntryPanel = false;

  @override
  void initState() {
    super.initState();
    _uiSlotRegistry = widget.uiSlotRegistry ?? createFirstPartyUiSlotRegistry();
    final initial = widget.initialSection;
    _activeSection =
        initial == WorkbenchSectionIds.home ||
            widget.sectionRegistry?[initial] != null
        ? initial
        : WorkbenchSectionIds.home;
  }

  @override
  void dispose() {
    _singleEntryController.dispose();
    super.dispose();
  }

  void _openSection(String sectionId) {
    final resolved =
        sectionId == WorkbenchSectionIds.home ||
            widget.sectionRegistry?[sectionId] != null
        ? sectionId
        : WorkbenchSectionIds.home;
    setState(() {
      _activeSection = resolved;
    });
  }

  void _openOrFocusSingleEntryPanel() {
    setState(() {
      _showSingleEntryPanel = true;
    });
    // Why: defer focus request until panel subtree is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _singleEntryController.requestFocus();
    });
  }

  void _hideSingleEntryPanel() {
    setState(() {
      _showSingleEntryPanel = false;
    });
  }

  String _titleForSection(BuildContext context) {
    if (_activeSection == WorkbenchSectionIds.home) {
      return AppLocalizations.of(context)!.lazyNoteWorkbenchTitle;
    }
    final registration = widget.sectionRegistry?[_activeSection];
    if (registration != null) {
      return registration.titleBuilder(context);
    }
    return '';
  }

  Widget _buildWorkbenchHome() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.workbenchHomeTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.workbenchHomeDescription,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Text(
          l10n.singleEntryTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              key: const Key('open_single_entry_panel_button'),
              onPressed: _openOrFocusSingleEntryPanel,
              child: Text(
                _showSingleEntryPanel
                    ? l10n.focusSingleEntryButton
                    : l10n.openSingleEntryButton,
              ),
            ),
            if (_showSingleEntryPanel)
              OutlinedButton(
                key: const Key('hide_single_entry_panel_button'),
                onPressed: _hideSingleEntryPanel,
                child: Text(l10n.hideSingleEntryButton),
              ),
          ],
        ),
        // Keep Single Entry embedded in Workbench instead of route replacement
        // so the right-side debug logs panel remains stable while testing.
        if (_showSingleEntryPanel) ...[
          const SizedBox(height: 12),
          SingleEntryPanel(
            controller: _singleEntryController,
            onClose: _hideSingleEntryPanel,
          ),
        ],
        const SizedBox(height: 24),
        UiSlotListHost(
          registry: _uiSlotRegistry,
          slotId: UiSlotIds.workbenchHomeBlocks,
          layer: UiSlotLayer.contentBlock,
          slotContext: UiSlotContext({
            UiSlotContextKeys.onOpenDiagnostics: () {
              _openSection(WorkbenchSectionIds.rustDiagnostics);
            },
          }),
          listBuilder: (context, children) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  if (index > 0) const SizedBox(height: 24),
                  children[index],
                ],
              ],
            );
          },
          fallbackBuilder: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workbenchDiagnosticsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      _openSection(WorkbenchSectionIds.rustDiagnostics),
                  child: Text(l10n.workbenchSectionRustDiagnostics),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          l10n.placeholderRoutesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        UiSlotListHost(
          registry: _uiSlotRegistry,
          slotId: UiSlotIds.workbenchHomeWidgets,
          layer: UiSlotLayer.homeWidget,
          slotContext: UiSlotContext({
            UiSlotContextKeys.onOpenSection: _openSection,
          }),
          listBuilder: (context, children) {
            return Wrap(spacing: 12, runSpacing: 12, children: children);
          },
          fallbackBuilder: (context) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton(
                  onPressed: () => _openSection(WorkbenchSectionIds.notes),
                  child: Text(l10n.workbenchSectionNotes),
                ),
                OutlinedButton(
                  onPressed: () => _openSection(WorkbenchSectionIds.tasks),
                  child: Text(l10n.workbenchSectionTasks),
                ),
                OutlinedButton(
                  onPressed: () => _openSection(WorkbenchSectionIds.calendar),
                  child: Text(l10n.workbenchSectionCalendar),
                ),
                OutlinedButton(
                  onPressed: () => _openSection(WorkbenchSectionIds.settings),
                  child: Text(l10n.workbenchSectionSettings),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveLeftContent() {
    return UiSlotViewHost(
      registry: _uiSlotRegistry,
      slotId: UiSlotIds.workbenchSectionView,
      slotContext: UiSlotContext({
        UiSlotContextKeys.activeSection: _activeSection,
        UiSlotContextKeys.onBackToWorkbench: () {
          _openSection(WorkbenchSectionIds.home);
        },
      }),
      fallbackBuilder: (context) {
        if (_activeSection == WorkbenchSectionIds.home) {
          return _buildWorkbenchHome();
        }
        final registration = widget.sectionRegistry?[_activeSection];
        if (registration != null) {
          return registration.builder(
            context,
            () => _openSection(WorkbenchSectionIds.home),
          );
        }
        return _buildWorkbenchHome();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenable = widget.sectionRegistry?.listenable;
    if (listenable == null) {
      return WorkbenchShellLayout(
        title: _titleForSection(context),
        content: _buildActiveLeftContent(),
      );
    }
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        return WorkbenchShellLayout(
          title: _titleForSection(context),
          content: _buildActiveLeftContent(),
        );
      },
    );
  }
}
