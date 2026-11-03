// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'tiyn';

  @override
  String get actionSignOut => 'Шығу';

  @override
  String get actionTryAgain => 'Қайталау';

  @override
  String get comingSoon => 'Жақында';

  @override
  String get navHome => 'Басты бет';

  @override
  String get navProgress => 'Прогресс';

  @override
  String get navGoals => 'Мақсаттар';

  @override
  String get navActivity => 'Белсенділік';

  @override
  String get navToCheck => 'Тексеруге';

  @override
  String get signInTagline =>
      'Тап, жина, үй шаруасы мен жақсы бағалар үшін ақша ал.';

  @override
  String get roleTeen => 'Жасөспірім';

  @override
  String get roleTeenSubtitle => 'Мен тапсырма орындап, ақша табамын';

  @override
  String get roleParent => 'Ата-ана';

  @override
  String get roleParentSubtitle => 'Мен тапсырма беріп, растаймын';

  @override
  String get signInContinueWithGoogle => 'Google арқылы жалғастыру';

  @override
  String get signInRoleNote =>
      'Рөл алғашқы кіргенде сақталады және кейін өзгертілмейді.';

  @override
  String get signInFailed => 'Кіру мүмкін болмады. Қайталап көріңіз.';

  @override
  String get errorNoConnection => 'Байланыс жоқ. Желіні тексеріңіз.';

  @override
  String get errorTimeout => 'Сервер ұзақ жауап бермеді. Қайталап көріңіз.';

  @override
  String get errorUnauthenticated => 'Сессия аяқталды. Қайтадан кіріңіз.';

  @override
  String get errorForbidden => 'Бұл әрекетке рұқсат жоқ.';

  @override
  String get errorServer =>
      'Біздің тарапта қателік болды. Кейінірек қайталап көріңіз.';

  @override
  String get errorInvalidIdentity =>
      'Google кіруден бас тартты. Қайталап көріңіз.';

  @override
  String get errorIdentityUnavailable =>
      'Google қазір қолжетімсіз. Кейінірек қайталап көріңіз.';

  @override
  String get errorInvalidJoinCode =>
      'Мұндай код табылмады. Кодты тексеріп, қайталап көріңіз.';

  @override
  String get errorConflict => 'Бұл әрекет бар деректермен сәйкес келмейді.';

  @override
  String errorUnknown(String code) {
    return 'Бірдеңе дұрыс болмады ($code).';
  }

  @override
  String get splashLoadFailed =>
      'Жүктеу мүмкін болмады. Байланысты тексеріп, қайталап көріңіз.';

  @override
  String get joinTitle => 'Ата-анаңның кодын енгіз';

  @override
  String get joinSubtitle =>
      'Анаңнан немесе әкеңнен Tiyn қолданбасындағы 6 таңбалы кодты сұра.';

  @override
  String get joinCodeLabel => 'Код';

  @override
  String get joinConnect => 'Қосылу';

  @override
  String get joinMultiParentInfo =>
      'Бірнеше ата-анаға қосылуға болады. Олардың әрқайсысы саған тапсырма бере алады.';

  @override
  String get joinWrongAccountHint =>
      'Аккаунт қате ме? Шығып, басқа Google аккаунтымен кір.';

  @override
  String get parentCodeTitle => 'Жасөспіріміңізді қосыңыз';

  @override
  String get parentCodeSubtitle =>
      'Жасөспіріміңізге Tiyn ашып, «Жасөспірім» таңдап, осы кодты енгізуін айтыңыз. Содан кейін оған тапсырма бере аласыз.';

  @override
  String get parentCodeYourCode => 'Сіздің кодыңыз';

  @override
  String get parentCodeNeverChanges =>
      'Код өзгермейді. Тек отбасыңызбен бөлісіңіз.';

  @override
  String get parentCodeSend => 'Кодты жіберу';

  @override
  String get parentCodeCopy => 'Көшіру';

  @override
  String get parentCodeCopied => 'Код көшірілді';

  @override
  String parentCodeShareMessage(String code) {
    return 'Менімен бірге Tiyn-ге қосыл. Менің отбасылық кодым: $code';
  }

  @override
  String get parentLinkedTeens => 'Қосылған жасөспірімдер';

  @override
  String get parentTeensLoadFailed =>
      'Жасөспірімдерді жүктеу мүмкін болмады. Қайталау үшін төмен тартыңыз.';

  @override
  String parentTeensLoadFailedCode(String code) {
    return 'Жасөспірімдерді жүктеу мүмкін болмады ($code). Қайталау үшін төмен тартыңыз.';
  }

  @override
  String get parentNoTeensYet =>
      'Әзірге ешкім жоқ. Жасөспірім кодты енгізгенде жаңарту үшін төмен тартыңыз.';

  @override
  String teenGreeting(String name) {
    return 'Сәлем, $name';
  }

  @override
  String teenConnectedTo(String names) {
    return 'Қосылған: $names';
  }

  @override
  String get signInWelcomeNote => 'Google аккаунты арқылы кіріңіз';

  @override
  String get signInRoleTitle => 'Сіз кімсіз?';

  @override
  String signInGoogleAccount(String email) {
    return 'Google аккаунты: $email';
  }

  @override
  String get actionContinue => 'Жалғастыру';

  @override
  String get signInUseAnotherAccount => 'Басқа Google аккаунты';

  @override
  String get signInExpired => 'Кіру мерзімі аяқталды, қайта кіріңіз';
}
