// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'tiyn';

  @override
  String get actionSignOut => 'Выйти';

  @override
  String get actionTryAgain => 'Повторить';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get navHome => 'Главная';

  @override
  String get navProgress => 'Прогресс';

  @override
  String get navGoals => 'Цели';

  @override
  String get navActivity => 'Активность';

  @override
  String get navToCheck => 'На проверке';

  @override
  String get signInTagline =>
      'Зарабатывай, копи, получай деньги за дела и хорошие оценки.';

  @override
  String get roleTeen => 'Подросток';

  @override
  String get roleTeenSubtitle => 'Я делаю дела и зарабатываю';

  @override
  String get roleParent => 'Родитель';

  @override
  String get roleParentSubtitle => 'Я ставлю задачи и подтверждаю';

  @override
  String get signInContinueWithGoogle => 'Продолжить через Google';

  @override
  String get signInRoleNote =>
      'Роль сохраняется при первом входе и позже не меняется.';

  @override
  String get signInFailed => 'Не удалось войти. Попробуйте ещё раз.';

  @override
  String get errorNoConnection => 'Нет соединения. Проверьте сеть.';

  @override
  String get errorTimeout => 'Сервер долго не отвечает. Попробуйте ещё раз.';

  @override
  String get errorUnauthenticated => 'Сессия завершена. Войдите снова.';

  @override
  String get errorForbidden => 'Недостаточно прав для этого действия.';

  @override
  String get errorServer =>
      'Что-то пошло не так на нашей стороне. Попробуйте позже.';

  @override
  String get errorInvalidIdentity =>
      'Google отклонил вход. Попробуйте ещё раз.';

  @override
  String get errorIdentityUnavailable =>
      'Google сейчас недоступен. Попробуйте позже.';

  @override
  String get errorInvalidJoinCode =>
      'Мы не нашли такой код. Проверьте его и попробуйте снова.';

  @override
  String get errorConflict =>
      'Это действие конфликтует с уже существующими данными.';

  @override
  String get errorUnknown => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get splashLoadFailed =>
      'Не удалось загрузить. Проверьте соединение и попробуйте снова.';

  @override
  String get joinTitle => 'Введи код родителя';

  @override
  String get joinSubtitle =>
      'Попроси маму или папу код из 6 символов из их приложения Tiyn.';

  @override
  String get joinCodeLabel => 'Код';

  @override
  String get joinConnect => 'Подключиться';

  @override
  String get joinMultiParentInfo =>
      'Можно подключиться к нескольким родителям. Каждый из них сможет давать тебе задания.';

  @override
  String get joinWrongAccountHint =>
      'Не тот аккаунт? Выйди и войди через другой аккаунт Google.';

  @override
  String get parentCodeTitle => 'Подключите подростка';

  @override
  String get parentCodeSubtitle =>
      'Попросите подростка открыть Tiyn, выбрать «Подросток» и ввести этот код. После этого вы сможете ставить ему задачи.';

  @override
  String get parentCodeYourCode => 'Ваш код';

  @override
  String get parentCodeNeverChanges =>
      'Код не меняется. Делитесь им только с семьёй.';

  @override
  String get parentCodeSend => 'Отправить код';

  @override
  String get parentCodeCopy => 'Копировать';

  @override
  String get parentCodeCopied => 'Код скопирован';

  @override
  String parentCodeShareMessage(String code) {
    return 'Присоединяйся ко мне в Tiyn. Мой семейный код: $code';
  }

  @override
  String teenGreeting(String name) {
    return 'Привет, $name';
  }

  @override
  String teenConnectedTo(String names) {
    return 'Подключено: $names';
  }

  @override
  String get signInWelcomeNote => 'Войдите через аккаунт Google';

  @override
  String get signInRoleTitle => 'Кто вы?';

  @override
  String signInGoogleAccount(String email) {
    return 'Аккаунт Google: $email';
  }

  @override
  String get actionContinue => 'Продолжить';

  @override
  String get signInUseAnotherAccount => 'Другой аккаунт Google';

  @override
  String get signInExpired => 'Вход истёк, войдите снова';

  @override
  String get parentHomeTitle => 'Мои подростки';

  @override
  String get parentHomeAdd => 'Добавить';

  @override
  String get addTeenTitle => 'Добавить подростка';

  @override
  String teenStatusToCheck(int count) {
    return '$count на проверке';
  }

  @override
  String teenStatusActive(int count) {
    return '$count в работе';
  }

  @override
  String get teenStatusIdle => 'Нет активных задач';

  @override
  String navBadgeWaiting(int count) {
    return 'Ожидают: $count';
  }

  @override
  String get taskStateAssigned => 'Нужно сделать';

  @override
  String get taskStateSubmitted => 'Ждёт проверки';

  @override
  String get taskStateApproved => 'Принято';

  @override
  String get taskStateRejected => 'Отклонено';

  @override
  String get taskStateCancelled => 'Отменено';

  @override
  String get taskStateExpired => 'Просрочено';

  @override
  String teenTabTasks(int count) {
    return 'Задачи ($count)';
  }

  @override
  String teenTabMilestones(int count) {
    return 'Этапы ($count)';
  }

  @override
  String teenFinished(int count) {
    return 'Завершённые ($count)';
  }

  @override
  String get teenNoTasks => 'Задач пока нет.';

  @override
  String get teenNoMilestones => 'Этапов пока нет.';

  @override
  String get teenNothingOpen => 'Сейчас ничего нет в работе.';

  @override
  String milestoneProgress(int done, int total) {
    return 'Выполнено $done из $total';
  }

  @override
  String get milestoneNoTasks => 'Задач пока нет';

  @override
  String deadlineToday(String time) {
    return 'Срок: сегодня, $time';
  }

  @override
  String deadlineTomorrow(String time) {
    return 'Срок: завтра, $time';
  }

  @override
  String deadlineOn(String date, String time) {
    return 'Срок: $date, $time';
  }

  @override
  String get actionBack => 'Назад';

  @override
  String get teenTasksTitle => 'Задачи';

  @override
  String get teenMilestonesTitle => 'Этапы';

  @override
  String get teenNothingToDo => 'Пока дел нет. Отдыхай!';

  @override
  String teenPendingChip(String amount) {
    return '$amount ждёт проверки';
  }
}
