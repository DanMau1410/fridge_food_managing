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
  String get accountSection => 'Account';

  @override
  String get foodEmpty => 'No food yet. What you add will show up here.';

  @override
  String get groceriesEmpty => 'Your grocery list is empty.';

  @override
  String get recipesEmpty => 'No recipes yet.';

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

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get displayNameOptionalLabel => 'Display name (optional)';

  @override
  String get switchToSignUp => 'New here? Create an account';

  @override
  String get switchToSignIn => 'Already have an account? Sign in';

  @override
  String get errorEmailRequired => 'Enter your email.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String errorPasswordTooShort(int min) {
    return 'Use at least $min characters.';
  }

  @override
  String get authInvalidCredentials => 'Wrong email or password.';

  @override
  String get authEmailInUse =>
      'An account with this email already exists. Sign in instead.';

  @override
  String get authWeakPassword => 'Choose a stronger password.';

  @override
  String get authInvalidEmail => 'That email address doesn\'t look right.';

  @override
  String get authTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authAccountExists => 'This email already signs in another way.';

  @override
  String get errorNoConnection =>
      'No connection. Check your internet and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get chooseUsernameTitle => 'Choose a username';

  @override
  String get chooseUsernameIntro =>
      'Friends find and invite you by your username. You can\'t change it later.';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameHelper => '3–20 characters: a–z, 0–9 and _';

  @override
  String get usernameInvalid =>
      'Use 3–20 characters: a–z, 0–9 or _, with no spaces.';

  @override
  String get usernameTaken => 'Username already taken';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameHelper =>
      'How others see you. Leave it empty to use your username.';

  @override
  String displayNameTooLong(int max) {
    return 'Use at most $max characters.';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get signOut => 'Sign out';

  @override
  String get sessionError => 'We couldn\'t load your account.';

  @override
  String get editDisplayName => 'Edit display name';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset your password';

  @override
  String get resetPasswordIntro =>
      'We\'ll email you a link to choose a new password.';

  @override
  String get sendResetLink => 'Send link';

  @override
  String get resetPasswordSent =>
      'If an account uses that email, a reset link is on its way. Check your inbox.';
}
