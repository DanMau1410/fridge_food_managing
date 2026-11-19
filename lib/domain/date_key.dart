final _dateKey = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// `yyyy-MM-dd` from the date's own calendar fields, so pass a local time.
String toDateKey(DateTime date) =>
    '${_pad(date.year, 4)}-${_pad(date.month, 2)}-${_pad(date.day, 2)}';

/// Local midnight of a `yyyy-MM-dd` key.
///
/// Throws a [FormatException] for anything else, including impossible dates
/// like `2026-02-30`, which [DateTime] would otherwise roll into March.
DateTime fromDateKey(String key) {
  final match = _dateKey.firstMatch(key);
  if (match != null) {
    final [y, m, d] = [1, 2, 3].map((g) => int.parse(match[g]!)).toList();
    final date = DateTime(y, m, d);
    if (date.year == y && date.month == m && date.day == d) return date;
  }
  throw FormatException('Not a yyyy-MM-dd date key', key);
}

String _pad(int value, int width) => value.toString().padLeft(width, '0');
