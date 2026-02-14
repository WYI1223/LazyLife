import 'package:flutter/material.dart';
import 'package:lazynote_flutter/features/notes/notes_style.dart';

/// Editable markdown text surface for active note content.
///
/// Contract:
/// - `content` is the full in-memory markdown draft for the active note.
/// - `focusRequestId` is a monotonic token; when it changes, editor requests
///   focus on next frame.
/// - `onChanged` emits local text edits only (persistence lands in C3).
class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.content,
    required this.focusRequestId,
    required this.onChanged,
  });

  /// Full markdown draft shown by this editor instance.
  final String content;

  /// Monotonic focus request token from notes controller.
  final int focusRequestId;

  /// Called whenever local draft text changes.
  final ValueChanged<String> onChanged;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.content);
    _focusNode = FocusNode();
    if (widget.focusRequestId > 0) {
      _scheduleFocusRequest();
    }
  }

  @override
  void didUpdateWidget(covariant NoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != _textController.text) {
      _textController.value = TextEditingValue(
        text: widget.content,
        selection: TextSelection.collapsed(offset: widget.content.length),
      );
    }
    if (widget.focusRequestId != oldWidget.focusRequestId) {
      _scheduleFocusRequest();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleFocusRequest() {
    // Why: requesting focus in post-frame avoids races during tab switching and
    // editor subtree rebuild, ensuring cursor visibility after selection/create.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.canRequestFocus) {
        return;
      }
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('note_editor_field'),
      controller: _textController,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: kNotesPrimaryText, height: 1.55),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        hintText: 'Start writing...',
      ),
    );
  }
}
