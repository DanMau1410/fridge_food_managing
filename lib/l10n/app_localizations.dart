import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// App name shown in the window or task switcher.
  ///
  /// In en, this message translates to:
  /// **'Fridge Food Manager'**
  String get appTitle;

  /// Navigation destination for the food inventory.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get navFood;

  /// Navigation destination for the grocery list.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get navGroceries;

  /// Navigation destination for recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navRecipes;

  /// Title of the account screen and tooltip of the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Household & account'**
  String get accountTitle;

  /// Heading of the account section on the Household & account screen.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// Shown when the food inventory is empty.
  ///
  /// In en, this message translates to:
  /// **'No food yet. What you add will show up here.'**
  String get foodEmpty;

  /// Shown when the grocery list is empty.
  ///
  /// In en, this message translates to:
  /// **'Your grocery list is empty.'**
  String get groceriesEmpty;

  /// Shown when there are no recipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet.'**
  String get recipesEmpty;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetables;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get categoryFruit;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Meat'**
  String get categoryMeat;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Fish & seafood'**
  String get categoryFish;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Dairy & eggs'**
  String get categoryDairyEggs;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Grains & bread'**
  String get categoryGrainsBread;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Legumes'**
  String get categoryLegumes;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Frozen'**
  String get categoryFrozen;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Canned & jarred'**
  String get categoryCanned;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Snacks & sweets'**
  String get categorySnacks;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get categoryBeverages;

  /// Food category.
  ///
  /// In en, this message translates to:
  /// **'Condiments & spices'**
  String get categoryCondimentsSpices;

  /// Food category for anything that fits no other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Storage location.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get locationFridge;

  /// Storage location.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get locationFreezer;

  /// Storage location: the pantry or kitchen cabinet.
  ///
  /// In en, this message translates to:
  /// **'Cabinet'**
  String get locationCabinet;

  /// Unit abbreviation: pieces.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get unitPcs;

  /// Unit abbreviation: grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// Unit abbreviation: kilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// Unit abbreviation: millilitres.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// Unit abbreviation: litres.
  ///
  /// In en, this message translates to:
  /// **'l'**
  String get unitL;

  /// Unit abbreviation: teaspoon (5 ml).
  ///
  /// In en, this message translates to:
  /// **'tsp'**
  String get unitTsp;

  /// Unit abbreviation: tablespoon (15 ml).
  ///
  /// In en, this message translates to:
  /// **'tbsp'**
  String get unitTbsp;

  /// Unit abbreviation: cup (240 ml).
  ///
  /// In en, this message translates to:
  /// **'cup'**
  String get unitCup;

  /// Sign-in screen title and submit button in sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Sign-in screen title and submit button in sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Optional display name field at sign-up.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get displayNameOptionalLabel;

  /// Switches the sign-in screen to sign-up mode.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get switchToSignUp;

  /// Switches the sign-in screen to sign-in mode.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get switchToSignIn;

  /// Validation: empty email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get errorEmailRequired;

  /// Validation: empty password.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get errorPasswordRequired;

  /// Validation: password shorter than the minimum at sign-up.
  ///
  /// In en, this message translates to:
  /// **'Use at least {min} characters.'**
  String errorPasswordTooShort(int min);

  /// Sign-in failed. Same text for an unknown email and a wrong password.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authInvalidCredentials;

  /// Sign-up failed: the email has an account.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get authEmailInUse;

  /// Sign-up failed: Firebase rejected the password.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get authWeakPassword;

  /// Malformed email.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get authInvalidEmail;

  /// Firebase throttled the sign-in attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authTooManyRequests;

  /// The email belongs to an account with a different sign-in method.
  ///
  /// In en, this message translates to:
  /// **'This email already signs in another way.'**
  String get authAccountExists;

  /// A network error.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get errorNoConnection;

  /// Any other error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorGeneric;

  /// Choose-username screen title.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get chooseUsernameTitle;

  /// Explains the username on the Choose-username screen.
  ///
  /// In en, this message translates to:
  /// **'Friends find and invite you by your username. You can\'t change it later.'**
  String get chooseUsernameIntro;

  /// Username field label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Helper text under the username field.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters: a–z, 0–9 and _'**
  String get usernameHelper;

  /// Validation: the username breaks the rule.
  ///
  /// In en, this message translates to:
  /// **'Use 3–20 characters: a–z, 0–9 or _, with no spaces.'**
  String get usernameInvalid;

  /// Another account has this username.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get usernameTaken;

  /// Display name field label.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// Helper text under the display name field.
  ///
  /// In en, this message translates to:
  /// **'How others see you. Leave it empty to use your username.'**
  String get displayNameHelper;

  /// Validation: the display name is too long.
  ///
  /// In en, this message translates to:
  /// **'Use at most {max} characters.'**
  String displayNameTooLong(int max);

  /// Submits the Choose-username screen.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Signs the user out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Shown when the account can't be loaded; offers Sign out.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your account.'**
  String get sessionError;

  /// Tooltip of the edit button next to the display name, and the title of its dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit display name'**
  String get editDisplayName;

  /// Signs in with a Google account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Opens the password reset dialog from Sign-in.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// Title of the password reset dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetPasswordTitle;

  /// Explains the password reset dialog.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a link to choose a new password.'**
  String get resetPasswordIntro;

  /// Sends the password reset email.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendResetLink;

  /// Confirmation after a reset request. Same text whether or not the account exists.
  ///
  /// In en, this message translates to:
  /// **'If an account uses that email, a reset link is on its way. Check your inbox.'**
  String get resetPasswordSent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
