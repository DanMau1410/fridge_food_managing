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

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get displayNameOptionalLabel => 'Nombre visible (opcional)';

  @override
  String get switchToSignUp => '¿Eres nuevo? Crea una cuenta';

  @override
  String get switchToSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get errorEmailRequired => 'Escribe tu correo.';

  @override
  String get errorPasswordRequired => 'Escribe tu contraseña.';

  @override
  String errorPasswordTooShort(int min) {
    return 'Usa al menos $min caracteres.';
  }

  @override
  String get authInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authEmailInUse =>
      'Ya existe una cuenta con este correo. Inicia sesión.';

  @override
  String get authWeakPassword => 'Elige una contraseña más segura.';

  @override
  String get authInvalidEmail => 'Ese correo no parece válido.';

  @override
  String get authTooManyRequests => 'Demasiados intentos. Inténtalo más tarde.';

  @override
  String get authAccountExists => 'Este correo ya inicia sesión de otra forma.';

  @override
  String get errorNoConnection =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get chooseUsernameTitle => 'Elige un nombre de usuario';

  @override
  String get chooseUsernameIntro =>
      'Tus amigos te encuentran e invitan por tu nombre de usuario. No podrás cambiarlo después.';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHelper => '3–20 caracteres: a–z, 0–9 y _';

  @override
  String get usernameInvalid =>
      'Usa 3–20 caracteres: a–z, 0–9 o _, sin espacios.';

  @override
  String get usernameTaken => 'Ese nombre de usuario ya está en uso';

  @override
  String get displayNameLabel => 'Nombre visible';

  @override
  String get displayNameHelper =>
      'Cómo te ven los demás. Déjalo vacío para usar tu nombre de usuario.';

  @override
  String displayNameTooLong(int max) {
    return 'Usa como máximo $max caracteres.';
  }

  @override
  String get continueButton => 'Continuar';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get sessionError => 'No pudimos cargar tu cuenta.';
}
