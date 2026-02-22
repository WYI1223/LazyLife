import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lazynote_flutter/core/debug/log_reader.dart';
import 'package:lazynote_flutter/core/diagnostics/dart_event_logger.dart';
import 'package:lazynote_flutter/features/diagnostics/log_line_meta.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

/// Inline live logs panel used across Workbench shell pages.
class DebugLogsPanel extends StatefulWidget {
  const DebugLogsPanel({
    super.key,
    this.snapshotLoader,
    this.copyTextHandler,
  });

  /// Test hook to disable periodic refresh and keep pump flows stable.
  static bool autoRefreshEnabled = true;

  /// Optional loader override for widget tests.
  final Future<DebugLogSnapshot> Function()? snapshotLoader;

  /// Optional clipboard-copy override for widget tests.
  final Future<void> Function(String text)? copyTextHandler;

  @override
  State<DebugLogsPanel> createState() => _DebugLogsPanelState();
}

class _DebugLogsPanelState extends State<DebugLogsPanel>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  DebugLogSnapshot? _snapshot;
  Object? _error;
  String? _actionMessage;
  bool _loading = false;
  DateTime? _lastRefreshAt;
  Timer? _refreshTimer;
  int _latestRefreshRequestId = 0;
  bool _refreshInFlight = false;
  bool _hasQueuedRefresh = false;
  bool _queuedShowLoading = false;
  bool _followTail = true;

  static const Duration _refreshInterval = Duration(seconds: 3);
  static const double _fallbackLogHeight = 320;
  static const int _maxActionMessageChars = 180;
  static const double _tailFollowThreshold = 32;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScrollPositionChanged);
    _refreshLogs(showLoading: true);
    _startAutoRefreshTimerIfNeeded();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScrollPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollPositionChanged() {
    if (!_scrollController.hasClients) {
      return;
    }
    final extentAfter = _scrollController.position.extentAfter;
    _followTail = extentAfter <= _tailFollowThreshold;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldEnableAutoRefresh()) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        _startAutoRefreshTimerIfNeeded();
        _refreshLogs(showLoading: false);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _refreshTimer?.cancel();
        _refreshTimer = null;
        break;
    }
  }

  bool _shouldEnableAutoRefresh() {
    if (!DebugLogsPanel.autoRefreshEnabled) {
      return false;
    }
    // Why: periodic setState keeps test pump cycles from settling.
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return !bindingName.contains('TestWidgetsFlutterBinding');
  }

  void _startAutoRefreshTimerIfNeeded() {
    if (!_shouldEnableAutoRefresh()) {
      return;
    }
    if (_refreshTimer != null) {
      return;
    }
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _refreshLogs(showLoading: false);
    });
  }

  Future<void> _refreshLogs({required bool showLoading}) async {
    if (_refreshInFlight) {
      // Why: coalesce overlapping refresh requests into one trailing request
      // to avoid unbounded file-read backlog after long app inactivity.
      _hasQueuedRefresh = true;
      _queuedShowLoading = _queuedShowLoading || showLoading;
      return;
    }

    _refreshInFlight = true;
    final requestId = ++_latestRefreshRequestId;

    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _actionMessage = null;
      });
    }

    try {
      final loader = widget.snapshotLoader ?? LogReader.readLatestTail;
      final snapshot = await loader();
      if (!mounted) {
        return;
      }
      if (requestId != _latestRefreshRequestId) {
        // Ignore stale refresh completion from an older in-flight request.
        return;
      }
      final changed = !_sameSnapshot(_snapshot, snapshot);
      final shouldFollowTailAfterUpdate = _followTail || _snapshot == null;
      if (!showLoading && !changed && _error == null) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _error = null;
        _loading = false;
        _lastRefreshAt = DateTime.now();
      });
      if (shouldFollowTailAfterUpdate) {
        _scheduleScrollToTail();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (requestId != _latestRefreshRequestId) {
        // Ignore stale refresh failure from an older in-flight request.
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    } finally {
      _refreshInFlight = false;
      if (_hasQueuedRefresh) {
        final nextShowLoading = _queuedShowLoading;
        _hasQueuedRefresh = false;
        _queuedShowLoading = false;
        unawaited(_refreshLogs(showLoading: nextShowLoading));
      }
    }
  }

  void _scheduleScrollToTail() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_followTail || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      if (!position.hasPixels) {
        return;
      }
      final max = position.maxScrollExtent;
      if ((max - position.pixels).abs() <= 1) {
        return;
      }
      _scrollController.jumpTo(max);
    });
  }

  bool _sameSnapshot(DebugLogSnapshot? left, DebugLogSnapshot right) {
    if (left == null) {
      return false;
    }
    // Why: skip repaint when source file and visible tail text are unchanged,
    // reducing unnecessary frame churn during periodic refresh.
    return left.logDir == right.logDir &&
        left.tailText == right.tailText &&
        left.warningMessage == right.warningMessage &&
        left.activeFile?.path == right.activeFile?.path &&
        left.activeFile?.modifiedAt == right.activeFile?.modifiedAt &&
        left.files.length == right.files.length;
  }

  void _setActionMessage(String message) {
    final normalized = message.replaceAll('\n', ' ').replaceAll('\r', ' ');
    final truncated = normalized.length > _maxActionMessageChars
        ? '${normalized.substring(0, _maxActionMessageChars)}...'
        : normalized;
    setState(() {
      _actionMessage = truncated;
    });
  }

  Future<void> _copyVisibleLogs() async {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot;
    if (snapshot == null || snapshot.tailText.isEmpty) {
      _setActionMessage(l10n.debugLogsNoVisibleLogsToCopy);
      return;
    }

    await _copyText(snapshot.tailText);
    if (!mounted) {
      return;
    }
    _setActionMessage(l10n.debugLogsVisibleLogsCopied);
    DartEventLogger.tryLog(
      level: 'info',
      eventName: 'diagnostics.logs.copy_visible',
      module: 'diagnostics.debug_logs_panel',
      message: 'Visible diagnostics logs copied.',
    );
  }

  Future<void> _copySingleLogLine(String rawLine) async {
    if (rawLine.isEmpty) {
      return;
    }
    await _copyText(rawLine);
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    _setActionMessage(l10n.debugLogsVisibleLogsCopied);
  }

  Future<void> _copyText(String text) async {
    final handler = widget.copyTextHandler;
    if (handler != null) {
      await handler(text);
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _openLogFolder() async {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot;
    if (snapshot == null) {
      return;
    }

    try {
      await LogReader.openLogFolder(snapshot.logDir);
      if (!mounted) {
        return;
      }
      _setActionMessage(l10n.debugLogsOpenedLogFolder);
      DartEventLogger.tryLog(
        level: 'info',
        eventName: 'diagnostics.logs.open_folder.ok',
        module: 'diagnostics.debug_logs_panel',
        message: 'Diagnostics log folder opened.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _setActionMessage(l10n.debugLogsOpenFolderFailed(error.toString()));
      DartEventLogger.tryLog(
        level: 'warn',
        eventName: 'diagnostics.logs.open_folder.error',
        module: 'diagnostics.debug_logs_panel',
        message: 'Diagnostics log folder open failed.',
      );
    }
  }

  String _formatRefreshTime(DateTime? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null) {
      return l10n.commonNever;
    }

    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  Widget _buildLogContent() {
    if (_loading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      final l10n = AppLocalizations.of(context)!;
      return SelectableText(l10n.debugLogsLoadFailed(_error.toString()));
    }

    final snapshot = _snapshot;
    if (snapshot == null || snapshot.tailText.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return SelectableText(l10n.debugLogsNoContentYet);
    }

    final lines = const LineSplitter().convert(snapshot.tailText);
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              _LogLineRow(line: line, onCopyRawLine: _copySingleLogLine),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final snapshot = _snapshot;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;

            final headerChildren = <Widget>[
              Text(
                l10n.debugLogsPanelTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.debugLogsAutoRefreshEverySeconds(
                  _refreshInterval.inSeconds,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                l10n.debugLogsLastRefreshValue(
                  _formatRefreshTime(_lastRefreshAt),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ];

            if (snapshot != null) {
              headerChildren.addAll([
                const SizedBox(height: 8),
                Text(
                  l10n.debugLogsDirectoryValue(snapshot.logDir),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  l10n.debugLogsActiveFileValue(
                    snapshot.activeFile?.name ?? 'N/A',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ]);
            }

            final actionChildren = <Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _refreshLogs(showLoading: true),
                    child: Text(l10n.refreshButton),
                  ),
                  OutlinedButton(
                    onPressed: _copyVisibleLogs,
                    child: Text(l10n.debugLogsCopyVisibleButton),
                  ),
                  OutlinedButton(
                    onPressed: _openLogFolder,
                    child: Text(l10n.debugLogsOpenLogFolderButton),
                  ),
                ],
              ),
            ];

            if (_actionMessage != null) {
              actionChildren.addAll([
                const SizedBox(height: 8),
                Text(
                  _actionMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ]);
            }

            final logArea = hasBoundedHeight
                ? Expanded(child: _buildLogContent())
                : SizedBox(
                    height: _fallbackLogHeight,
                    child: _buildLogContent(),
                  );

            return Column(
              mainAxisSize: hasBoundedHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...headerChildren,
                ...actionChildren,
                const SizedBox(height: 12),
                logArea,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Renders a single log line with a timestamp column and a severity-aware
/// level badge.  Falls back to plain text for lines that do not match the
/// expected [flexi_logger::detailed_format] format.
class _LogLineRow extends StatelessWidget {
  const _LogLineRow({required this.line, required this.onCopyRawLine});

  final String line;
  final ValueChanged<String> onCopyRawLine;

  static const double _timestampWidth = 84;
  static const double _levelWidth = 52;
  static const double _fontSize = 12;
  static const TextStyle _monoTextStyle = TextStyle(
    fontSize: _fontSize,
    fontFamily: 'monospace',
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) {
    final meta = LogLineMeta.parse(line);
    final rowBg = _rowBackground(meta.level);
    final levelColor = _levelColor(context, meta.level);
    final badgeBg = _levelBadgeBackground(meta.level);
    final messageColor = _messageColor(context, meta.level);
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          left: BorderSide(
            color: levelColor.withAlpha(190),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _timestampWidth,
            child: SelectableText(
              meta.timestamp ?? '',
              style: _monoTextStyle,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: _levelWidth,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              meta.level?.toUpperCase() ?? '',
              style: _monoTextStyle.copyWith(
                color: levelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SelectableText(
              meta.message,
              textWidthBasis: TextWidthBasis.parent,
              style: _monoTextStyle.copyWith(
                color: messageColor,
                fontWeight: meta.level == 'error'
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: copyLabel,
            child: IconButton(
              onPressed: () => onCopyRawLine(meta.raw),
              icon: const Icon(Icons.content_copy, size: 14),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 20, height: 20),
              padding: EdgeInsets.zero,
              splashRadius: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color? _rowBackground(String? level) {
    return switch (level) {
      'error' => Colors.red.shade50,
      'warn' => Colors.amber.shade50,
      'info' => Colors.green.shade50,
      'debug' => Colors.blueGrey.shade50,
      'trace' => Colors.grey.shade200,
      _ => null,
    };
  }

  Color? _levelBadgeBackground(String? level) {
    return switch (level) {
      'error' => Colors.red.shade100,
      'warn' => Colors.amber.shade100,
      'info' => Colors.green.shade100,
      'debug' => Colors.blueGrey.shade100,
      'trace' => Colors.grey.shade300,
      _ => null,
    };
  }

  Color _levelColor(BuildContext context, String? level) {
    return switch (level) {
      'error' => Colors.red.shade700,
      'warn' => Colors.orange.shade800,
      'info' => Colors.green.shade700,
      'debug' => Colors.blueGrey.shade600,
      'trace' => Colors.grey.shade600,
      _ => Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
    };
  }

  Color _messageColor(BuildContext context, String? level) {
    return switch (level) {
      'error' => Colors.red.shade900,
      'warn' => Colors.orange.shade900,
      _ => Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
    };
  }
}
