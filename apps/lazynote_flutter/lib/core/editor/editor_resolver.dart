import 'package:flutter/widgets.dart';

import 'package:lazynote_flutter/core/editor/edit_buffer.dart';

/// Signature for a function that builds an editor widget for a given buffer.
///
/// Design source: DI-10 Q1 — each content_type gets its own EditorPane
/// that interprets `buffer.content` in its own format.
///
/// [requestInitialFocus]: when `true`, the built editor should request
/// keyboard focus on first frame. Controlled by chrome layer (DI-10 Q2).
typedef EditorPaneBuilder =
    Widget Function(
      BuildContext context,
      EditBuffer buffer, {
      bool requestInitialFocus,
    });

/// Maps `content_type` strings to [EditorPaneBuilder] factories.
///
/// Three-layer separation (DI-10):
/// - EditorShellService — state (groups, buffers, layout)
/// - **EditorResolver** — selection (content_type → EditorPane widget)
/// - Feature Chrome — shell (loading/error/metadata)
///
/// v0.3: only `markdown` is registered. Unknown types render an error
/// placeholder rather than falling back to markdown (DI-10 Q3: prevents
/// canvas JSON from being corrupted by a text editor).
class EditorResolver {
  final Map<String, EditorPaneBuilder> _registry = {};

  /// Registers [builder] for [contentType]. Last registration wins.
  void register(String contentType, EditorPaneBuilder builder) {
    _registry[contentType] = builder;
  }

  /// Returns the builder for [contentType], or an error placeholder.
  EditorPaneBuilder resolve(String contentType) {
    return _registry[contentType] ?? _unknownTypePlaceholder;
  }

  static Widget _unknownTypePlaceholder(
    BuildContext context,
    EditBuffer buffer, {
    bool requestInitialFocus = false,
  }) {
    return const Center(child: Text('Unsupported content type'));
  }
}
