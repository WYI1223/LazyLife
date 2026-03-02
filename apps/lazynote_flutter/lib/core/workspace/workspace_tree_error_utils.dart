String workspaceActionErrorMessage({
  required String? errorCode,
  required String message,
  required String fallback,
}) {
  final normalized = _envelopeError(
    errorCode: errorCode,
    message: message,
    fallback: fallback,
  );
  if (errorCode == 'db_busy') {
    return '$normalized Retry in a moment.';
  }
  if (errorCode == 'db_error') {
    return '$normalized Verify database access and retry.';
  }
  return normalized;
}

String _envelopeError({
  required String? errorCode,
  required String message,
  required String fallback,
}) {
  final normalized = message.trim();
  if (errorCode == null || errorCode.trim().isEmpty) {
    return normalized.isEmpty ? fallback : normalized;
  }
  if (normalized.isEmpty) {
    return '[$errorCode] $fallback';
  }
  return '[$errorCode] $normalized';
}
