import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/models/food_category.dart';
import 'package:fridge_food_managing/domain/models/storage_location.dart';
import 'package:fridge_food_managing/domain/models/unit.dart';
import 'package:fridge_food_managing/l10n/app_localizations.dart';
import 'package:fridge_food_managing/ui/core/labels.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));

  // SPEC-app-foundation.md, "Food categories": EN and ES columns.
  const table = {
    FoodCategory.vegetables: ('Vegetables', 'Verduras'),
    FoodCategory.fruit: ('Fruit', 'Fruta'),
    FoodCategory.meat: ('Meat', 'Carne'),
    FoodCategory.fish: ('Fish & seafood', 'Pescado y mariscos'),
    FoodCategory.dairyEggs: ('Dairy & eggs', 'Lácteos y huevos'),
    FoodCategory.grainsBread: ('Grains & bread', 'Cereales y pan'),
    FoodCategory.legumes: ('Legumes', 'Legumbres'),
    FoodCategory.frozen: ('Frozen', 'Congelados'),
    FoodCategory.canned: ('Canned & jarred', 'Conservas'),
    FoodCategory.snacks: ('Snacks & sweets', 'Snacks y dulces'),
    FoodCategory.beverages: ('Beverages', 'Bebidas'),
    FoodCategory.condimentsSpices: (
      'Condiments & spices',
      'Condimentos y especias',
    ),
    FoodCategory.other: ('Other', 'Otros'),
  };

  for (final category in FoodCategory.values) {
    test('${category.name} label matches the spec table', () {
      final (enLabel, esLabel) = table[category]!;
      expect(category.label(en), enLabel);
      expect(category.label(es), esLabel);
    });
  }

  for (final (name, l10n) in [('en', en), ('es', es)]) {
    group(name, () {
      test('AC-AF-6: every category, location and unit has a label', () {
        final labels = [
          ...FoodCategory.values.map((c) => c.label(l10n)),
          ...StorageLocation.values.map((s) => s.label(l10n)),
          ...Unit.values.map((u) => u.label(l10n)),
        ];
        expect(labels, everyElement(isNotEmpty));
      });

      test('category labels are distinct', () {
        final labels = FoodCategory.values.map((c) => c.label(l10n));
        expect(labels.toSet(), hasLength(FoodCategory.values.length));
      });

      test('location labels are distinct', () {
        final labels = StorageLocation.values.map((s) => s.label(l10n));
        expect(labels.toSet(), hasLength(StorageLocation.values.length));
      });
    });
  }

  // gen-l10n silently falls back to English for a key missing in Spanish.
  test('app_es.arb has exactly the keys of app_en.arb', () {
    Set<String> keys(String file) =>
        (jsonDecode(File('lib/l10n/$file').readAsStringSync()) as Map).keys
            .cast<String>()
            .where((k) => !k.startsWith('@'))
            .toSet();
    expect(keys('app_es.arb'), keys('app_en.arb'));
  });

  test('spot checks', () {
    expect(FoodCategory.fruit.label(en), 'Fruit');
    expect(FoodCategory.fruit.label(es), 'Fruta');
    expect(StorageLocation.cabinet.label(en), 'Cabinet');
    expect(StorageLocation.cabinet.label(es), 'Despensa');
    expect(Unit.tbsp.label(en), 'tbsp');
    expect(Unit.tbsp.label(es), 'cda');
  });
}
