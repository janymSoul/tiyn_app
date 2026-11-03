import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'tiyn'**
  String get appTitle;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get actionSignOut;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get navGoals;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navToCheck.
  ///
  /// In en, this message translates to:
  /// **'To check'**
  String get navToCheck;

  /// No description provided for @signInTagline.
  ///
  /// In en, this message translates to:
  /// **'Earn it. Save it. Get paid for chores and good grades.'**
  String get signInTagline;

  /// No description provided for @roleTeen.
  ///
  /// In en, this message translates to:
  /// **'Teen'**
  String get roleTeen;

  /// No description provided for @roleTeenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I do chores and earn'**
  String get roleTeenSubtitle;

  /// No description provided for @roleParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get roleParent;

  /// No description provided for @roleParentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I set tasks and approve'**
  String get roleParentSubtitle;

  /// No description provided for @signInContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInContinueWithGoogle;

  /// No description provided for @signInRoleNote.
  ///
  /// In en, this message translates to:
  /// **'Your role is saved on first sign-in and can\'t be changed later.'**
  String get signInRoleNote;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Try again.'**
  String get signInFailed;

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network.'**
  String get errorNoConnection;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to answer. Try again.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthenticated.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Sign in again.'**
  String get errorUnauthenticated;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You can\'t do that.'**
  String get errorForbidden;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again later.'**
  String get errorServer;

  /// No description provided for @errorInvalidIdentity.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was rejected. Try again.'**
  String get errorInvalidIdentity;

  /// No description provided for @errorIdentityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google is unavailable right now. Try again later.'**
  String get errorIdentityUnavailable;

  /// No description provided for @errorInvalidJoinCode.
  ///
  /// In en, this message translates to:
  /// **'We could not find that code. Check it and try again.'**
  String get errorInvalidJoinCode;

  /// No description provided for @errorConflict.
  ///
  /// In en, this message translates to:
  /// **'That conflicts with data that already exists.'**
  String get errorConflict;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}).'**
  String errorUnknown(String code);

  /// No description provided for @splashLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load. Check your connection and try again.'**
  String get splashLoadFailed;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your parent\'s code'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your mom or dad for the 6-letter code from their Tiyn app.'**
  String get joinSubtitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get joinCodeLabel;

  /// No description provided for @joinCodeTooShort.
  ///
  /// In en, this message translates to:
  /// **'That code is too short. It has 6 letters or numbers.'**
  String get joinCodeTooShort;

  /// No description provided for @joinConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get joinConnect;

  /// No description provided for @joinMultiParentInfo.
  ///
  /// In en, this message translates to:
  /// **'You can connect to more than one parent. Each of them can give you tasks.'**
  String get joinMultiParentInfo;

  /// No description provided for @joinWrongAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Wrong account? Sign out and use another Google account.'**
  String get joinWrongAccountHint;

  /// No description provided for @parentCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect your teen'**
  String get parentCodeTitle;

  /// No description provided for @parentCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your teen to open Tiyn, choose Teen, and type this code. Then you can give them tasks.'**
  String get parentCodeSubtitle;

  /// No description provided for @parentCodeYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your code'**
  String get parentCodeYourCode;

  /// No description provided for @parentCodeNeverChanges.
  ///
  /// In en, this message translates to:
  /// **'It never changes. Share it only with your family.'**
  String get parentCodeNeverChanges;

  /// No description provided for @parentCodeSend.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get parentCodeSend;

  /// No description provided for @parentCodeCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get parentCodeCopy;

  /// No description provided for @parentCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get parentCodeCopied;

  /// No description provided for @parentCodeShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join me on Tiyn. My family code is {code}'**
  String parentCodeShareMessage(String code);

  /// No description provided for @parentLinkedTeens.
  ///
  /// In en, this message translates to:
  /// **'Linked teens'**
  String get parentLinkedTeens;

  /// No description provided for @parentTeensLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your teens. Pull down to retry.'**
  String get parentTeensLoadFailed;

  /// No description provided for @parentTeensLoadFailedCode.
  ///
  /// In en, this message translates to:
  /// **'Could not load your teens ({code}). Pull down to retry.'**
  String parentTeensLoadFailedCode(String code);

  /// No description provided for @parentNoTeensYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet. Pull down to refresh once your teen enters the code.'**
  String get parentNoTeensYet;

  /// No description provided for @teenGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String teenGreeting(String name);

  /// No description provided for @teenConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {names}'**
  String teenConnectedTo(String names);

  /// No description provided for @signInWelcomeNote.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your Google account'**
  String get signInWelcomeNote;

  /// No description provided for @signInRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get signInRoleTitle;

  /// No description provided for @signInGoogleAccount.
  ///
  /// In en, this message translates to:
  /// **'Google account: {email}'**
  String signInGoogleAccount(String email);

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @signInUseAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different Google account'**
  String get signInUseAnotherAccount;

  /// No description provided for @signInExpired.
  ///
  /// In en, this message translates to:
  /// **'Sign-in expired. Sign in again.'**
  String get signInExpired;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
