import 'package:flutter/material.dart';

@immutable
class ExtensionCapabilitySnapshot {
  const ExtensionCapabilitySnapshot({
    required this.extensionId,
    required this.runtimeCapabilities,
  });

  final String extensionId;
  final List<RuntimeCapabilityDescriptor> runtimeCapabilities;
}

@immutable
class RuntimeCapabilityDescriptor {
  const RuntimeCapabilityDescriptor({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
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

class SettingsCapabilityPage extends StatelessWidget {
  const SettingsCapabilityPage({
    super.key,
    required this.onBackToWorkbench,
    this.extensions = firstPartyExtensionSnapshots,
  });

  final VoidCallback onBackToWorkbench;
  final List<ExtensionCapabilitySnapshot> extensions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('settings_capability_page_root'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Extension capability audit (v0.2 baseline)',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Runtime capability checks are deny-by-default. '
            'Undeclared capabilities are rejected at invocation time.',
          ),
          const SizedBox(height: 16),
          Text('Registered Extensions', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...extensions.map(_buildExtensionCard),
          const SizedBox(height: 16),
          Text('Capability Catalog', style: theme.textTheme.titleSmall),
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
            child: const Text('Back to Workbench'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionCard(ExtensionCapabilitySnapshot extension) {
    if (extension.runtimeCapabilities.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(extension.extensionId),
          subtitle: const Text(
            'No runtime permissions declared (deny-by-default).',
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
