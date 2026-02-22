/// Best-effort parsed metadata for a single log line produced by
/// [flexi_logger::detailed_format].
///
/// Expected detailed_format shape in flexi_logger 0.29:
///   `[YYYY-MM-DD HH:MM:SS.ffffff TZ] LEVEL [module::path] src/file.rs:line: message`
///
/// Legacy default_format shape (no timestamp):
///   `LEVEL [module::path] message`
///
/// When a line does not match known formats, [timestamp] and [level] are null
/// and [message] returns the raw line unchanged. Callers must treat all fields
/// as best-effort and never fail on an unrecognised line.
class LogLineMeta {
  const LogLineMeta({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.raw,
  });

  /// Extracted time in `HH:MM:SS.mmm` form, or null when not parseable.
  final String? timestamp;

  /// Lowercase severity level (`trace`|`debug`|`info`|`warn`|`error`),
  /// or null when not parseable.
  final String? level;

  /// Message body after structured metadata prefixes.
  /// Falls back to the full raw line when the format is unrecognised.
  final String message;

  /// Original unmodified line as read from the log file.
  final String raw;

  // Matches flexi_logger detailed_format:
  //   [2026-02-15 10:23:45.123456 +00:00] INFO [lazynote_core::logging] src/logging.rs:100: event=app_start
  //
  // Group 1 - HH:MM:SS(.fraction) token
  // Group 2 - level token   (e.g. INFO)
  // Group 3 - message body  (everything after "file:line: ")
  static final RegExp _detailedPattern = RegExp(
    r'^\[\d{4}-\d{2}-\d{2} ([0-9:.]+) [^\]]+\] ([A-Za-z]+) \[[^\]]+\] .+?:\d+: (.*)$',
    caseSensitive: false,
  );

  // Backward-compatible matcher for the previously documented shape:
  //   [2026-02-15 10:23:45.123456 UTC] INFO [src/logging.rs:100] event=app_start
  static final RegExp _bracketFilePattern = RegExp(
    r'^\[\d{4}-\d{2}-\d{2} ([0-9:.]+) [^\]]+\] ([A-Za-z]+) \[[^\]]*:\d+\] (.*)$',
    caseSensitive: false,
  );

  // ISO-like prefix matcher:
  //   2026-02-15T10:23:45.1Z WARN [lazynote_core::diag] src/diag.rs:42: event=slow_query
  static final RegExp _isoPrefixPattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}[ T]([0-9:.]+)(?: ?(?:Z|[+-]\d{2}:?\d{2}|UTC|GMT))?\s+([A-Za-z]+)\s+(.*)$',
    caseSensitive: false,
  );

  // Time-only prefix matcher:
  //   [10:23:45.42] warning [module::path] message
  static final RegExp _timeOnlyPattern = RegExp(
    r'^\[?(\d{2}:\d{2}:\d{2}(?:\.\d+)?)\]?\s+([A-Za-z]+)\s+(.*)$',
    caseSensitive: false,
  );

  // Legacy default_format matcher (no timestamp):
  //   INFO [lazynote_core::db::open] event=db_open module=db status=ok
  static final RegExp _defaultPattern = RegExp(
    r'^(TRACE|DEBUG|INFO|WARN|WARNING|ERROR|ERR)\s+(?:\[[^\]]+\]\s+)?(.*)$',
    caseSensitive: false,
  );

  static final RegExp _timeTokenPattern = RegExp(
    r'(\d{2}:\d{2}:\d{2})(?:\.(\d{1,9}))?',
  );
  static final RegExp _modulePrefixPattern = RegExp(r'^\[[^\]]+\]\s*(.*)$');
  static final RegExp _sourcePrefixPattern = RegExp(
    r'^[A-Za-z0-9_./\\-]+:\d+:\s*(.*)$',
  );

  /// Parses [raw] and returns a [LogLineMeta].
  ///
  /// Always succeeds - returns a fallback with null metadata fields when the
  /// line does not match the expected format.
  static LogLineMeta parse(String raw) {
    // trimRight handles optional \r on Windows CRLF log files.
    final normalized = raw.trimRight();

    final detailed = _detailedPattern.firstMatch(normalized);
    if (detailed != null) {
      return LogLineMeta(
        timestamp: _normalizeTimestamp(detailed.group(1)),
        level: _normalizeLevel(detailed.group(2)),
        message: _normalizeMessage(detailed.group(3) ?? ''),
        raw: raw,
      );
    }

    final bracketFile = _bracketFilePattern.firstMatch(normalized);
    if (bracketFile != null) {
      return LogLineMeta(
        timestamp: _normalizeTimestamp(bracketFile.group(1)),
        level: _normalizeLevel(bracketFile.group(2)),
        message: _normalizeMessage(bracketFile.group(3) ?? ''),
        raw: raw,
      );
    }

    final isoPrefix = _isoPrefixPattern.firstMatch(normalized);
    if (isoPrefix != null) {
      return LogLineMeta(
        timestamp: _normalizeTimestamp(isoPrefix.group(1)),
        level: _normalizeLevel(isoPrefix.group(2)),
        message: _normalizeMessage(isoPrefix.group(3) ?? ''),
        raw: raw,
      );
    }

    final timeOnly = _timeOnlyPattern.firstMatch(normalized);
    if (timeOnly != null) {
      return LogLineMeta(
        timestamp: _normalizeTimestamp(timeOnly.group(1)),
        level: _normalizeLevel(timeOnly.group(2)),
        message: _normalizeMessage(timeOnly.group(3) ?? ''),
        raw: raw,
      );
    }

    final defaultLine = _defaultPattern.firstMatch(normalized);
    if (defaultLine != null) {
      return LogLineMeta(
        timestamp: null,
        level: _normalizeLevel(defaultLine.group(1)),
        message: _normalizeMessage(defaultLine.group(2) ?? ''),
        raw: raw,
      );
    }

    return LogLineMeta(timestamp: null, level: null, message: raw, raw: raw);
  }

  static String? _normalizeTimestamp(String? rawToken) {
    if (rawToken == null || rawToken.trim().isEmpty) {
      return null;
    }
    final match = _timeTokenPattern.firstMatch(rawToken);
    if (match == null) {
      return null;
    }

    final hhmmss = match.group(1)!;
    var fraction = match.group(2) ?? '';
    if (fraction.isEmpty) {
      fraction = '000';
    } else if (fraction.length < 3) {
      fraction = fraction.padRight(3, '0');
    } else if (fraction.length > 3) {
      fraction = fraction.substring(0, 3);
    }
    return '$hhmmss.$fraction';
  }

  static String? _normalizeLevel(String? token) {
    if (token == null) {
      return null;
    }
    return switch (token.toLowerCase()) {
      'trace' => 'trace',
      'debug' => 'debug',
      'info' => 'info',
      'warn' => 'warn',
      'warning' => 'warn',
      'error' => 'error',
      'err' => 'error',
      _ => null,
    };
  }

  static String _normalizeMessage(String message) {
    var normalized = message.trimLeft();

    final module = _modulePrefixPattern.firstMatch(normalized);
    if (module != null) {
      normalized = module.group(1) ?? normalized;
    }

    final source = _sourcePrefixPattern.firstMatch(normalized);
    if (source != null) {
      normalized = source.group(1) ?? normalized;
    }
    return normalized;
  }
}
