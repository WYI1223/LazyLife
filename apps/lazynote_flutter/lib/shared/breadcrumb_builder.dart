/// Formats an ancestor path (from `workspace_ancestor_path` FFI) into
/// a human-readable breadcrumb string for tag result items.
///
/// Design source: PR-RB-10 S3 Phase A — atom_ref path breadcrumbs.
String formatBreadcrumb(List<String> ancestorPath, {String? rootLabel}) {
  if (ancestorPath.isEmpty) return rootLabel ?? 'Root';
  return ancestorPath.join(' / ');
}
