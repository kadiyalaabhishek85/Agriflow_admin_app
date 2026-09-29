/// Single source of truth for date/time display formatting.
///
/// flutter-03 rec 12: the visit detail sheet and booking cards showed raw
/// ISO dates because every feature hand-rolled (or skipped) formatting.
/// All display-layer date text should come from here.
///
/// Deliberate byte-compatibility rules:
/// - Unparseable non-empty strings pass through unchanged (never hide data).
/// - `null`/empty values fall back to the caller's [fallback] label.
/// - Day is zero-padded to match the historical card/detail output.
abstract class AppDates {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// `'2026-09-28'`, `'2026-09-28T10:32:00Z'` or `'2026-09-28 10:32:00'`
  /// -> `'28 Sep 2026'`.
  static String dayMonthYear(String? raw, {String fallback = 'Not set'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final trimmed = raw.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return raw;
    return _dayMonthYear(parsed);
  }

  /// [DateTime] -> `'28 Sep 2026'`.
  static String dayMonthYearOf(DateTime dt) => _dayMonthYear(dt);

  /// ISO timestamp -> `'28 Sep 2026, 10:32'` (24h, no seconds, as displayed
  /// by the Event Logs screen). Falls back to [fallback] for empty input and
  /// passes unparseable values through unchanged.
  static String isoDateTimeLabel(String? raw, {String fallback = '—'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    return _dateTimeLabel(parsed);
  }

  /// [DateTime] -> `'28 Sep 2026, 10:32'`. Callers should pass a local time
  /// (`utc.toLocal()`); UTC values are converted automatically.
  static String dateTimeLabel(DateTime dt) => _dateTimeLabel(dt);

  /// [DateTime] -> `'28/09/2026'` (numeric form used on invoice cards).
  static String numericDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  static String _dayMonthYear(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    return '$day ${_months[dt.month - 1]} ${dt.year}';
  }

  static String _dateTimeLabel(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${_dayMonthYear(dt)}, $hour:$minute';
  }
}
