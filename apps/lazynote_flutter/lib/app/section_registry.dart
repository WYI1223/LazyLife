import 'package:flutter/widgets.dart';

/// Builder for a section's content widget.
///
/// Receives the current [BuildContext] and an [onBackToWorkbench] callback
/// that sections should invoke to navigate back to the home section.
typedef SectionWidgetBuilder =
    Widget Function(BuildContext context, VoidCallback onBackToWorkbench);

/// Builder for a section's dynamic title string.
typedef SectionTitleBuilder = String Function(BuildContext context);

/// A single registered workbench section.
class SectionRegistration {
  const SectionRegistration({
    required this.id,
    required this.builder,
    required this.titleBuilder,
  });

  /// Section identifier (use [WorkbenchSectionIds] constants).
  final String id;

  /// Builds the section content widget.
  final SectionWidgetBuilder builder;

  /// Builds the section title for the shell layout title bar.
  final SectionTitleBuilder titleBuilder;
}

/// Registry of workbench sections.
///
/// Sections are registered in the app layer (composition root) and consumed
/// by [EntryShellPage] without cross-feature imports.
class SectionRegistry {
  SectionRegistry({this.listenable});

  /// Optional listenable for triggering shell rebuilds
  /// (e.g., workspace tab count changes affecting the title bar).
  final Listenable? listenable;

  final Map<String, SectionRegistration> _sections = {};

  /// Registers a section. Replaces any existing section with the same id.
  void register(SectionRegistration section) {
    _sections[section.id] = section;
  }

  /// Returns the registration for [id], or `null` if not registered.
  SectionRegistration? operator [](String id) => _sections[id];
}
