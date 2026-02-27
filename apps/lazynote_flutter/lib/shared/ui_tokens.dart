import 'package:flutter/material.dart';

/// Cross-feature color tokens shared by Notes and Tags.
///
/// Extracted from `notes_style.dart` to break the tags→notes Rule E cycle.
/// Names keep the `kNotes*` prefix for backwards compatibility; renaming
/// to a neutral palette is deferred to v0.3 design-token unification.

/// Primary text color for titles and body content.
const Color kNotesPrimaryText = Color(0xFF37352F);

/// Secondary text color for metadata and auxiliary labels.
const Color kNotesSecondaryText = Color(0xFF6B6B6B);

/// Row hover fill used in explorer, tab strip, and tag chips.
const Color kNotesItemHoverColor = Color(0xFFEDECE8);

/// Active item fill for selected notes/tabs/tags.
const Color kNotesItemSelectedColor = Color(0xFFE9E8E3);
