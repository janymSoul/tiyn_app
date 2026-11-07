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

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionClose => 'Закрыть';

  @override
  String get createTaskTitle => 'Новая задача';

  @override
  String get createMilestoneTitle => 'Новый этап';

  @override
  String createFor(String name) {
    return 'Для: $name';
  }

  @override
  String get fieldTitle => 'Название';

  @override
  String get fieldReward => 'Награда (₸)';

  @override
  String get fieldPenalty => 'Штраф (₸)';

  @override
  String get fieldDeadlineDate => 'Дата';

  @override
  String get fieldDeadlineTime => 'Время';

  @override
  String get fieldDescription => 'Описание (необязательно)';

  @override
  String get penaltyToggle => 'Добавить штраф за невыполнение';

  @override
  String get createAddTask => 'Добавить задачу';

  @override
  String get createAddMilestone => 'Добавить этап';

  @override
  String get errTitleRequired => 'Введите название.';

  @override
  String get errTitleTooLong =>
      'Название слишком длинное (не более 200 символов).';

  @override
  String get errAmountInvalid => 'Введите сумму, например 1 500.';

  @override
  String errRewardRange(String max) {
    return 'Награда должна быть больше 0 и не более $max.';
  }

  @override
  String errPenaltyRange(String max) {
    return 'Штраф не может быть больше $max.';
  }

  @override
  String get errDeadlinePast => 'Выберите время в будущем.';

  @override
  String get errDeadlineAfterMilestone =>
      'Срок должен заканчиваться раньше этапа.';

  @override
  String get errorInvalidTitle => 'Сервер не принял это название.';

  @override
  String get errorInvalidReward => 'Сервер не принял эту награду.';

  @override
  String get errorInvalidPenalty => 'Сервер не принял этот штраф.';

  @override
  String get errorInvalidDeadline => 'Сервер не принял этот срок.';

  @override
  String get errorInvalidMilestone => 'Этот этап уже закрыт.';

  @override
  String get errorTeenRequired => 'Этот подросток не подключён к вам.';

  @override
  String get errorInvalidIdempotencyKey =>
      'Не удалось отправить. Закройте форму и попробуйте снова.';

  @override
  String get createUnsure =>
      'Не удалось понять, сохранилась ли задача. Повторите: она не добавится дважды.';

  @override
  String get createEditDetails => 'Изменить данные';

  @override
  String get createEditWarnTitle => 'Изменить данные?';

  @override
  String get createEditWarnBody =>
      'Первая попытка могла уже пройти. Если вы измените данные и отправите, может появиться вторая задача.';

  @override
  String get createEditAnyway => 'Всё равно изменить';

  @override
  String get createNewTaskTooltip => 'Новая задача';

  @override
  String get createNewMilestoneTooltip => 'Новый этап';

  @override
  String get actionSend => 'Отправить';

  @override
  String get reviewEmpty => 'Проверять нечего. Отлично!';

  @override
  String reviewAttempt(int n) {
    return 'Попытка $n';
  }

  @override
  String get reviewApprove => 'Принять';

  @override
  String get reviewRedo => 'Попросить переделать';

  @override
  String get reviewReject => 'Отклонить';

  @override
  String get reviewNote => 'Комментарий (необязательно)';

  @override
  String get reviewRedoTitle => 'Попросить переделать';

  @override
  String reviewRedoHint(String name) {
    return 'Задача вернётся к: $name. Можно назначить новый срок.';
  }

  @override
  String get reviewDeadlineKeep => 'Оставить прежний срок';

  @override
  String get reviewDeadlineChange => 'Новый срок';

  @override
  String get reviewRejectTitle => 'Отклонить задачу?';

  @override
  String reviewRejectBody(String name) {
    return 'Это окончательно. $name не сможет её переделать.';
  }

  @override
  String get reviewChanged =>
      'Задача только что изменилась. Вот актуальные данные.';

  @override
  String get reviewNoProof => 'Подтверждение не приложено.';

  @override
  String get reviewPhotoFailed => 'Не удалось загрузить фото.';

  @override
  String get reviewZoomHint => 'Нажмите, чтобы увеличить';

  @override
  String get reviewProofLabel => 'Подтверждение';

  @override
  String get teenSubmitProof => 'Отправить подтверждение';

  @override
  String get teenSubmitMilestone => 'Сдать этап';

  @override
  String get proofTakePhoto => 'Сделать фото';

  @override
  String get proofChoosePhoto => 'Выбрать из галереи';

  @override
  String get proofWriteNote => 'Написать заметку';

  @override
  String get proofNoteLabel => 'Твоя заметка';

  @override
  String get proofTooLarge =>
      'Фото слишком большое, даже после сжатия. Попробуй другое.';

  @override
  String get proofUnreadable =>
      'Не получилось прочитать фото. Попробуй другое.';

  @override
  String get teenWaiting => 'Ждёт проверки родителя';

  @override
  String get teenRejectedLine => 'Родитель отклонил эту задачу.';

  @override
  String get teenExpiredLine => 'Срок прошёл.';

  @override
  String get teenCancelledLine => 'Задача отменена.';

  @override
  String get teenRedoTitle => 'Родитель просит переделать';

  @override
  String get teenNoteFromParent => 'Комментарий родителя';

  @override
  String teenPenaltyLine(String amount) {
    return 'Если не успеешь, спишется $amount.';
  }

  @override
  String get milestoneStepsTitle => 'Шаги';

  @override
  String milestoneStepsApproved(int done, int total) {
    return 'Принято шагов: $done из $total';
  }

  @override
  String milestoneBlockedPending(int done, int total) {
    return 'Сначала выполни все шаги. Принято $done из $total.';
  }

  @override
  String get milestoneBlockedEmpty => 'В этом этапе пока нет шагов.';

  @override
  String get errorDeadlinePassed =>
      'Срок прошёл, поэтому отправить уже нельзя.';

  @override
  String get errorUnsupportedProof =>
      'Не удалось принять. Попробуй другое фото или более короткую заметку.';

  @override
  String get errorPayloadTooLarge => 'Фото слишком большое. Попробуй другое.';

  @override
  String get errorTaskChanged =>
      'Задача только что изменилась. Вот актуальные данные.';

  @override
  String get parentCancelTask => 'Отменить задачу';

  @override
  String get parentCancelMilestone => 'Отменить этап';

  @override
  String get parentCancelTaskTitle => 'Отменить эту задачу?';

  @override
  String get parentCancelMilestoneTitle => 'Отменить этот этап?';

  @override
  String get parentCancelBody =>
      'Её больше нельзя будет выполнить или отправить. Это нельзя отменить.';

  @override
  String get parentKeepIt => 'Оставить';

  @override
  String get parentConfirmCancel => 'Да, отменить';

  @override
  String get parentAddToMilestone => 'Добавить задачу в этот этап';

  @override
  String get parentNoteLabel => 'Заметка';

  @override
  String get pushBannerOpen => 'Открыть';

  @override
  String get pushBannerDismiss => 'Закрыть';

  @override
  String get notifyAskTitleTeen => 'Узнавай о новых задачах и деньгах';

  @override
  String notifyParentSheetTitle(String name) {
    return 'Узнайте, когда $name отправит подтверждение';
  }

  @override
  String get notifyParentSheetBody =>
      'Мы сообщим, как только будет что проверить.';

  @override
  String get notifyFallbackName => 'ваш подросток';

  @override
  String get notifyTurnOn => 'Включить';

  @override
  String get notifyNotNow => 'Не сейчас';

  @override
  String get notifyDeniedTitle => 'Уведомления выключены';

  @override
  String get notifyDeniedBody =>
      'Пока уведомления выключены, об обновлениях не узнать. Их можно включить в настройках.';

  @override
  String get notifyOpenSettings => 'Открыть настройки';

  @override
  String get notifyDismiss => 'Закрыть';

  @override
  String get notifyTeenSheetBody =>
      'Сразу скажем, когда придёт задача или родитель примет решение.';
}
