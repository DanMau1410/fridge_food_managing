import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/username.dart';

void main() {
  group('parseUsername', () {
    // AC-ID-4: input is trimmed and lowercased.
    final valid = {
      'Dan_M': 'dan_m',
      ' dan_m ': 'dan_m',
      'abc': 'abc',
      '___': '___',
      'a' * 20: 'a' * 20,
    };
    for (final MapEntry(key: input, value: expected) in valid.entries) {
      test('"$input" → $expected', () {
        expect(parseUsername(input), expected);
      });
    }

    // AC-ID-6, plus characters the regex must not let through.
    final invalid = [
      'ab',
      'a' * 21,
      'dan m',
      'dan-m',
      'dañ',
      'dan.m',
      'dan@m',
      '',
      '   ',
    ];
    for (final input in invalid) {
      test('"$input" is rejected', () {
        expect(parseUsername(input), isNull);
      });
    }
  });

  group('parseDisplayName', () {
    test('is trimmed', () {
      expect(parseDisplayName('  Ana María ', 'ana'), 'Ana María');
    });

    test('falls back to the username when blank', () {
      for (final blank in ['', '   ', '\t\n', ' ']) {
        expect(parseDisplayName(blank, 'ana'), 'ana');
      }
    });

    test('accepts 30 characters and rejects 31', () {
      expect(parseDisplayName('x' * 30, 'ana'), 'x' * 30);
      expect(parseDisplayName('x' * 31, 'ana'), isNull);
    });

    test('counts an emoji as two', () {
      expect(parseDisplayName('😀' * 15, 'ana'), '😀' * 15);
      expect(parseDisplayName('${'😀' * 15}a', 'ana'), isNull);
    });
  });
}
