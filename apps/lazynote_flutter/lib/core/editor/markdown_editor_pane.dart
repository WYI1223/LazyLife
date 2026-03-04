import 'package:flutter/material.dart';

import 'package:lazynote_flutter/core/editor/edit_buffer.dart';
import 'package:lazynote_flutter/l10n/app_localizations.dart';

/// Pure markdown editing surface. Depends only on [EditBuffer].
///
/// Adapted from `NoteEditor` (PR-RB-09, DI-10):
/// - `buffer` is required (non-nullable) — EditorPane is only instantiated
///   when the buffer is in `ready` phase.
/// - Writes directly to `buffer.edit()` — no `onChanged` callback.
/// - Focus controlled by chrome layer via [requestInitialFocus].
/// - Uses `Theme.of(context)` for text color (Rule E: no feature imports).
///
/// Three-point lifecycle + string guard bridging (DI-4 D12) inline (~30 lines).
class MarkdownEditorPane extends StatefulWidget {
  const MarkdownEditorPane({
    super.key,
    required this.buffer,
    this.requestInitialFocus = false,
  });

  /// The shared edit buffer for the active atom.
  final EditBuffer buffer;

  /// Whether to request keyboard focus on first build.
  /// Controlled by the chrome layer (e.g., only the active pane gets focus).
  final bool requestInitialFocus;

  @override
  State<MarkdownEditorPane> createState() => _MarkdownEditorPaneState();
}

class _MarkdownEditorPaneState extends State<MarkdownEditorPane> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  String _l10nText({
    required String fallback,
    required String Function(AppLocalizations l10n) pick,
  }) {
    final l10n = AppLocalizations.of(context);
    return l10n == null ? fallback : pick(l10n);
  }

  // ── Three-point lifecycle: initState / didUpdateWidget / dispose ────

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.buffer.content);
    _focusNode = FocusNode();
    // Point 1: attach buffer listener
    widget.buffer.addListener(_onBufferChanged);
    // Chrome-layer focus control: only request focus when explicitly asked.
    if (widget.requestInitialFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MarkdownEditorPane oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Point 2: swap buffer listener on reference change
    if (widget.buffer != oldWidget.buffer) {
      oldWidget.buffer.removeListener(_onBufferChanged);
      widget.buffer.addListener(_onBufferChanged);
      // Sync controller to new buffer's content
      final newContent = widget.buffer.content;
      if (newContent != _textController.text) {
        _textController.value = TextEditingValue(
          text: newContent,
          selection: TextSelection.collapsed(offset: newContent.length),
        );
      }
    }
  }

  @override
  void dispose() {
    // Point 3: detach buffer listener
    widget.buffer.removeListener(_onBufferChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Manual listener: string guard bridging (DI-4 D12) ──────────────

  /// Called when the shared [EditBuffer] notifies (any pane edited).
  ///
  /// String guard: if buffer content already matches controller text,
  /// this is a local edit echo — NO-OP preserves cursor position.
  /// Otherwise, this is a remote edit — update controller.
  void _onBufferChanged() {
    if (widget.buffer.content != _textController.text) {
      _textController.value = TextEditingValue(text: widget.buffer.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('markdown_editor_field'),
      controller: _textController,
      focusNode: _focusNode,
      onChanged: (text) => widget.buffer.edit(text),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
      decoration: InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        hintText: _l10nText(
          fallback: 'Start writing...',
          pick: (l10n) => l10n.notesEditorHintText,
        ),
      ),
    );
  }
}
