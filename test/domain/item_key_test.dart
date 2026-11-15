import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/item_key.dart';

void main() {
  // AC-AF-4, plus the accents the spec's languages use.
  const cases = {
    '  Tomates ': 'tomates',
    'Jalapeño': 'jalapeno',
    'CAFÉ  con  Leche': 'cafe con leche',
    'Ñame': 'name',
    'Pingüino': 'pinguino',
    'Façon': 'facon',
    'Crème Brûlée': 'creme brulee',
    'Maçã': 'maca',
    // Decomposed accents (NFD) must give the same key as precomposed ones.
    'Jalapen\u0303o': 'jalapeno',
    // Tabs, newlines and non-breaking spaces collapse like spaces.
    'Peanut\t\nbutter\u00a0 jar': 'peanut butter jar',
  };

  for (final MapEntry(key: name, value: expected) in cases.entries) {
    test('itemKey(${name.replaceAll('\n', r'\n')}) == $expected', () {
      expect(itemKey(name), expected);
    });
  }

  test('blank names give an empty key, which callers must reject', () {
    for (final blank in ['', '   ', '\t\n', '\u00a0']) {
      expect(itemKey(blank), isEmpty, reason: 'input: ${blank.codeUnits}');
    }
  });
}
