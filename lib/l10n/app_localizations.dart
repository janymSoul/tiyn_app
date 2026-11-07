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
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

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
  /// **'Ask your mom or dad for the 6-character code from their Tiyn app.'**
  String get joinSubtitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get joinCodeLabel;

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

  /// No description provided for @parentHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'My teens'**
  String get parentHomeTitle;

  /// No description provided for @parentHomeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get parentHomeAdd;

  /// No description provided for @addTeenTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a teen'**
  String get addTeenTitle;

  /// No description provided for @teenStatusToCheck.
  ///
  /// In en, this message translates to:
  /// **'{count} to check'**
  String teenStatusToCheck(int count);

  /// No description provided for @teenStatusActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String teenStatusActive(int count);

  /// No description provided for @teenStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Nothing active'**
  String get teenStatusIdle;

  /// No description provided for @navBadgeWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String navBadgeWaiting(int count);

  /// No description provided for @taskStateAssigned.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskStateAssigned;

  /// No description provided for @taskStateSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Waiting for check'**
  String get taskStateSubmitted;

  /// No description provided for @taskStateApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get taskStateApproved;

  /// No description provided for @taskStateRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get taskStateRejected;

  /// No description provided for @taskStateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStateCancelled;

  /// No description provided for @taskStateExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get taskStateExpired;

  /// No description provided for @teenTabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks ({count})'**
  String teenTabTasks(int count);

  /// No description provided for @teenTabMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones ({count})'**
  String teenTabMilestones(int count);

  /// No description provided for @teenFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished ({count})'**
  String teenFinished(int count);

  /// No description provided for @teenNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet.'**
  String get teenNoTasks;

  /// No description provided for @teenNoMilestones.
  ///
  /// In en, this message translates to:
  /// **'No milestones yet.'**
  String get teenNoMilestones;

  /// No description provided for @teenNothingOpen.
  ///
  /// In en, this message translates to:
  /// **'Nothing open right now.'**
  String get teenNothingOpen;

  /// No description provided for @milestoneProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String milestoneProgress(int done, int total);

  /// No description provided for @milestoneNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get milestoneNoTasks;

  /// No description provided for @deadlineToday.
  ///
  /// In en, this message translates to:
  /// **'Due today, {time}'**
  String deadlineToday(String time);

  /// No description provided for @deadlineTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow, {time}'**
  String deadlineTomorrow(String time);

  /// No description provided for @deadlineOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}, {time}'**
  String deadlineOn(String date, String time);

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @teenTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get teenTasksTitle;

  /// No description provided for @teenMilestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get teenMilestonesTitle;

  /// No description provided for @teenNothingToDo.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do right now. Enjoy!'**
  String get teenNothingToDo;

  /// No description provided for @teenPendingChip.
  ///
  /// In en, this message translates to:
  /// **'{amount} waiting for check'**
  String teenPendingChip(String amount);

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @createTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get createTaskTitle;

  /// No description provided for @createMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'New milestone'**
  String get createMilestoneTitle;

  /// No description provided for @createFor.
  ///
  /// In en, this message translates to:
  /// **'For {name}'**
  String createFor(String name);

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldReward.
  ///
  /// In en, this message translates to:
  /// **'Reward (₸)'**
  String get fieldReward;

  /// No description provided for @fieldPenalty.
  ///
  /// In en, this message translates to:
  /// **'Penalty (₸)'**
  String get fieldPenalty;

  /// No description provided for @fieldDeadlineDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDeadlineDate;

  /// No description provided for @fieldDeadlineTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get fieldDeadlineTime;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get fieldDescription;

  /// No description provided for @penaltyToggle.
  ///
  /// In en, this message translates to:
  /// **'Add a penalty if it\'s missed'**
  String get penaltyToggle;

  /// No description provided for @createAddTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get createAddTask;

  /// No description provided for @createAddMilestone.
  ///
  /// In en, this message translates to:
  /// **'Add milestone'**
  String get createAddMilestone;

  /// No description provided for @errTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title.'**
  String get errTitleRequired;

  /// No description provided for @errTitleTooLong.
  ///
  /// In en, this message translates to:
  /// **'The title is too long (200 characters at most).'**
  String get errTitleTooLong;

  /// No description provided for @errAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount, like 1 500.'**
  String get errAmountInvalid;

  /// No description provided for @errRewardRange.
  ///
  /// In en, this message translates to:
  /// **'The reward must be more than 0 and at most {max}.'**
  String errRewardRange(String max);

  /// No description provided for @errPenaltyRange.
  ///
  /// In en, this message translates to:
  /// **'The penalty can be at most {max}.'**
  String errPenaltyRange(String max);

  /// No description provided for @errDeadlinePast.
  ///
  /// In en, this message translates to:
  /// **'Pick a time in the future.'**
  String get errDeadlinePast;

  /// No description provided for @errDeadlineAfterMilestone.
  ///
  /// In en, this message translates to:
  /// **'It must end before the milestone does.'**
  String get errDeadlineAfterMilestone;

  /// No description provided for @errorInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this title.'**
  String get errorInvalidTitle;

  /// No description provided for @errorInvalidReward.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this reward.'**
  String get errorInvalidReward;

  /// No description provided for @errorInvalidPenalty.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this penalty.'**
  String get errorInvalidPenalty;

  /// No description provided for @errorInvalidDeadline.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this deadline.'**
  String get errorInvalidDeadline;

  /// No description provided for @errorInvalidMilestone.
  ///
  /// In en, this message translates to:
  /// **'That milestone is no longer open.'**
  String get errorInvalidMilestone;

  /// No description provided for @errorTeenRequired.
  ///
  /// In en, this message translates to:
  /// **'That teen is not linked to you.'**
  String get errorTeenRequired;

  /// No description provided for @errorInvalidIdempotencyKey.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while sending. Close the form and try again.'**
  String get errorInvalidIdempotencyKey;

  /// No description provided for @createUnsure.
  ///
  /// In en, this message translates to:
  /// **'We could not tell if the task was saved. Try again: it will not be added twice.'**
  String get createUnsure;

  /// No description provided for @createEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get createEditDetails;

  /// No description provided for @createEditWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Change the details?'**
  String get createEditWarnTitle;

  /// No description provided for @createEditWarnBody.
  ///
  /// In en, this message translates to:
  /// **'The first attempt may already have gone through. If you change something and send it, a second task could be created.'**
  String get createEditWarnBody;

  /// No description provided for @createEditAnyway.
  ///
  /// In en, this message translates to:
  /// **'Change anyway'**
  String get createEditAnyway;

  /// No description provided for @createNewTaskTooltip.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get createNewTaskTooltip;

  /// No description provided for @createNewMilestoneTooltip.
  ///
  /// In en, this message translates to:
  /// **'New milestone'**
  String get createNewMilestoneTooltip;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @reviewEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to check. Nice!'**
  String get reviewEmpty;

  /// No description provided for @reviewAttempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n}'**
  String reviewAttempt(int n);

  /// No description provided for @reviewApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get reviewApprove;

  /// No description provided for @reviewRedo.
  ///
  /// In en, this message translates to:
  /// **'Ask to redo'**
  String get reviewRedo;

  /// No description provided for @reviewReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reviewReject;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get reviewNote;

  /// No description provided for @reviewRedoTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask to redo'**
  String get reviewRedoTitle;

  /// No description provided for @reviewRedoHint.
  ///
  /// In en, this message translates to:
  /// **'The task goes back to {name}. You can give a new deadline.'**
  String reviewRedoHint(String name);

  /// No description provided for @reviewDeadlineKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep the current deadline'**
  String get reviewDeadlineKeep;

  /// No description provided for @reviewDeadlineChange.
  ///
  /// In en, this message translates to:
  /// **'New deadline'**
  String get reviewDeadlineChange;

  /// No description provided for @reviewRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this task?'**
  String get reviewRejectTitle;

  /// No description provided for @reviewRejectBody.
  ///
  /// In en, this message translates to:
  /// **'This is final. {name} will not be able to redo it.'**
  String reviewRejectBody(String name);

  /// No description provided for @reviewChanged.
  ///
  /// In en, this message translates to:
  /// **'This task just changed. Here is the latest.'**
  String get reviewChanged;

  /// No description provided for @reviewNoProof.
  ///
  /// In en, this message translates to:
  /// **'No proof was attached.'**
  String get reviewNoProof;

  /// No description provided for @reviewPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the photo.'**
  String get reviewPhotoFailed;

  /// No description provided for @reviewZoomHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to zoom'**
  String get reviewZoomHint;

  /// No description provided for @reviewProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Proof'**
  String get reviewProofLabel;

  /// No description provided for @teenSubmitProof.
  ///
  /// In en, this message translates to:
  /// **'Submit proof'**
  String get teenSubmitProof;

  /// No description provided for @teenSubmitMilestone.
  ///
  /// In en, this message translates to:
  /// **'Submit milestone'**
  String get teenSubmitMilestone;

  /// No description provided for @proofTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get proofTakePhoto;

  /// No description provided for @proofChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get proofChoosePhoto;

  /// No description provided for @proofWriteNote.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get proofWriteNote;

  /// No description provided for @proofNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Your note'**
  String get proofNoteLabel;

  /// No description provided for @proofTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too big, even after shrinking it. Try another one.'**
  String get proofTooLarge;

  /// No description provided for @proofUnreadable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read that photo. Try another one.'**
  String get proofUnreadable;

  /// No description provided for @teenWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your parent'**
  String get teenWaiting;

  /// No description provided for @teenRejectedLine.
  ///
  /// In en, this message translates to:
  /// **'Your parent rejected this task.'**
  String get teenRejectedLine;

  /// No description provided for @teenExpiredLine.
  ///
  /// In en, this message translates to:
  /// **'The deadline passed.'**
  String get teenExpiredLine;

  /// No description provided for @teenCancelledLine.
  ///
  /// In en, this message translates to:
  /// **'This task was cancelled.'**
  String get teenCancelledLine;

  /// No description provided for @teenRedoTitle.
  ///
  /// In en, this message translates to:
  /// **'Your parent asked you to redo this'**
  String get teenRedoTitle;

  /// No description provided for @teenNoteFromParent.
  ///
  /// In en, this message translates to:
  /// **'Note from your parent'**
  String get teenNoteFromParent;

  /// No description provided for @teenPenaltyLine.
  ///
  /// In en, this message translates to:
  /// **'Missing the deadline costs {amount}.'**
  String teenPenaltyLine(String amount);

  /// No description provided for @milestoneStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get milestoneStepsTitle;

  /// No description provided for @milestoneStepsApproved.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} steps approved'**
  String milestoneStepsApproved(int done, int total);

  /// No description provided for @milestoneBlockedPending.
  ///
  /// In en, this message translates to:
  /// **'Finish all steps first. {done} of {total} approved.'**
  String milestoneBlockedPending(int done, int total);

  /// No description provided for @milestoneBlockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'This milestone has no steps yet.'**
  String get milestoneBlockedEmpty;

  /// No description provided for @errorDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'The deadline has passed, so this can\'t be sent anymore.'**
  String get errorDeadlinePassed;

  /// No description provided for @errorUnsupportedProof.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t accept that. Try a different photo, or a shorter note.'**
  String get errorUnsupportedProof;

  /// No description provided for @errorPayloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too big. Try another one.'**
  String get errorPayloadTooLarge;

  /// No description provided for @errorTaskChanged.
  ///
  /// In en, this message translates to:
  /// **'This task just changed. Here is the latest.'**
  String get errorTaskChanged;

  /// No description provided for @parentCancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel task'**
  String get parentCancelTask;

  /// No description provided for @parentCancelMilestone.
  ///
  /// In en, this message translates to:
  /// **'Cancel milestone'**
  String get parentCancelMilestone;

  /// No description provided for @parentCancelTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this task?'**
  String get parentCancelTaskTitle;

  /// No description provided for @parentCancelMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this milestone?'**
  String get parentCancelMilestoneTitle;

  /// No description provided for @parentCancelBody.
  ///
  /// In en, this message translates to:
  /// **'It can\'t be done or submitted any more. This can\'t be undone.'**
  String get parentCancelBody;

  /// No description provided for @parentKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get parentKeepIt;

  /// No description provided for @parentConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get parentConfirmCancel;

  /// No description provided for @parentAddToMilestone.
  ///
  /// In en, this message translates to:
  /// **'Add task to this milestone'**
  String get parentAddToMilestone;

  /// No description provided for @parentNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get parentNoteLabel;

  /// No description provided for @pushBannerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get pushBannerOpen;

  /// No description provided for @pushBannerDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get pushBannerDismiss;

  /// No description provided for @notifyAskTitleTeen.
  ///
  /// In en, this message translates to:
  /// **'Get notified about new tasks and money'**
  String get notifyAskTitleTeen;

  /// No description provided for @notifyParentSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified when {name} sends proof'**
  String notifyParentSheetTitle(String name);

  /// No description provided for @notifyParentSheetBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tell you as soon as there\'s something to check.'**
  String get notifyParentSheetBody;

  /// No description provided for @notifyFallbackName.
  ///
  /// In en, this message translates to:
  /// **'your teen'**
  String get notifyFallbackName;

  /// No description provided for @notifyTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notifyTurnOn;

  /// No description provided for @notifyNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifyNotNow;

  /// No description provided for @notifyDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notifyDeniedTitle;

  /// No description provided for @notifyDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t hear about updates until you turn them on in settings.'**
  String get notifyDeniedBody;

  /// No description provided for @notifyOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get notifyOpenSettings;

  /// No description provided for @notifyDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get notifyDismiss;

  /// No description provided for @notifyTeenSheetBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know the moment a task arrives or a parent decides.'**
  String get notifyTeenSheetBody;

  /// No description provided for @payoutCashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get payoutCashOut;

  /// No description provided for @payoutAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {amount}'**
  String payoutAvailable(String amount);

  /// No description provided for @fieldPayoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (₸)'**
  String get fieldPayoutAmount;

  /// No description provided for @payoutMinHint.
  ///
  /// In en, this message translates to:
  /// **'Smallest cash-out: {min}'**
  String payoutMinHint(String min);

  /// No description provided for @payoutAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get payoutAsk;

  /// No description provided for @payoutTo.
  ///
  /// In en, this message translates to:
  /// **'To: {name}'**
  String payoutTo(String name);

  /// No description provided for @payoutSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get payoutSend;

  /// No description provided for @payoutBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get payoutBackHome;

  /// No description provided for @payoutSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}'**
  String payoutSent(String name);

  /// No description provided for @errPayoutAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get errPayoutAmountPositive;

  /// No description provided for @errPayoutBelowMin.
  ///
  /// In en, this message translates to:
  /// **'The smallest cash-out is {min}.'**
  String errPayoutBelowMin(String min);

  /// No description provided for @errPayoutAboveAvailable.
  ///
  /// In en, this message translates to:
  /// **'You have {available} available.'**
  String errPayoutAboveAvailable(String available);

  /// No description provided for @errPayoutChooseParent.
  ///
  /// In en, this message translates to:
  /// **'Choose who to ask.'**
  String get errPayoutChooseParent;

  /// No description provided for @errPayoutTooSmall.
  ///
  /// In en, this message translates to:
  /// **'That is below the smallest amount you can cash out.'**
  String get errPayoutTooSmall;

  /// No description provided for @errPayoutInsufficient.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have that much available any more. Money already held for a request or saved for a goal is not available.'**
  String get errPayoutInsufficient;

  /// No description provided for @errPayoutAlreadyOpen.
  ///
  /// In en, this message translates to:
  /// **'You already have a cash-out request open. Wait for your parent to answer, or cancel it first.'**
  String get errPayoutAlreadyOpen;

  /// No description provided for @errPayoutNotLinked.
  ///
  /// In en, this message translates to:
  /// **'You are no longer linked to this parent.'**
  String get errPayoutNotLinked;

  /// No description provided for @payoutUnsure.
  ///
  /// In en, this message translates to:
  /// **'We could not tell if the request was sent. Try again: it will not be sent twice.'**
  String get payoutUnsure;

  /// No description provided for @payoutEditWarnBody.
  ///
  /// In en, this message translates to:
  /// **'The first attempt may already have gone through. If you change something and send it, it may be refused because a request is already open.'**
  String get payoutEditWarnBody;

  /// No description provided for @cashOutDebt.
  ///
  /// In en, this message translates to:
  /// **'You owe {owed} for a missed task. New rewards pay it off first, then you can cash out.'**
  String cashOutDebt(String owed);

  /// No description provided for @cashOutBelowMin.
  ///
  /// In en, this message translates to:
  /// **'You need at least {min} available to cash out.'**
  String cashOutBelowMin(String min);

  /// No description provided for @cashOutLockedNote.
  ///
  /// In en, this message translates to:
  /// **'Money set aside for goals is not included.'**
  String get cashOutLockedNote;

  /// No description provided for @payoutWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String payoutWaitingFor(String name);

  /// No description provided for @payoutWaitingForParent.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your parent'**
  String get payoutWaitingForParent;

  /// No description provided for @payoutHeld.
  ///
  /// In en, this message translates to:
  /// **'{amount} held for this request'**
  String payoutHeld(String amount);

  /// No description provided for @payoutDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 day left} other{{count} days left}}'**
  String payoutDaysLeft(int count);

  /// No description provided for @payoutHoursLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hour left} other{{count} hours left}}'**
  String payoutHoursLeft(int count);

  /// No description provided for @payoutLessThanHour.
  ///
  /// In en, this message translates to:
  /// **'Less than an hour left'**
  String get payoutLessThanHour;

  /// No description provided for @payoutAnyMoment.
  ///
  /// In en, this message translates to:
  /// **'Expires any moment'**
  String get payoutAnyMoment;

  /// No description provided for @payoutCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get payoutCancelRequest;

  /// No description provided for @payoutCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get payoutCancelTitle;

  /// No description provided for @payoutCancelBody.
  ///
  /// In en, this message translates to:
  /// **'Your {amount} request will be withdrawn and the money is available again.'**
  String payoutCancelBody(String amount);

  /// No description provided for @payoutConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel the request'**
  String get payoutConfirmCancel;

  /// No description provided for @payoutChanged.
  ///
  /// In en, this message translates to:
  /// **'This request just changed. Here is the latest.'**
  String get payoutChanged;

  /// No description provided for @payoutUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available.'**
  String get payoutUnavailable;

  /// No description provided for @payoutFulfilledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout of {amount} confirmed'**
  String payoutFulfilledTitle(String amount);

  /// No description provided for @payoutFulfilledBody.
  ///
  /// In en, this message translates to:
  /// **'Your parent confirmed sending the money. Check your bank. If it hasn\'t arrived, talk to them.'**
  String get payoutFulfilledBody;

  /// No description provided for @payoutDeclinedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get payoutDeclinedTitle;

  /// No description provided for @payoutDeclinedBody.
  ///
  /// In en, this message translates to:
  /// **'Your parent declined the request. {amount} is available again.'**
  String payoutDeclinedBody(String amount);

  /// No description provided for @payoutExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Request expired'**
  String get payoutExpiredTitle;

  /// No description provided for @payoutExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your parent didn\'t answer in time. {amount} is available again, and you can ask again.'**
  String payoutExpiredBody(String amount);

  /// No description provided for @payoutCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get payoutCancelledTitle;

  /// No description provided for @payoutCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} is available again.'**
  String payoutCancelledBody(String amount);

  /// No description provided for @payoutUnlinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'No longer linked'**
  String get payoutUnlinkedTitle;

  /// No description provided for @payoutUnlinkedBody.
  ///
  /// In en, this message translates to:
  /// **'You are no longer linked to this parent, so the request was cancelled. {amount} is available again.'**
  String payoutUnlinkedBody(String amount);

  /// No description provided for @payoutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout requests ({count})'**
  String payoutSectionTitle(int count);

  /// No description provided for @proofsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Proofs ({count})'**
  String proofsSectionTitle(int count);

  /// No description provided for @payoutRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash-out request'**
  String get payoutRowTitle;

  /// No description provided for @payoutAsksForTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} asks for'**
  String payoutAsksForTitle(String name);

  /// No description provided for @payoutStepSend.
  ///
  /// In en, this message translates to:
  /// **'1. Send the money'**
  String get payoutStepSend;

  /// No description provided for @payoutStepConfirm.
  ///
  /// In en, this message translates to:
  /// **'2. Then confirm'**
  String get payoutStepConfirm;

  /// No description provided for @payoutSendHint.
  ///
  /// In en, this message translates to:
  /// **'Send {amount} in your bank app, or hand over cash. Tiyn does not move money itself.'**
  String payoutSendHint(String amount);

  /// No description provided for @payoutCopyAmount.
  ///
  /// In en, this message translates to:
  /// **'Copy amount'**
  String get payoutCopyAmount;

  /// No description provided for @payoutCopied.
  ///
  /// In en, this message translates to:
  /// **'Amount copied'**
  String get payoutCopied;

  /// No description provided for @payoutISentIt.
  ///
  /// In en, this message translates to:
  /// **'I sent it'**
  String get payoutISentIt;

  /// No description provided for @payoutDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get payoutDecline;

  /// No description provided for @payoutConfirmSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm you sent {amount}?'**
  String payoutConfirmSentTitle(String amount);

  /// No description provided for @payoutConfirmSentBody.
  ///
  /// In en, this message translates to:
  /// **'Tiyn can\'t see the transfer. Confirming takes {amount} off the teen\'s balance.'**
  String payoutConfirmSentBody(String amount);

  /// No description provided for @payoutYesSent.
  ///
  /// In en, this message translates to:
  /// **'Yes, I sent it'**
  String get payoutYesSent;

  /// No description provided for @payoutNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get payoutNotYet;

  /// No description provided for @payoutDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline the {amount} request?'**
  String payoutDeclineTitle(String amount);

  /// No description provided for @payoutDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'The teen keeps their money and can ask again.'**
  String get payoutDeclineBody;

  /// No description provided for @payoutKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep it open'**
  String get payoutKeepOpen;

  /// No description provided for @payoutConfirmDecline.
  ///
  /// In en, this message translates to:
  /// **'Yes, decline'**
  String get payoutConfirmDecline;

  /// No description provided for @payoutNoCover.
  ///
  /// In en, this message translates to:
  /// **'The teen\'s balance no longer covers {amount}. A missed-task penalty or a goal saving took part of it. You can decline this request, and the teen can ask again for a smaller amount.'**
  String payoutNoCover(String amount);

  /// No description provided for @payoutSentDone.
  ///
  /// In en, this message translates to:
  /// **'Payout confirmed'**
  String get payoutSentDone;

  /// No description provided for @payoutDeclinedDone.
  ///
  /// In en, this message translates to:
  /// **'Request declined'**
  String get payoutDeclinedDone;

  /// No description provided for @payoutParentFulfilledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout confirmed'**
  String get payoutParentFulfilledTitle;

  /// No description provided for @payoutParentFulfilledBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} was taken off the teen\'s balance.'**
  String payoutParentFulfilledBody(String amount);

  /// No description provided for @payoutParentTeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'The teen cancelled this request'**
  String get payoutParentTeenCancelled;

  /// No description provided for @payoutParentDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined this request'**
  String get payoutParentDeclined;

  /// No description provided for @payoutParentExpired.
  ///
  /// In en, this message translates to:
  /// **'This request expired'**
  String get payoutParentExpired;

  /// No description provided for @payoutParentUnlinked.
  ///
  /// In en, this message translates to:
  /// **'You are no longer linked to this teen. The request was cancelled.'**
  String get payoutParentUnlinked;

  /// No description provided for @payoutOpenBank.
  ///
  /// In en, this message translates to:
  /// **'Open {bank}'**
  String payoutOpenBank(String bank);

  /// No description provided for @payoutBankStore.
  ///
  /// In en, this message translates to:
  /// **'{bank} isn\'t installed. We opened its store page.'**
  String payoutBankStore(String bank);

  /// No description provided for @payoutBankUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open {bank}. Open it yourself, then come back and confirm.'**
  String payoutBankUnavailable(String bank);
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
