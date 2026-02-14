import 'package:flutter/material.dart';

/// Shared visual tokens for Notes shell.
///
/// These constants intentionally stay close to Single Entry light-theme tones
/// so Notes keeps a consistent minimalist surface in Workbench.
const Color kNotesSidebarBackground = Color(0xFFF7F7F5);

/// Shared height for explorer header row and top tab strip.
const double kNotesTopStripHeight = 26;

/// Main document canvas background color.
const Color kNotesCanvasBackground = Color(0xFFFFFFFF);

/// Primary text color for titles and body content.
const Color kNotesPrimaryText = Color(0xFF37352F);

/// Secondary text color for metadata and auxiliary labels.
const Color kNotesSecondaryText = Color(0xFF6B6B6B);

/// Divider and subtle border color.
const Color kNotesDividerColor = Color(0xFFE3E2DE);

/// Row hover fill used in explorer and tab strip.
const Color kNotesItemHoverColor = Color(0xFFEDECE8);

/// Active item fill for selected notes/tabs.
const Color kNotesItemSelectedColor = Color(0xFFE9E8E3);

/// Shared placeholder icon for note rows and top tabs.
const IconData kNotesItemPlaceholderIcon = Icons.description_outlined;

/// Error surface background color for inline detail failures.
const Color kNotesErrorBackground = Color(0xFFFFEBEE);

/// Error surface border color for inline detail failures.
const Color kNotesErrorBorder = Color(0xFFFFCDD2);
