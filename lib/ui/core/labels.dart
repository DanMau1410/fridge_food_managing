import '../../domain/models/food_category.dart';
import '../../domain/models/storage_location.dart';
import '../../domain/models/unit.dart';
import '../../l10n/app_localizations.dart';

/// The localized name of a [FoodCategory].
extension FoodCategoryLabel on FoodCategory {
  String label(AppLocalizations l10n) => switch (this) {
    FoodCategory.vegetables => l10n.categoryVegetables,
    FoodCategory.fruit => l10n.categoryFruit,
    FoodCategory.meat => l10n.categoryMeat,
    FoodCategory.fish => l10n.categoryFish,
    FoodCategory.dairyEggs => l10n.categoryDairyEggs,
    FoodCategory.grainsBread => l10n.categoryGrainsBread,
    FoodCategory.legumes => l10n.categoryLegumes,
    FoodCategory.frozen => l10n.categoryFrozen,
    FoodCategory.canned => l10n.categoryCanned,
    FoodCategory.snacks => l10n.categorySnacks,
    FoodCategory.beverages => l10n.categoryBeverages,
    FoodCategory.condimentsSpices => l10n.categoryCondimentsSpices,
    FoodCategory.other => l10n.categoryOther,
  };
}

/// The localized name of a [StorageLocation].
extension StorageLocationLabel on StorageLocation {
  String label(AppLocalizations l10n) => switch (this) {
    StorageLocation.fridge => l10n.locationFridge,
    StorageLocation.freezer => l10n.locationFreezer,
    StorageLocation.cabinet => l10n.locationCabinet,
  };
}

/// The localized abbreviation of a [Unit].
extension UnitLabel on Unit {
  String label(AppLocalizations l10n) => switch (this) {
    Unit.pcs => l10n.unitPcs,
    Unit.g => l10n.unitG,
    Unit.kg => l10n.unitKg,
    Unit.ml => l10n.unitMl,
    Unit.l => l10n.unitL,
    Unit.tsp => l10n.unitTsp,
    Unit.tbsp => l10n.unitTbsp,
    Unit.cup => l10n.unitCup,
  };
}
