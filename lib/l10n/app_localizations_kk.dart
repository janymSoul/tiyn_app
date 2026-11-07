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
  String get errorUnknown => 'Бірдеңе дұрыс болмады. Қайталап көріңіз.';

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

  @override
  String get parentHomeTitle => 'Менің жасөспірімдерім';

  @override
  String get parentHomeAdd => 'Қосу';

  @override
  String get addTeenTitle => 'Жасөспірім қосу';

  @override
  String teenStatusToCheck(int count) {
    return '$count тексеруге';
  }

  @override
  String teenStatusActive(int count) {
    return '$count орындалуда';
  }

  @override
  String get teenStatusIdle => 'Белсенді тапсырма жоқ';

  @override
  String navBadgeWaiting(int count) {
    return 'Күтуде: $count';
  }

  @override
  String get taskStateAssigned => 'Орындау керек';

  @override
  String get taskStateSubmitted => 'Тексеруді күтуде';

  @override
  String get taskStateApproved => 'Қабылданды';

  @override
  String get taskStateRejected => 'Қабылданбады';

  @override
  String get taskStateCancelled => 'Бас тартылды';

  @override
  String get taskStateExpired => 'Мерзімі өтті';

  @override
  String teenTabTasks(int count) {
    return 'Тапсырмалар ($count)';
  }

  @override
  String teenTabMilestones(int count) {
    return 'Кезеңдер ($count)';
  }

  @override
  String teenFinished(int count) {
    return 'Аяқталғандар ($count)';
  }

  @override
  String get teenNoTasks => 'Әзірге тапсырма жоқ.';

  @override
  String get teenNoMilestones => 'Әзірге кезең жоқ.';

  @override
  String get teenNothingOpen => 'Қазір ашық тапсырма жоқ.';

  @override
  String milestoneProgress(int done, int total) {
    return '$total ішінен $done орындалды';
  }

  @override
  String get milestoneNoTasks => 'Әзірге тапсырма жоқ';

  @override
  String deadlineToday(String time) {
    return 'Мерзімі: бүгін, $time';
  }

  @override
  String deadlineTomorrow(String time) {
    return 'Мерзімі: ертең, $time';
  }

  @override
  String deadlineOn(String date, String time) {
    return 'Мерзімі: $date, $time';
  }

  @override
  String get actionBack => 'Артқа';

  @override
  String get teenTasksTitle => 'Тапсырмалар';

  @override
  String get teenMilestonesTitle => 'Кезеңдер';

  @override
  String get teenNothingToDo => 'Әзірге істер жоқ. Демал!';

  @override
  String teenPendingChip(String amount) {
    return '$amount тексеруді күтуде';
  }

  @override
  String get actionCancel => 'Бас тарту';

  @override
  String get actionClose => 'Жабу';

  @override
  String get createTaskTitle => 'Жаңа тапсырма';

  @override
  String get createMilestoneTitle => 'Жаңа кезең';

  @override
  String createFor(String name) {
    return 'Кімге: $name';
  }

  @override
  String get fieldTitle => 'Атауы';

  @override
  String get fieldReward => 'Сыйақы (₸)';

  @override
  String get fieldPenalty => 'Айыппұл (₸)';

  @override
  String get fieldDeadlineDate => 'Күні';

  @override
  String get fieldDeadlineTime => 'Уақыты';

  @override
  String get fieldDescription => 'Сипаттама (міндетті емес)';

  @override
  String get penaltyToggle => 'Орындалмаса айыппұл қосу';

  @override
  String get createAddTask => 'Тапсырма қосу';

  @override
  String get createAddMilestone => 'Кезең қосу';

  @override
  String get errTitleRequired => 'Атауын енгізіңіз.';

  @override
  String get errTitleTooLong => 'Атауы тым ұзын (ең көбі 200 таңба).';

  @override
  String get errAmountInvalid => 'Соманы енгізіңіз, мысалы 1 500.';

  @override
  String errRewardRange(String max) {
    return 'Сыйақы 0-ден көп және ең көбі $max болуы керек.';
  }

  @override
  String errPenaltyRange(String max) {
    return 'Айыппұл $max-ден аспауы керек.';
  }

  @override
  String get errDeadlinePast => 'Болашақтағы уақытты таңдаңыз.';

  @override
  String get errDeadlineAfterMilestone =>
      'Мерзім кезеңнен бұрын аяқталуы керек.';

  @override
  String get errorInvalidTitle => 'Сервер бұл атауды қабылдамады.';

  @override
  String get errorInvalidReward => 'Сервер бұл сыйақыны қабылдамады.';

  @override
  String get errorInvalidPenalty => 'Сервер бұл айыппұлды қабылдамады.';

  @override
  String get errorInvalidDeadline => 'Сервер бұл мерзімді қабылдамады.';

  @override
  String get errorInvalidMilestone => 'Бұл кезең енді ашық емес.';

  @override
  String get errorTeenRequired => 'Бұл жасөспірім сізбен байланыспаған.';

  @override
  String get errorInvalidIdempotencyKey =>
      'Жіберу кезінде қате кетті. Форманы жауып, қайта көріңіз.';

  @override
  String get createUnsure =>
      'Тапсырма сақталғаны белгісіз. Қайталаңыз: ол екі рет қосылмайды.';

  @override
  String get createEditDetails => 'Деректерді өзгерту';

  @override
  String get createEditWarnTitle => 'Деректерді өзгерту керек пе?';

  @override
  String get createEditWarnBody =>
      'Бірінші әрекет өтіп кеткен болуы мүмкін. Деректерді өзгертіп жіберсеңіз, екінші тапсырма пайда болуы мүмкін.';

  @override
  String get createEditAnyway => 'Бәрібір өзгерту';

  @override
  String get createNewTaskTooltip => 'Жаңа тапсырма';

  @override
  String get createNewMilestoneTooltip => 'Жаңа кезең';

  @override
  String get actionSend => 'Жіберу';

  @override
  String get reviewEmpty => 'Тексеретін ештеңе жоқ. Тамаша!';

  @override
  String reviewAttempt(int n) {
    return '$n-әрекет';
  }

  @override
  String get reviewApprove => 'Қабылдау';

  @override
  String get reviewRedo => 'Қайта жасауды сұрау';

  @override
  String get reviewReject => 'Қабылдамау';

  @override
  String get reviewNote => 'Ескертпе (міндетті емес)';

  @override
  String get reviewRedoTitle => 'Қайта жасауды сұрау';

  @override
  String reviewRedoHint(String name) {
    return 'Тапсырма қайтадан $name қолына өтеді. Жаңа мерзім беруге болады.';
  }

  @override
  String get reviewDeadlineKeep => 'Бұрынғы мерзімді қалдыру';

  @override
  String get reviewDeadlineChange => 'Жаңа мерзім';

  @override
  String get reviewRejectTitle => 'Тапсырманы қабылдамау керек пе?';

  @override
  String reviewRejectBody(String name) {
    return 'Бұл түпкілікті шешім. $name оны қайта жасай алмайды.';
  }

  @override
  String get reviewChanged =>
      'Тапсырма жаңа ғана өзгерді. Міне, соңғы нұсқасы.';

  @override
  String get reviewNoProof => 'Растама тіркелмеген.';

  @override
  String get reviewPhotoFailed => 'Фотоны жүктеу мүмкін болмады.';

  @override
  String get reviewZoomHint => 'Үлкейту үшін басыңыз';

  @override
  String get reviewProofLabel => 'Растама';

  @override
  String get teenSubmitProof => 'Растама жіберу';

  @override
  String get teenSubmitMilestone => 'Кезеңді тапсыру';

  @override
  String get proofTakePhoto => 'Фото түсіру';

  @override
  String get proofChoosePhoto => 'Галереядан таңдау';

  @override
  String get proofWriteNote => 'Ескертпе жазу';

  @override
  String get proofNoteLabel => 'Сенің ескертпең';

  @override
  String get proofTooLarge =>
      'Фото тым үлкен, кішірейткеннен кейін де. Басқасын көр.';

  @override
  String get proofUnreadable => 'Фотоны оқи алмадық. Басқасын көр.';

  @override
  String get teenWaiting => 'Ата-ананың тексеруін күтуде';

  @override
  String get teenRejectedLine => 'Ата-анаң бұл тапсырманы қабылдамады.';

  @override
  String get teenExpiredLine => 'Мерзімі өтті.';

  @override
  String get teenCancelledLine => 'Тапсырма бас тартылды.';

  @override
  String get teenRedoTitle => 'Ата-анаң қайта жасауды сұрады';

  @override
  String get teenNoteFromParent => 'Ата-ананың ескертпесі';

  @override
  String teenPenaltyLine(String amount) {
    return 'Мерзімді жіберіп алсаң, $amount алынады.';
  }

  @override
  String get milestoneStepsTitle => 'Қадамдар';

  @override
  String milestoneStepsApproved(int done, int total) {
    return '$total қадамның $done қабылданды';
  }

  @override
  String milestoneBlockedPending(int done, int total) {
    return 'Алдымен барлық қадамды орында. $total ішінен $done қабылданды.';
  }

  @override
  String get milestoneBlockedEmpty => 'Бұл кезеңде әзірге қадам жоқ.';

  @override
  String get errorDeadlinePassed => 'Мерзім өтті, сондықтан жіберуге болмайды.';

  @override
  String get errorUnsupportedProof =>
      'Қабылдай алмадық. Басқа фото немесе қысқа ескертпе көр.';

  @override
  String get errorPayloadTooLarge => 'Фото тым үлкен. Басқасын көр.';

  @override
  String get errorTaskChanged =>
      'Тапсырма жаңа ғана өзгерді. Міне, соңғы нұсқасы.';

  @override
  String get parentCancelTask => 'Тапсырманы болдырмау';

  @override
  String get parentCancelMilestone => 'Кезеңді болдырмау';

  @override
  String get parentCancelTaskTitle => 'Бұл тапсырманы болдырмау керек пе?';

  @override
  String get parentCancelMilestoneTitle => 'Бұл кезеңді болдырмау керек пе?';

  @override
  String get parentCancelBody =>
      'Оны енді орындауға немесе жіберуге болмайды. Мұны қайтару мүмкін емес.';

  @override
  String get parentKeepIt => 'Қалдыру';

  @override
  String get parentConfirmCancel => 'Иә, болдырмау';

  @override
  String get parentAddToMilestone => 'Осы кезеңге тапсырма қосу';

  @override
  String get parentNoteLabel => 'Ескерту';

  @override
  String get pushBannerOpen => 'Ашу';

  @override
  String get pushBannerDismiss => 'Жабу';

  @override
  String get notifyAskTitleTeen =>
      'Жаңа тапсырмалар мен ақша туралы біліп отыр';

  @override
  String notifyParentSheetTitle(String name) {
    return '$name растама жібергенде хабарлама алыңыз';
  }

  @override
  String get notifyParentSheetBody =>
      'Тексеретін нәрсе пайда болғанда хабарлаймыз.';

  @override
  String get notifyFallbackName => 'жасөспіріміңіз';

  @override
  String get notifyTurnOn => 'Қосу';

  @override
  String get notifyNotNow => 'Қазір емес';

  @override
  String get notifyDeniedTitle => 'Хабарламалар өшірулі';

  @override
  String get notifyDeniedBody =>
      'Хабарламалар өшірулі тұрғанда жаңалықтардан хабарсыз қаласыз. Оларды баптауларда қосуға болады.';

  @override
  String get notifyOpenSettings => 'Баптауларды ашу';

  @override
  String get notifyDismiss => 'Жабу';

  @override
  String get notifyTeenSheetBody =>
      'Тапсырма келгенде немесе ата-ана шешім қабылдағанда бірден хабарлаймыз.';

  @override
  String get payoutCashOut => 'Төлем сұрау';

  @override
  String payoutAvailable(String amount) {
    return 'Қолжетімді: $amount';
  }

  @override
  String get fieldPayoutAmount => 'Сома (₸)';

  @override
  String payoutMinHint(String min) {
    return 'Ең аз сома: $min';
  }

  @override
  String get payoutAsk => 'Кімнен сұрау';

  @override
  String payoutTo(String name) {
    return 'Кімге: $name';
  }

  @override
  String get payoutSend => 'Сұрау жіберу';

  @override
  String get payoutBackHome => 'Басты бетке';

  @override
  String payoutSent(String name) {
    return 'Сұрау жіберілді: $name';
  }

  @override
  String get errPayoutAmountPositive => 'Нөлден үлкен сома енгіз.';

  @override
  String errPayoutBelowMin(String min) {
    return 'Төлемнің ең аз сомасы — $min.';
  }

  @override
  String errPayoutAboveAvailable(String available) {
    return 'Саған $available қолжетімді.';
  }

  @override
  String get errPayoutChooseParent => 'Кімнен сұрайтыныңды таңда.';

  @override
  String get errPayoutTooSmall => 'Бұл төлемнің ең аз сомасынан кем.';

  @override
  String get errPayoutInsufficient =>
      'Мұншама сома енді қолжетімді емес. Сұрауға бекітілген немесе мақсатқа бөлінген ақша қолжетімсіз.';

  @override
  String get errPayoutAlreadyOpen =>
      'Саған ашық сұрау бар. Ата-анаңның жауабын күт немесе оны болдырма.';

  @override
  String get errPayoutNotLinked => 'Бұл ата-анамен байланыс үзілген.';

  @override
  String get payoutUnsure =>
      'Сұраудың жіберілгені белгісіз. Қайтала: ол екі рет жіберілмейді.';

  @override
  String get payoutEditWarnBody =>
      'Бірінші әрекет өтіп кеткен болуы мүмкін. Деректерді өзгертіп жіберсең, ашық сұрау бар болғандықтан, қабылданбауы мүмкін.';

  @override
  String cashOutDebt(String owed) {
    return 'Өткізіп алған тапсырма үшін $owed қарыз жиналды. Жаңа сыйақылар алдымен қарызды жабады, содан кейін төлем сұрай аласың.';
  }

  @override
  String cashOutBelowMin(String min) {
    return 'Төлем сұрау үшін кемінде $min қолжетімді болуы керек.';
  }

  @override
  String get cashOutLockedNote => 'Мақсатқа бөлінген ақша есепке алынбайды.';

  @override
  String payoutWaitingFor(String name) {
    return 'Жауап күтілуде: $name';
  }

  @override
  String get payoutWaitingForParent => 'Ата-анаңның жауабы күтілуде';

  @override
  String payoutHeld(String amount) {
    return '$amount осы сұрауға бекітілді';
  }

  @override
  String payoutDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count күн қалды',
      one: '$count күн қалды',
    );
    return '$_temp0';
  }

  @override
  String payoutHoursLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сағат қалды',
      one: '$count сағат қалды',
    );
    return '$_temp0';
  }

  @override
  String get payoutLessThanHour => 'Бір сағаттан аз қалды';

  @override
  String get payoutAnyMoment => 'Мерзімі кез келген минутта аяқталады';

  @override
  String get payoutCancelRequest => 'Сұрауды болдырмау';

  @override
  String get payoutCancelTitle => 'Сұрауды болдырмау керек пе?';

  @override
  String payoutCancelBody(String amount) {
    return '$amount сұрауы кері қайтарылады, ақша қайтадан қолжетімді болады.';
  }

  @override
  String get payoutConfirmCancel => 'Иә, сұрауды болдырмау';

  @override
  String get payoutChanged => 'Сұрау жаңа ғана өзгерді. Міне, соңғы нұсқасы.';

  @override
  String get payoutUnavailable => 'Бұл сұрау енді жоқ.';

  @override
  String payoutFulfilledTitle(String amount) {
    return '$amount төлемі расталды';
  }

  @override
  String get payoutFulfilledBody =>
      'Ата-анаң ақшаны жібергенін растады. Банкіңді тексер. Ақша келмесе, онымен сөйлес.';

  @override
  String get payoutDeclinedTitle => 'Сұрау қабылданбады';

  @override
  String payoutDeclinedBody(String amount) {
    return 'Ата-анаң сұрауды қабылдамады. $amount қайтадан қолжетімді.';
  }

  @override
  String get payoutExpiredTitle => 'Сұраудың мерзімі өтті';

  @override
  String payoutExpiredBody(String amount) {
    return 'Ата-анаң уақытында жауап бермеді. $amount қайтадан қолжетімді, қайта сұрай аласың.';
  }

  @override
  String get payoutCancelledTitle => 'Сұрау кері қайтарылды';

  @override
  String payoutCancelledBody(String amount) {
    return '$amount қайтадан қолжетімді.';
  }

  @override
  String get payoutUnlinkedTitle => 'Байланыс үзілді';

  @override
  String payoutUnlinkedBody(String amount) {
    return 'Ата-анаңмен байланыс үзілгендіктен, сұрау жойылды. $amount қайтадан қолжетімді.';
  }

  @override
  String payoutSectionTitle(int count) {
    return 'Төлем сұраулары ($count)';
  }

  @override
  String proofsSectionTitle(int count) {
    return 'Растаулар ($count)';
  }

  @override
  String get payoutRowTitle => 'Төлем сұрауы';
}
