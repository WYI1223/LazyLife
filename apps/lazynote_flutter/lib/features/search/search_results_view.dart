import 'package:flutter/material.dart';
import 'package:lazynote_flutter/core/bindings/api.dart' as rust_api;

/// Search results section for the Single Entry panel.
class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    super.key,
    required this.visible,
    required this.isLoading,
    required this.errorMessage,
    required this.items,
    required this.appliedLimit,
    this.onItemTap,
  });

  /// Whether search results area should be mounted.
  final bool visible;

  /// Realtime loading flag for search-mode requests.
  final bool isLoading;

  /// Inline search error text; `null` means no error.
  final String? errorMessage;

  /// Search result rows from latest successful response.
  final List<rust_api.EntrySearchItem> items;

  /// Backend-applied search limit for latest response.
  final int? appliedLimit;

  /// Invoked when user taps a search result row.
  final ValueChanged<rust_api.EntrySearchItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    if (isLoading) {
      return _SearchInfoList(
        key: const Key('single_entry_search_loading'),
        icon: Icons.hourglass_top_outlined,
        message: 'Searching...',
      );
    }

    if (errorMessage != null) {
      return _SearchInfoList(
        key: const Key('single_entry_search_error'),
        icon: Icons.error_outline,
        message: errorMessage!,
        messageColor: Theme.of(context).colorScheme.error,
      );
    }

    if (items.isEmpty) {
      return const _SearchInfoList(
        key: Key('single_entry_search_empty'),
        icon: Icons.search_off_outlined,
        message: 'No results.',
      );
    }

    return _ResultScrollbar(
      builder: (controller) => ListView.separated(
        key: const Key('single_entry_search_results'),
        controller: controller,
        primary: false,
        itemCount: items.length,
        itemBuilder: (context, index) => _SearchResultRow(
          item: items[index],
          index: index,
          onTap: onItemTap,
          showAppliedLimit: appliedLimit != null && index == 0,
          appliedLimit: appliedLimit,
        ),
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 0.6, indent: 16, endIndent: 16),
      ),
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  const _SearchResultRow({
    required this.item,
    required this.index,
    required this.onTap,
    required this.showAppliedLimit,
    required this.appliedLimit,
  });

  final rust_api.EntrySearchItem item;
  final int index;
  final ValueChanged<rust_api.EntrySearchItem>? onTap;
  final bool showAppliedLimit;
  final int? appliedLimit;

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() {
      _isHovered = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subtitleLines = <String>[
      widget.item.kind.toUpperCase(),
      widget.item.atomId,
      if (widget.showAppliedLimit) 'Applied limit: ${widget.appliedLimit}',
    ];
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        color: _isHovered ? const Color(0xFFF7F7F7) : Colors.transparent,
        child: ListTile(
          key: Key('single_entry_search_item_${widget.index}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          leading: Icon(
            _iconForKind(widget.item.kind),
            color: Colors.grey.shade600,
          ),
          title: Text(
            widget.item.snippet,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            subtitleLines.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade500),
          onTap: widget.onTap == null ? null : () => widget.onTap!(widget.item),
        ),
      ),
    );
  }
}

class _SearchInfoList extends StatelessWidget {
  const _SearchInfoList({
    super.key,
    required this.icon,
    required this.message,
    this.messageColor,
  });

  final IconData icon;
  final String message;
  final Color? messageColor;

  @override
  Widget build(BuildContext context) {
    final textColor = messageColor ?? Colors.grey.shade700;
    return _ResultScrollbar(
      builder: (controller) => ListView(
        key: key,
        controller: controller,
        primary: false,
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.grey.shade600),
            title: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ],
      ),
    );
  }
}

class _ResultScrollbar extends StatefulWidget {
  const _ResultScrollbar({required this.builder});

  /// Builder receives the single source-of-truth controller for both list
  /// scrolling and scrollbar painting.
  final Widget Function(ScrollController controller) builder;

  @override
  State<_ResultScrollbar> createState() => _ResultScrollbarState();
}

class _ResultScrollbarState extends State<_ResultScrollbar> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Why: keep result content flush while constraining only scrollbar track
    // endpoints so desktop thumb does not touch the rounded container edge.
    // Why: disable automatic desktop scrollbar wrapping here; we provide one
    // explicit RawScrollbar to avoid duplicated bars and attachment warnings.
    final noAutoScrollbar = ScrollConfiguration.of(
      context,
    ).copyWith(scrollbars: false);
    return ScrollConfiguration(
      behavior: noAutoScrollbar,
      child: RawScrollbar(
        controller: _controller,
        thumbVisibility: true,
        mainAxisMargin: 16,
        crossAxisMargin: 2,
        radius: const Radius.circular(8),
        thickness: 6,
        child: widget.builder(_controller),
      ),
    );
  }
}

IconData _iconForKind(String kind) {
  // Why: Atom can represent multiple roles (note/task/event) at once; v0.1
  // keeps deterministic placeholder icons until user-customized mapping lands.
  return switch (kind.toLowerCase()) {
    'note' => Icons.description_outlined,
    'task' => Icons.check_circle_outline,
    'event' => Icons.calendar_today_outlined,
    _ => Icons.insert_drive_file_outlined,
  };
}
