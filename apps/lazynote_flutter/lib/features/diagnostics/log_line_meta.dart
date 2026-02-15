/// Best-effort parsed metadata for a single log line produced by
/// [flexi_logger::detailed_format].
///
/// Expected format:
///   `[YYYY-MM-DD HH:MM:SS.ffffff TZ] LEVEL [file:line] message`
///
/// When a line does not match the expected format, [timestamp] and [level] are
/// null and [message] returns the raw line unchanged.  Callers must treat all
/// fields as best-effort — never fail on an unrecognised line.
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

  /// Message body — everything after the `[file:line]` bracket.
  /// Falls back to the full raw line when the format is unrecognised.
  final String message;

  /// Original unmodified line as read from the log file.
  final String raw;

  // Matches flexi_logger detailed_format:
  //   [2026-02-15 10:23:45.123456 UTC] INFO [src/foo.rs:12] message
  //
  // Group 1 — HH:MM:SS.mmm  (first 3 of the 6 fractional-second digits)
  // Group 2 — level token    (e.g. INFO)
  // Group 3 — message body   (everything after [file:line])
  static final RegExp _pattern = RegExp(
    r'^\[\d{4}-\d{2}-\d{2} (\d{2}:\d{2}:\d{2}\.\d{3})\d* [^\]]+\] (\w+) \[[^\]]*\] (.*)$',
  );

  /// Parses [raw] and returns a [LogLineMeta].
  ///
  /// Always succeeds — returns a fallback with null metadata fields when the
  /// line does not match the expected format.
  static LogLineMeta parse(String raw) {
    // trimRight handles optional \r on Windows CRLF log files.
    final match = _pattern.firstMatch(raw.trimRight());
    if (match == null) {
      return LogLineMeta(
        timestamp: null,
        level: null,
        message: raw,
        raw: raw,
      );
    }
    return LogLineMeta(
      timestamp: match.group(1),
      level: match.group(2)?.toLowerCase(),
      message: match.group(3) ?? '',
      raw: raw,
    );
  }
}
