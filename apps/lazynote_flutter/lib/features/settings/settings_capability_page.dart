import 'package:flutter/material.dart';
import 'package:lazynote_flutter/app/app_locale_controller.dart';
import 'package:lazynote_flutter/core/settings/ui_language.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

/// Capability snapshot shown in settings audit page.
@immutable
class ExtensionCapabilitySnapshot {
  /// Creates one extension capability snapshot.
  const ExtensionCapabilitySnapshot({
    required this.extensionId,
    required this.runtimeCapabilities,
  });

  /// Stable extension identifier.
  final String extensionId;

  /// Declared runtime capabilities for this extension.
  final List<RuntimeCapabilityDescriptor> runtimeCapabilities;
}

/// Runtime capability metadata descriptor used by capability catalog rendering.
@immutable
class RuntimeCapabilityDescriptor {
  /// Creates one capability descriptor.
  const RuntimeCapabilityDescriptor({
    required this.id,
    required this.label,
    required this.description,
  });

  /// Stable runtime capability id.
  final String id;

  /// User-facing short label.
  final String label;

  /// User-facing detailed explanation.
  final String description;
}

const RuntimeCapabilityDescriptor _networkCapability =
    RuntimeCapabilityDescriptor(
      id: 'network',
      label: 'Network',
      description:
          'Allow network access for provider sync and remote service calls.',
    );

const RuntimeCapabilityDescriptor _fileCapability = RuntimeCapabilityDescriptor(
  id: 'file',
  label: 'File',
  description:
      'Allow local file read/write access for import/export workflows.',
);

const RuntimeCapabilityDescriptor _notificationCapability =
    RuntimeCapabilityDescriptor(
      id: 'notification',
      label: 'Notification',
      description: 'Allow posting local notifications and reminder prompts.',
    );

const RuntimeCapabilityDescriptor _calendarCapability =
    RuntimeCapabilityDescriptor(
      id: 'calendar',
      label: 'Calendar',
      description: 'Allow reading/writing external calendar provider data.',
    );

const List<RuntimeCapabilityDescriptor> runtimeCapabilityCatalog =
    <RuntimeCapabilityDescriptor>[
      _networkCapability,
      _fileCapability,
      _notificationCapability,
      _calendarCapability,
    ];

const List<ExtensionCapabilitySnapshot> firstPartyExtensionSnapshots =
    <ExtensionCapabilitySnapshot>[
      ExtensionCapabilitySnapshot(
        extensionId: 'builtin.notes.shell',
        runtimeCapabilities: <RuntimeCapabilityDescriptor>[],
      ),
    ];

/// Settings page section that displays extension capability audit information.
class SettingsCapabilityPage extends StatelessWidget {
  /// Creates settings capability audit page.
  const SettingsCapabilityPage({
    super.key,
    required this.onBackToWorkbench,
    this.extensions = firstPartyExtensionSnapshots,
    this.localeController,
  });

  /// Callback used to return to workbench shell.
  final VoidCallback onBackToWorkbench;

  /// Extension capability snapshots rendered by this page.
  final List<ExtensionCapabilitySnapshot> extensions;
  final AppLocaleController? localeController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final controller = localeController;
    final language = controller?.language ?? UiLanguage.system;
    return SingleChildScrollView(
      key: const Key('settings_capability_page_root'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.workbenchSectionSettings, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            l10n.settingsCapabilityAuditTitle,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsCapabilityAuditDescription,
          ),
          const SizedBox(height: 16),
          _LanguageSelectorCard(
            language: language,
            enabled: controller != null,
            onChanged: (nextLanguage) async {
              if (controller == null) {
                return;
              }
              final persisted = await controller.setLanguage(nextLanguage);
              if (!persisted && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.settingsLanguageSaveFailed),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Text(l10n.settingsRegisteredExtensions, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...extensions.map((extension) => _buildExtensionCard(context, extension)),
          const SizedBox(height: 16),
          Text(l10n.settingsCapabilityCatalog, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...runtimeCapabilityCatalog.map(
            (capability) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${capability.label} (${capability.id})'),
              subtitle: Text(capability.description),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onBackToWorkbench,
            child: Text(l10n.backToWorkbenchButton),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionCard(
    BuildContext context,
    ExtensionCapabilitySnapshot extension,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (extension.runtimeCapabilities.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(extension.extensionId),
          subtitle: Text(
            l10n.settingsNoRuntimePermissionsDeclared,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(extension.extensionId),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: extension.runtimeCapabilities
                  .map((capability) => Chip(label: Text(capability.id)))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelectorCard extends StatelessWidget {
  const _LanguageSelectorCard({
    required this.language,
    required this.enabled,
    required this.onChanged,
  });

  final UiLanguage language;
  final bool enabled;
  final ValueChanged<UiLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsLanguageTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.settingsLanguageDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<UiLanguage>(
              value: language,
              onChanged: enabled
                  ? (next) {
                      if (next != null) {
                        onChanged(next);
                      }
                    }
                  : null,
              items: [
                DropdownMenuItem(
                  value: UiLanguage.system,
                  child: Text(l10n.languageOptionSystem),
                ),
                DropdownMenuItem(
                  value: UiLanguage.en,
                  child: Text(l10n.languageOptionEnglish),
                ),
                DropdownMenuItem(
                  value: UiLanguage.zhCn,
                  child: Text(l10n.languageOptionChineseSimplified),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
