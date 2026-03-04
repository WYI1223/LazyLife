import 'package:flutter/material.dart';

import 'package:lazynote_flutter/l10n/app_localizations.dart';
import 'package:lazynote_flutter/shared/breadcrumb_builder.dart';

/// Independent tag results panel (S3 Phase A).
///
/// Shows a flat list of atoms matching a selected tag, each with an
/// atom_ref breadcrumb path. Inserted between TagFilter and Explorer
/// in the notes sidebar.
class TagResultsPanel extends StatelessWidget {
  const TagResultsPanel({
    super.key,
    required this.tag,
    required this.items,
    required this.loading,
    required this.breadcrumbs,
    required this.onTapItem,
    this.errorMessage,
  });

  /// The currently selected tag.
  final String tag;

  /// Matching atoms (from `notes_list(tag=)`).
  final List<TagResultItem> items;

  /// Whether results are still loading.
  final bool loading;

  /// Precomputed breadcrumb paths keyed by atomId.
  final Map<String, List<String>> breadcrumbs;

  /// Called when a result row is tapped.
  final ValueChanged<String> onTapItem;

  /// Optional error message to display.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _buildContainer(
        context,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return _buildContainer(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Text(
            errorMessage!,
            key: const Key('tag_results_error'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return _buildContainer(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              AppLocalizations.of(context)?.tagResultsNoMatching ??
                  'No matching atoms',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return _buildContainer(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in items)
            _TagResultRow(
              item: item,
              breadcrumbPath: breadcrumbs[item.atomId] ?? const [],
              onTap: () => onTapItem(item.atomId),
            ),
        ],
      ),
    );
  }

  Widget _buildContainer(BuildContext context, {required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 2),
          child: Text(
            AppLocalizations.of(context)?.tagResultsHeader(tag) ?? 'Tag "$tag"',
            key: const Key('tag_results_header'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
        const Divider(height: 1),
      ],
    );
  }
}

class _TagResultRow extends StatelessWidget {
  const _TagResultRow({
    required this.item,
    required this.breadcrumbPath,
    required this.onTap,
  });

  final TagResultItem item;
  final List<String> breadcrumbPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('tag_result_${item.atomId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  _viewHintIcon(item.viewHint),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                '\u{1F4C1} ${formatBreadcrumb(breadcrumbPath, rootLabel: AppLocalizations.of(context)?.tagResultsRootDirectory)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _viewHintIcon(String viewHint) {
    switch (viewHint) {
      case 'task':
        return '\u2705';
      case 'event':
        return '\u{1F4C5}';
      default:
        return '\u{1F4DD}';
    }
  }
}

/// Lightweight DTO for tag result items consumed by [TagResultsPanel].
///
/// Decouples the panel from FFI `AtomListItem` (Rule E: shared widget
/// must not import features/ internals or FFI types directly).
class TagResultItem {
  const TagResultItem({
    required this.atomId,
    required this.viewHint,
    required this.title,
  });

  final String atomId;
  final String viewHint;
  final String title;
}
