import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/date_key.dart';

void main() {
  test('AC-AF-7: toDateKey ignores the time of day', () {
    expect(toDateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
  });

  test('AC-AF-7: fromDateKey round-trips to local midnight', () {
    final date = fromDateKey('2026-03-05');
    expect(date, DateTime(2026, 3, 5));
    expect(date.isUtc, isFalse);
    expect(toDateKey(date), '2026-03-05');
  });

  test('pads years, months and days', () {
    expect(toDateKey(DateTime(999, 1, 2)), '0999-01-02');
  });

  test('accepts leap days in leap years only', () {
    expect(fromDateKey('2028-02-29'), DateTime(2028, 2, 29));
    expect(() => fromDateKey('2026-02-29'), throwsFormatException);
  });

  // Keys come back from Firestore, which another client may have written.
  test('malformed or impossible keys throw instead of being normalized', () {
    const bad = [
      '',
      '2026-3-5',
      '2026-03-05T00:00',
      ' 2026-03-05',
      '2026/03/05',
      '2026-02-30',
      '2026-13-01',
      '2026-00-10',
      '2026-01-00',
      '２０２６-03-05', // full-width digits
    ];
    for (final key in bad) {
      expect(() => fromDateKey(key), throwsFormatException, reason: key);
    }
  });
}
