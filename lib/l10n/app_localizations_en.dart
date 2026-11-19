// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fridge Food Manager';

  @override
  String get navFood => 'Food';

  @override
  String get navGroceries => 'Groceries';

  @override
  String get navRecipes => 'Recipes';

  @override
  String get accountTitle => 'Household & account';

  @override
  String get foodEmpty => 'No food yet. What you add will show up here.';

  @override
  String get groceriesEmpty => 'Your grocery list is empty.';

  @override
  String get recipesEmpty => 'No recipes yet.';

  @override
  String get accountPlaceholder =>
      'Sign-in and household settings are coming soon.';

  @override
  String get categoryVegetables => 'Vegetables';

  @override
  String get categoryFruit => 'Fruit';

  @override
  String get categoryMeat => 'Meat';

  @override
  String get categoryFish => 'Fish & seafood';

  @override
  String get categoryDairyEggs => 'Dairy & eggs';

  @override
  String get categoryGrainsBread => 'Grains & bread';

  @override
  String get categoryLegumes => 'Legumes';

  @override
  String get categoryFrozen => 'Frozen';

  @override
  String get categoryCanned => 'Canned & jarred';

  @override
  String get categorySnacks => 'Snacks & sweets';

  @override
  String get categoryBeverages => 'Beverages';

  @override
  String get categoryCondimentsSpices => 'Condiments & spices';

  @override
  String get categoryOther => 'Other';

  @override
  String get locationFridge => 'Fridge';

  @override
  String get locationFreezer => 'Freezer';

  @override
  String get locationCabinet => 'Cabinet';

  @override
  String get unitPcs => 'pcs';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'l';

  @override
  String get unitTsp => 'tsp';

  @override
  String get unitTbsp => 'tbsp';

  @override
  String get unitCup => 'cup';
}
