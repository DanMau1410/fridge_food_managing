import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_food_managing/domain/models/food_category.dart';
import 'package:fridge_food_managing/domain/models/storage_location.dart';

void main() {
  const fridge = StorageLocation.fridge;
  const freezer = StorageLocation.freezer;
  const cabinet = StorageLocation.cabinet;

  // SPEC-app-foundation.md, "Food categories": healthy, location, shelf life.
  const table = {
    'vegetables': (true, fridge, 7),
    'fruit': (true, cabinet, 7),
    'meat': (false, fridge, 3),
    'fish': (true, fridge, 2),
    'dairyEggs': (false, fridge, 7),
    'grainsBread': (false, cabinet, 4),
    'legumes': (true, cabinet, null),
    'frozen': (false, freezer, 90),
    'canned': (false, cabinet, null),
    'snacks': (false, cabinet, null),
    'beverages': (false, cabinet, null),
    'condimentsSpices': (false, cabinet, null),
    'other': (false, cabinet, null),
  };

  test('the categories are exactly the 13 in the spec, in order', () {
    expect(FoodCategory.values.map((c) => c.name), table.keys);
  });

  for (final category in FoodCategory.values) {
    test('AC-AF-6: ${category.name} matches the spec table', () {
      final (healthy, location, shelfLife) = table[category.name]!;
      expect(category.healthy, healthy);
      expect(category.defaultLocation, location);
      expect(category.defaultShelfLifeDays, shelfLife);
    });
  }

  test('storage locations are fridge, freezer and cabinet', () {
    expect(StorageLocation.values, [fridge, freezer, cabinet]);
  });
}
