import 'storage_location.dart';

/// The shared food categories, and the single source of truth for each one's
/// healthy flag, default location and default shelf life
/// (SPEC-app-foundation.md, "Food categories").
enum FoodCategory {
  // healthy, defaultLocation, defaultShelfLifeDays
  vegetables(true, StorageLocation.fridge, 7),
  fruit(true, StorageLocation.cabinet, 7),
  meat(false, StorageLocation.fridge, 3),
  fish(true, StorageLocation.fridge, 2),
  dairyEggs(false, StorageLocation.fridge, 7),
  grainsBread(false, StorageLocation.cabinet, 4),
  legumes(true, StorageLocation.cabinet, null),
  frozen(false, StorageLocation.freezer, 90),
  canned(false, StorageLocation.cabinet, null),
  snacks(false, StorageLocation.cabinet, null),
  beverages(false, StorageLocation.cabinet, null),
  condimentsSpices(false, StorageLocation.cabinet, null),
  other(false, StorageLocation.cabinet, null);

  const FoodCategory(
    this.healthy,
    this.defaultLocation,
    this.defaultShelfLifeDays,
  );

  final bool healthy;
  final StorageLocation defaultLocation;

  /// Days from purchase to the default expiry date; `null` means no default.
  final int? defaultShelfLifeDays;
}
