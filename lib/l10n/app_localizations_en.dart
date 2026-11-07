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

  @override
  String get taskStateAssigned => 'To do';

  @override
  String get taskStateSubmitted => 'Waiting for check';

  @override
  String get taskStateApproved => 'Approved';

  @override
  String get taskStateRejected => 'Rejected';

  @override
  String get taskStateCancelled => 'Cancelled';

  @override
  String get taskStateExpired => 'Expired';

  @override
  String teenTabTasks(int count) {
    return 'Tasks ($count)';
  }

  @override
  String teenTabMilestones(int count) {
    return 'Milestones ($count)';
  }

  @override
  String teenFinished(int count) {
    return 'Finished ($count)';
  }

  @override
  String get teenNoTasks => 'No tasks yet.';

  @override
  String get teenNoMilestones => 'No milestones yet.';

  @override
  String get teenNothingOpen => 'Nothing open right now.';

  @override
  String milestoneProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get milestoneNoTasks => 'No tasks yet';

  @override
  String deadlineToday(String time) {
    return 'Due today, $time';
  }

  @override
  String deadlineTomorrow(String time) {
    return 'Due tomorrow, $time';
  }

  @override
  String deadlineOn(String date, String time) {
    return 'Due $date, $time';
  }

  @override
  String get actionBack => 'Back';

  @override
  String get teenTasksTitle => 'Tasks';

  @override
  String get teenMilestonesTitle => 'Milestones';

  @override
  String get teenNothingToDo => 'Nothing to do right now. Enjoy!';

  @override
  String teenPendingChip(String amount) {
    return '$amount waiting for check';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get createTaskTitle => 'New task';

  @override
  String get createMilestoneTitle => 'New milestone';

  @override
  String createFor(String name) {
    return 'For $name';
  }

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldReward => 'Reward (₸)';

  @override
  String get fieldPenalty => 'Penalty (₸)';

  @override
  String get fieldDeadlineDate => 'Date';

  @override
  String get fieldDeadlineTime => 'Time';

  @override
  String get fieldDescription => 'Description (optional)';

  @override
  String get penaltyToggle => 'Add a penalty if it\'s missed';

  @override
  String get createAddTask => 'Add task';

  @override
  String get createAddMilestone => 'Add milestone';

  @override
  String get errTitleRequired => 'Enter a title.';

  @override
  String get errTitleTooLong =>
      'The title is too long (200 characters at most).';

  @override
  String get errAmountInvalid => 'Enter an amount, like 1 500.';

  @override
  String errRewardRange(String max) {
    return 'The reward must be more than 0 and at most $max.';
  }

  @override
  String errPenaltyRange(String max) {
    return 'The penalty can be at most $max.';
  }

  @override
  String get errDeadlinePast => 'Pick a time in the future.';

  @override
  String get errDeadlineAfterMilestone =>
      'It must end before the milestone does.';

  @override
  String get errorInvalidTitle => 'The server did not accept this title.';

  @override
  String get errorInvalidReward => 'The server did not accept this reward.';

  @override
  String get errorInvalidPenalty => 'The server did not accept this penalty.';

  @override
  String get errorInvalidDeadline => 'The server did not accept this deadline.';

  @override
  String get errorInvalidMilestone => 'That milestone is no longer open.';

  @override
  String get errorTeenRequired => 'That teen is not linked to you.';

  @override
  String get errorInvalidIdempotencyKey =>
      'Something went wrong while sending. Close the form and try again.';

  @override
  String get createUnsure =>
      'We could not tell if the task was saved. Try again: it will not be added twice.';

  @override
  String get createEditDetails => 'Edit details';

  @override
  String get createEditWarnTitle => 'Change the details?';

  @override
  String get createEditWarnBody =>
      'The first attempt may already have gone through. If you change something and send it, a second task could be created.';

  @override
  String get createEditAnyway => 'Change anyway';

  @override
  String get createNewTaskTooltip => 'New task';

  @override
  String get createNewMilestoneTooltip => 'New milestone';

  @override
  String get actionSend => 'Send';

  @override
  String get reviewEmpty => 'Nothing to check. Nice!';

  @override
  String reviewAttempt(int n) {
    return 'Attempt $n';
  }

  @override
  String get reviewApprove => 'Approve';

  @override
  String get reviewRedo => 'Ask to redo';

  @override
  String get reviewReject => 'Reject';

  @override
  String get reviewNote => 'Note (optional)';

  @override
  String get reviewRedoTitle => 'Ask to redo';

  @override
  String reviewRedoHint(String name) {
    return 'The task goes back to $name. You can give a new deadline.';
  }

  @override
  String get reviewDeadlineKeep => 'Keep the current deadline';

  @override
  String get reviewDeadlineChange => 'New deadline';

  @override
  String get reviewRejectTitle => 'Reject this task?';

  @override
  String reviewRejectBody(String name) {
    return 'This is final. $name will not be able to redo it.';
  }

  @override
  String get reviewChanged => 'This task just changed. Here is the latest.';

  @override
  String get reviewNoProof => 'No proof was attached.';

  @override
  String get reviewPhotoFailed => 'Could not load the photo.';

  @override
  String get reviewZoomHint => 'Tap to zoom';

  @override
  String get reviewProofLabel => 'Proof';

  @override
  String get teenSubmitProof => 'Submit proof';

  @override
  String get teenSubmitMilestone => 'Submit milestone';

  @override
  String get proofTakePhoto => 'Take photo';

  @override
  String get proofChoosePhoto => 'Choose from gallery';

  @override
  String get proofWriteNote => 'Write a note';

  @override
  String get proofNoteLabel => 'Your note';

  @override
  String get proofTooLarge =>
      'That photo is too big, even after shrinking it. Try another one.';

  @override
  String get proofUnreadable =>
      'We couldn\'t read that photo. Try another one.';

  @override
  String get teenWaiting => 'Waiting for your parent';

  @override
  String get teenRejectedLine => 'Your parent rejected this task.';

  @override
  String get teenExpiredLine => 'The deadline passed.';

  @override
  String get teenCancelledLine => 'This task was cancelled.';

  @override
  String get teenRedoTitle => 'Your parent asked you to redo this';

  @override
  String get teenNoteFromParent => 'Note from your parent';

  @override
  String teenPenaltyLine(String amount) {
    return 'Missing the deadline costs $amount.';
  }

  @override
  String get milestoneStepsTitle => 'Steps';

  @override
  String milestoneStepsApproved(int done, int total) {
    return '$done of $total steps approved';
  }

  @override
  String milestoneBlockedPending(int done, int total) {
    return 'Finish all steps first. $done of $total approved.';
  }

  @override
  String get milestoneBlockedEmpty => 'This milestone has no steps yet.';

  @override
  String get errorDeadlinePassed =>
      'The deadline has passed, so this can\'t be sent anymore.';

  @override
  String get errorUnsupportedProof =>
      'We couldn\'t accept that. Try a different photo, or a shorter note.';

  @override
  String get errorPayloadTooLarge => 'That photo is too big. Try another one.';

  @override
  String get errorTaskChanged => 'This task just changed. Here is the latest.';

  @override
  String get parentCancelTask => 'Cancel task';

  @override
  String get parentCancelMilestone => 'Cancel milestone';

  @override
  String get parentCancelTaskTitle => 'Cancel this task?';

  @override
  String get parentCancelMilestoneTitle => 'Cancel this milestone?';

  @override
  String get parentCancelBody =>
      'It can\'t be done or submitted any more. This can\'t be undone.';

  @override
  String get parentKeepIt => 'Keep it';

  @override
  String get parentConfirmCancel => 'Yes, cancel';

  @override
  String get parentAddToMilestone => 'Add task to this milestone';

  @override
  String get parentNoteLabel => 'Note';

  @override
  String get pushBannerOpen => 'Open';

  @override
  String get pushBannerDismiss => 'Dismiss';

  @override
  String get notifyAskTitleTeen => 'Get notified about new tasks and money';

  @override
  String notifyParentSheetTitle(String name) {
    return 'Get notified when $name sends proof';
  }

  @override
  String get notifyParentSheetBody =>
      'We\'ll tell you as soon as there\'s something to check.';

  @override
  String get notifyFallbackName => 'your teen';

  @override
  String get notifyTurnOn => 'Turn on';

  @override
  String get notifyNotNow => 'Not now';

  @override
  String get notifyDeniedTitle => 'Notifications are off';

  @override
  String get notifyDeniedBody =>
      'You won\'t hear about updates until you turn them on in settings.';

  @override
  String get notifyOpenSettings => 'Open settings';

  @override
  String get notifyDismiss => 'Dismiss';

  @override
  String get notifyTeenSheetBody =>
      'We\'ll let you know the moment a task arrives or a parent decides.';

  @override
  String get payoutCashOut => 'Cash out';

  @override
  String payoutAvailable(String amount) {
    return 'Available: $amount';
  }

  @override
  String get fieldPayoutAmount => 'Amount (₸)';

  @override
  String payoutMinHint(String min) {
    return 'Smallest cash-out: $min';
  }

  @override
  String get payoutAsk => 'Ask';

  @override
  String payoutTo(String name) {
    return 'To: $name';
  }

  @override
  String get payoutSend => 'Send request';

  @override
  String get payoutBackHome => 'Back to home';

  @override
  String payoutSent(String name) {
    return 'Request sent to $name';
  }

  @override
  String get errPayoutAmountPositive => 'Enter an amount greater than zero.';

  @override
  String errPayoutBelowMin(String min) {
    return 'The smallest cash-out is $min.';
  }

  @override
  String errPayoutAboveAvailable(String available) {
    return 'You have $available available.';
  }

  @override
  String get errPayoutChooseParent => 'Choose who to ask.';

  @override
  String get errPayoutTooSmall =>
      'That is below the smallest amount you can cash out.';

  @override
  String get errPayoutInsufficient =>
      'You don\'t have that much available any more. Money already held for a request or saved for a goal is not available.';

  @override
  String get errPayoutAlreadyOpen =>
      'You already have a cash-out request open. Wait for your parent to answer, or cancel it first.';

  @override
  String get errPayoutNotLinked => 'You are no longer linked to this parent.';

  @override
  String get payoutUnsure =>
      'We could not tell if the request was sent. Try again: it will not be sent twice.';

  @override
  String get payoutEditWarnBody =>
      'The first attempt may already have gone through. If you change something and send it, it may be refused because a request is already open.';

  @override
  String cashOutDebt(String owed) {
    return 'You owe $owed for a missed task. New rewards pay it off first, then you can cash out.';
  }

  @override
  String cashOutBelowMin(String min) {
    return 'You need at least $min available to cash out.';
  }

  @override
  String get cashOutLockedNote => 'Money set aside for goals is not included.';

  @override
  String payoutWaitingFor(String name) {
    return 'Waiting for $name';
  }

  @override
  String get payoutWaitingForParent => 'Waiting for your parent';

  @override
  String payoutHeld(String amount) {
    return '$amount held for this request';
  }

  @override
  String payoutDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String payoutHoursLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours left',
      one: '1 hour left',
    );
    return '$_temp0';
  }

  @override
  String get payoutLessThanHour => 'Less than an hour left';

  @override
  String get payoutAnyMoment => 'Expires any moment';

  @override
  String get payoutCancelRequest => 'Cancel request';

  @override
  String get payoutCancelTitle => 'Cancel this request?';

  @override
  String payoutCancelBody(String amount) {
    return 'Your $amount request will be withdrawn and the money is available again.';
  }

  @override
  String get payoutConfirmCancel => 'Yes, cancel the request';

  @override
  String get payoutChanged => 'This request just changed. Here is the latest.';

  @override
  String get payoutUnavailable => 'This request is no longer available.';

  @override
  String payoutFulfilledTitle(String amount) {
    return 'Payout of $amount confirmed';
  }

  @override
  String get payoutFulfilledBody =>
      'Your parent confirmed sending the money. Check your bank. If it hasn\'t arrived, talk to them.';

  @override
  String get payoutDeclinedTitle => 'Request declined';

  @override
  String payoutDeclinedBody(String amount) {
    return 'Your parent declined the request. $amount is available again.';
  }

  @override
  String get payoutExpiredTitle => 'Request expired';

  @override
  String payoutExpiredBody(String amount) {
    return 'Your parent didn\'t answer in time. $amount is available again, and you can ask again.';
  }

  @override
  String get payoutCancelledTitle => 'Request cancelled';

  @override
  String payoutCancelledBody(String amount) {
    return '$amount is available again.';
  }

  @override
  String get payoutUnlinkedTitle => 'No longer linked';

  @override
  String payoutUnlinkedBody(String amount) {
    return 'You are no longer linked to this parent, so the request was cancelled. $amount is available again.';
  }

  @override
  String payoutSectionTitle(int count) {
    return 'Payout requests ($count)';
  }

  @override
  String proofsSectionTitle(int count) {
    return 'Proofs ($count)';
  }

  @override
  String get payoutRowTitle => 'Cash-out request';
}
