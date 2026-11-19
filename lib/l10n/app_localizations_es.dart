// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Gestor de alimentos';

  @override
  String get navFood => 'Alimentos';

  @override
  String get navGroceries => 'Compras';

  @override
  String get navRecipes => 'Recetas';

  @override
  String get accountTitle => 'Hogar y cuenta';

  @override
  String get foodEmpty => 'Aún no hay alimentos. Lo que añadas aparecerá aquí.';

  @override
  String get groceriesEmpty => 'Tu lista de la compra está vacía.';

  @override
  String get recipesEmpty => 'Aún no hay recetas.';

  @override
  String get accountPlaceholder =>
      'El inicio de sesión y los ajustes del hogar llegarán pronto.';

  @override
  String get categoryVegetables => 'Verduras';

  @override
  String get categoryFruit => 'Fruta';

  @override
  String get categoryMeat => 'Carne';

  @override
  String get categoryFish => 'Pescado y mariscos';

  @override
  String get categoryDairyEggs => 'Lácteos y huevos';

  @override
  String get categoryGrainsBread => 'Cereales y pan';

  @override
  String get categoryLegumes => 'Legumbres';

  @override
  String get categoryFrozen => 'Congelados';

  @override
  String get categoryCanned => 'Conservas';

  @override
  String get categorySnacks => 'Snacks y dulces';

  @override
  String get categoryBeverages => 'Bebidas';

  @override
  String get categoryCondimentsSpices => 'Condimentos y especias';

  @override
  String get categoryOther => 'Otros';

  @override
  String get locationFridge => 'Nevera';

  @override
  String get locationFreezer => 'Congelador';

  @override
  String get locationCabinet => 'Despensa';

  @override
  String get unitPcs => 'uds';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'l';

  @override
  String get unitTsp => 'cdta';

  @override
  String get unitTbsp => 'cda';

  @override
  String get unitCup => 'taza';
}
