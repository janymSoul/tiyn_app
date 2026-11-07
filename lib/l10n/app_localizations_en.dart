// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'tiyn';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get navHome => 'Home';

  @override
  String get navProgress => 'Progress';

  @override
  String get navGoals => 'Goals';

  @override
  String get navActivity => 'Activity';

  @override
  String get navToCheck => 'To check';

  @override
  String get signInTagline =>
      'Earn it. Save it. Get paid for chores and good grades.';

  @override
  String get roleTeen => 'Teen';

  @override
  String get roleTeenSubtitle => 'I do chores and earn';

  @override
  String get roleParent => 'Parent';

  @override
  String get roleParentSubtitle => 'I set tasks and approve';

  @override
  String get signInContinueWithGoogle => 'Continue with Google';

  @override
  String get signInRoleNote =>
      'Your role is saved on first sign-in and can\'t be changed later.';

  @override
  String get signInFailed => 'Sign-in failed. Try again.';

  @override
  String get errorNoConnection => 'No connection. Check your network.';

  @override
  String get errorTimeout => 'The server took too long to answer. Try again.';

  @override
  String get errorUnauthenticated => 'Your session has ended. Sign in again.';

  @override
  String get errorForbidden => 'You can\'t do that.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Try again later.';

  @override
  String get errorInvalidIdentity => 'Google sign-in was rejected. Try again.';

  @override
  String get errorIdentityUnavailable =>
      'Google is unavailable right now. Try again later.';

  @override
  String get errorInvalidJoinCode =>
      'We could not find that code. Check it and try again.';

  @override
  String get errorConflict => 'That conflicts with data that already exists.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get splashLoadFailed =>
      'Could not load. Check your connection and try again.';

  @override
  String get joinTitle => 'Enter your parent\'s code';

  @override
  String get joinSubtitle =>
      'Ask your mom or dad for the 6-character code from their Tiyn app.';

  @override
  String get joinCodeLabel => 'Code';

  @override
  String get joinConnect => 'Connect';

  @override
  String get joinMultiParentInfo =>
      'You can connect to more than one parent. Each of them can give you tasks.';

  @override
  String get joinWrongAccountHint =>
      'Wrong account? Sign out and use another Google account.';

  @override
  String get parentCodeTitle => 'Connect your teen';

  @override
  String get parentCodeSubtitle =>
      'Ask your teen to open Tiyn, choose Teen, and type this code. Then you can give them tasks.';

  @override
  String get parentCodeYourCode => 'Your code';

  @override
  String get parentCodeNeverChanges =>
      'It never changes. Share it only with your family.';

  @override
  String get parentCodeSend => 'Send code';

  @override
  String get parentCodeCopy => 'Copy';

  @override
  String get parentCodeCopied => 'Code copied';

  @override
  String parentCodeShareMessage(String code) {
    return 'Join me on Tiyn. My family code is $code';
  }

  @override
  String teenGreeting(String name) {
    return 'Hi, $name';
  }

  @override
  String teenConnectedTo(String names) {
    return 'Connected to $names';
  }

  @override
  String get signInWelcomeNote => 'Sign in with your Google account';

  @override
  String get signInRoleTitle => 'Who are you?';

  @override
  String signInGoogleAccount(String email) {
    return 'Google account: $email';
  }

  @override
  String get actionContinue => 'Continue';

  @override
  String get signInUseAnotherAccount => 'Use a different Google account';

  @override
  String get signInExpired => 'Sign-in expired. Sign in again.';

  @override
  String get parentHomeTitle => 'My teens';

  @override
  String get parentHomeAdd => 'Add';

  @override
  String get addTeenTitle => 'Add a teen';

  @override
  String teenStatusToCheck(int count) {
    return '$count to check';
  }

  @override
  String teenStatusActive(int count) {
    return '$count active';
  }

  @override
  String get teenStatusIdle => 'Nothing active';

  @override
  String navBadgeWaiting(int count) {
    return '$count waiting';
  }
}
