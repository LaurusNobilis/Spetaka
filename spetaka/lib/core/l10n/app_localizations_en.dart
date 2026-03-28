// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spetaka';

  @override
  String get navDaily => 'Suggested actions';

  @override
  String get navFriends => 'Friends';

  @override
  String get navSettings => 'Settings';

  @override
  String shellPageIndicatorSemantics(String page) {
    return 'Current page: $page. Swipe left or right to switch pages.';
  }

  @override
  String get actionAdd => 'Add';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionBack => 'Back';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionFlag => 'Flag';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get couldNotSave => 'Could not save. Please try again.';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get addFriendTooltip => 'Add friend';

  @override
  String get addFirstFriend => 'Add first friend';

  @override
  String get emptyFriendsTitle => 'No friends yet.';

  @override
  String get emptyFriendsSubtitle =>
      'Tap the button below to add your first friend.';

  @override
  String get addFriendTitle => 'Add Friend';

  @override
  String get editFriendTitle => 'Edit Friend';

  @override
  String get howToAddFriend => 'How would you like to add this friend?';

  @override
  String get importFromContacts => 'Import from contacts';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get enterDetails => 'Enter details';

  @override
  String get categoryTagsLabel => 'Category tags';

  @override
  String get nameLabel => 'Name';

  @override
  String get mobileLabel => 'Mobile';

  @override
  String get mobilePlaceholder => 'e.g. 06 12 34 56 78';

  @override
  String get notesLabel => 'Notes';

  @override
  String get optionalContextNotes => 'Optional context notes…';

  @override
  String get friendTitle => 'Friend';

  @override
  String get fullDetails => 'Full details';

  @override
  String fullDetailsSemantics(String name) {
    return 'Full details for $name';
  }

  @override
  String get deleteFriendTitle => 'Delete friend?';

  @override
  String get flagConcernTitle => 'Flag concern';

  @override
  String get clearConcernTitle => 'Clear concern?';

  @override
  String get clearConcernAction => 'Clear concern';

  @override
  String get concernLabel => 'Concern';

  @override
  String get concernFlaggedTooltip => 'Concern flagged';

  @override
  String get concernFlaggedSemanticsSuffix => 'concern flagged';

  @override
  String get eventsLabel => 'Events';

  @override
  String get addEventAction => 'Add event';

  @override
  String get contactHistorySection => 'Contact History';

  @override
  String get noContactHistory => 'No contact history yet.';

  @override
  String get logContactTitle => 'Contact completed';

  @override
  String get confirmContactLog => 'Confirm contact';

  @override
  String get howDidItGo => 'Comment ça s\'est passé ?';

  @override
  String get callAction => 'Call';

  @override
  String get smsAction => 'SMS';

  @override
  String get whatsappAction => 'WhatsApp';

  @override
  String get savesContactHistory => 'Saves the contact to history';

  @override
  String get addEventTitle => 'Add Event';

  @override
  String get editEventTitle => 'Edit Event';

  @override
  String get invalidEventIdMessage => 'Invalid event id.';

  @override
  String get couldNotLoadEventMessage => 'Could not load event.';

  @override
  String get eventNotFoundMessage => 'Event not found.';

  @override
  String get deleteEventTitle => 'Delete event?';

  @override
  String get eventTypeLabel => 'Event Type';

  @override
  String get dateLabel => 'Date';

  @override
  String get recurringLabel => 'Recurring';

  @override
  String get checkInCadence => 'Set a repeating check-in cadence';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get addNoteHint => 'Add a note…';

  @override
  String get optionalNoteHint => 'Optional note…';

  @override
  String get everyWeek => 'Every week';

  @override
  String get every2Weeks => 'Every 2 weeks';

  @override
  String get every3Weeks => 'Every 3 weeks';

  @override
  String get monthly => 'Monthly';

  @override
  String get every2Months => 'Every 2 months';

  @override
  String get every3Months => 'Every 3 months';

  @override
  String get every6Months => 'Every 6 months';

  @override
  String get everyYear => 'Every year';

  @override
  String get couldNotLoadEventTypes => 'Could not load event types.';

  @override
  String get invalidNameFallback => 'Invalid name.';

  @override
  String eventTypeInUseNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# events use this type — they will keep their current label.',
      one: '# event uses this type — it will keep its current label.',
    );
    return '$_temp0';
  }

  @override
  String get eventTypesTitle => 'Event Types';

  @override
  String get newEventTypePlaceholder => 'New event type…';

  @override
  String get addTypeTooltip => 'Add type';

  @override
  String get renameEventTypeTitle => 'Rename Event Type';

  @override
  String get deleteEventTypeTitle => 'Delete Event Type?';

  @override
  String get noEventTypes => 'No event types. Add one above.';

  @override
  String deleteEntryConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get categoryTagsTitle => 'Category Tags';

  @override
  String get resetToDefaultTagsTooltip => 'Reset to defaults';

  @override
  String get addTagTooltip => 'Add tag';

  @override
  String get noTagsYet => 'No tags yet. Tap + to add one.';

  @override
  String get tagsWeightHelp =>
      'Tags control the priority score. Higher weight = higher priority in the daily view. Drag to reorder.';

  @override
  String get resetToDefaultsTitle => 'Reset to defaults?';

  @override
  String get resetToDefaultsContent =>
      'This will restore the original 5 tags and weights. Any custom tags you added will be lost.';

  @override
  String get deleteTagTitle => 'Delete tag?';

  @override
  String deleteTagContent(String name) {
    return 'Remove \"$name\"? Friends already tagged with it keep the tag label, but it will score as the default weight.';
  }

  @override
  String get addTagTitle => 'Add tag';

  @override
  String get editTagTitle => 'Edit tag';

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get tagNamePlaceholder => 'e.g. Family';

  @override
  String get weightLabel => 'Weight';

  @override
  String get weightPlaceholder => 'e.g. 2.5';

  @override
  String get weightHelperText => 'Positive number — higher = more priority';

  @override
  String weightValueLabel(String value) {
    return 'Weight: $value';
  }

  @override
  String dragToReorder(String name) {
    return 'Drag to reorder $name';
  }

  @override
  String editItemSemantics(String name) {
    return 'Edit $name';
  }

  @override
  String deleteItemSemantics(String name) {
    return 'Delete $name';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get backupSectionTitle => 'Backup & Restore';

  @override
  String get backupPassphraseNote =>
      'Your passphrase encrypts your backup. It is never stored. If you lose it, your backup cannot be recovered.';

  @override
  String get exportBackupLabel => 'Export backup';

  @override
  String get importBackupLabel => 'Import backup';

  @override
  String get resetBackupSettingsLabel => 'Reset backup settings';

  @override
  String get exportBackupSemantics => 'Export encrypted backup';

  @override
  String get importBackupSemantics => 'Import encrypted backup from file';

  @override
  String get resetEncryptionKeyTitle => 'Reset encryption key';

  @override
  String get resetEncryptionKeyContent =>
      'This will generate a new encryption key for this device and re-encrypt all your data. Your existing backup files are NOT affected — they carry their own backup passphrase.';

  @override
  String get displaySectionTitle => 'Display';

  @override
  String get compactViewLabel => 'Compact view';

  @override
  String get compactViewSubtitle => 'Show more friends on screen at once';

  @override
  String get compactViewOn => 'Compact view, on';

  @override
  String get compactViewOff => 'Compact view, off';

  @override
  String get darkModeLabel => 'Dark mode';

  @override
  String get fontSizeLabel => 'Font size';

  @override
  String get iconSizeLabel => 'Icon size';

  @override
  String get languageLabel => 'Language';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Normal';

  @override
  String get sizeLarge => 'Large';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';

  @override
  String get categoryTagsSectionTitle => 'Category Tags';

  @override
  String get manageCategoryTagsLabel => 'Manage Category Tags';

  @override
  String get editNamesWeightsSubtitle => 'Edit names and priority weights';

  @override
  String get eventTypesSectionTitle => 'Event Types';

  @override
  String get manageEventTypesLabel => 'Manage Event Types';

  @override
  String get syncSectionTitle => 'Sync & Backup';

  @override
  String get syncComingSoon => 'Coming in Phase 2';

  @override
  String get syncSemantics =>
      'Sync & Backup — Coming in Phase 2, not yet available';

  @override
  String get passphraseLabel => 'Passphrase';

  @override
  String get confirmPassphraseLabel => 'Confirm passphrase';

  @override
  String get showPassphrase => 'Show passphrase';

  @override
  String get hidePassphrase => 'Hide passphrase';

  @override
  String get exportPassphraseHint =>
      'Choose a passphrase to protect your backup. Write it down somewhere safe — it cannot be recovered.';

  @override
  String get importPassphraseHint =>
      'Enter the passphrase you used when creating this backup.';

  @override
  String get dailyTitle => 'Daily';

  @override
  String get switchToExpandedView => 'Switch to expanded view';

  @override
  String get switchToCompactView => 'Switch to compact view';

  @override
  String get expandedViewTooltip => 'Expanded view';

  @override
  String get compactViewTooltip => 'Compact view';

  @override
  String get nothingToday => 'Nothing to do today 🎉\nAll caught up!';

  @override
  String get backupRestoredSuccess => 'Backup restored successfully.';

  @override
  String backupSavedTo(String path) {
    return 'Backup saved to:\n$path';
  }

  @override
  String get backupSettingsResetSuccess => 'Backup settings have been reset.';

  @override
  String get resetExportFailed => 'Export failed. Please try again.';

  @override
  String get importFailed =>
      'Import failed. Please check your passphrase and file.';

  @override
  String get resetFailed => 'Reset failed. Please try again.';

  @override
  String get demoLabel => 'Demo';

  @override
  String get importantLabel => 'Important';

  @override
  String get urgentLabel => 'Urgent';

  @override
  String get tagsSection => 'Tags';

  @override
  String get noTags => 'No tags';

  @override
  String get mobileSection => 'Mobile';

  @override
  String get concernFlagActive => 'Concern flag is active';

  @override
  String get noEventsYet => 'No events yet. Tap + to add one.';

  @override
  String get couldNotLoadEvents => 'Could not load events.';

  @override
  String get couldNotLoadHistory => 'Could not load history.';

  @override
  String get markDoneAdvance => 'Mark done (advance)';

  @override
  String get markAsDone => 'Mark as done';

  @override
  String get typeLabel => 'Type';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String get demoFriendDescription =>
      'This is a demo friend. Add a real contact to get started — Sophie will be removed automatically.';

  @override
  String get feedbackSectionTitle => 'Feedback';

  @override
  String get feedbackEmailLabel => 'Send us your suggestions';

  @override
  String get friendNotFound => 'Friend not found.';

  @override
  String deleteFriendConfirmContent(String name) {
    return 'Delete \"$name\"? All contact history will be permanently removed and cannot be undone.';
  }

  @override
  String get clearConcernBody =>
      'Remove the concern flag and its note for this friend?';

  @override
  String deleteEventConfirmContent(String type, String date) {
    return 'Delete \"$type\" on $date? This action cannot be undone.';
  }

  @override
  String eventDoneLabel(String date) {
    return 'Done $date';
  }

  @override
  String get eventActionsTooltip => 'Event actions';

  @override
  String get tierNormal => 'Normal';

  @override
  String get surfacingNoEvent => 'No upcoming event';

  @override
  String surfacingOverdueByDays(int days) {
    return 'Overdue by $days days';
  }

  @override
  String get surfacingOverdueByOneDay => 'Overdue by 1 day';

  @override
  String get surfacingDueToday => 'Due today';

  @override
  String get surfacingDueTomorrow => 'Due tomorrow';

  @override
  String surfacingDueInDays(int days) {
    return 'Due in $days days';
  }

  @override
  String get couldNotLoadDailyView => 'Could not load daily view.';

  @override
  String get concernActiveSemantics => 'Concern active';

  @override
  String get lastNoteLabel => 'Last note';

  @override
  String get contactLoggedFeedback => 'Contact enregistré — bien joué 💛';

  @override
  String cadenceEveryNDays(int days) {
    return 'Every $days days';
  }

  @override
  String get heartBriefingTitle => 'Heart Briefing';

  @override
  String get noFriendsWithTagsYet => 'No friends with these tags yet.';

  @override
  String get searchFriendsByName => 'Search friends by name';

  @override
  String noFriendNamedSearch(String query) {
    return 'No friend named \"$query\" in your circle.';
  }

  @override
  String filterByTagSemantics(String tag, String state) {
    return 'Filter by $tag, $state';
  }

  @override
  String get chipStateSelected => 'selected';

  @override
  String get chipStateNotSelected => 'not selected';

  @override
  String get concernCadenceSectionTitle => 'Concern Follow-up';

  @override
  String get concernCadenceLabel => 'Follow-up cadence';

  @override
  String concernCadenceEveryNDays(int days) {
    return 'Every $days days';
  }

  @override
  String get concernCadenceDefault => 'default';

  @override
  String get concernCadenceAppliesNote =>
      'Applies to new concern flags — existing cadences are not changed.';

  @override
  String concernCadenceSemantics(int days, String state) {
    return 'Concern cadence: Every $days days, $state';
  }

  @override
  String get draftResumingBanner => 'Resuming your draft';

  @override
  String lastContactLabel(String date) {
    return 'Last contact: $date';
  }

  @override
  String get draftDiscard => 'Discard';

  @override
  String get modelDownloadTitle => 'AI Model Setup';

  @override
  String get modelDownloadStorageRequired =>
      'This feature requires downloading an AI model (~2 GB). Make sure you have enough storage space.';

  @override
  String get modelDownloadButton => 'Download model';

  @override
  String get modelDownloadCancelButton => 'Cancel';

  @override
  String get modelDownloadRetryButton => 'Retry';

  @override
  String modelDownloadProgressSemantics(int percent) {
    return 'Downloading AI model, $percent percent complete';
  }

  @override
  String modelDownloadErrorMessage(String error) {
    return 'Download failed: $error';
  }

  @override
  String get modelDownloadComplete =>
      'AI model ready — you can now use smart suggestions.';

  @override
  String get modelDownloadOkButton => 'Done';

  @override
  String get statusFilterTooltip => 'Filter by status';

  @override
  String statusFilterActiveSemantics(int count) {
    return 'Filter by status, $count active';
  }

  @override
  String get statusFilterSheetTitle => 'Filter by status';

  @override
  String get statusFilterActiveConcern => 'Active concern';

  @override
  String get statusFilterOverdueEvent => 'Overdue event';

  @override
  String get statusFilterNoRecentContact => 'No recent contact';

  @override
  String get statusFilterClearAll => 'Clear all filters';

  @override
  String get noFriendsMatchingStatus => 'No friends match the active filters.';

  // ---------------------------------------------------------------------------
  // Story 10.2 — DraftMessageSheet l10n
  // ---------------------------------------------------------------------------

  @override
  String get suggestMessageAction => 'Suggest message';

  @override
  String get draftMessageSheetTitle => 'Message suggestions';

  @override
  String get draftMessageGenerating => 'Generating...';

  @override
  String draftMessageEventHeader(String name, String eventContext) {
    return 'For $name — $eventContext';
  }

  @override
  String draftMessageVariantSemantics(int n, String preview) {
    return 'Message option $n: $preview';
  }

  @override
  String get draftMessageChannelWhatsApp => 'WhatsApp';

  @override
  String get draftMessageChannelSms => 'SMS';

  @override
  String get draftMessageChannelWhatsAppSemantics => 'Send via WhatsApp';

  @override
  String get draftMessageChannelSmsSemantics => 'Send via SMS';

  @override
  String get draftMessageSendViaWhatsApp => 'Copy & Send via WhatsApp';

  @override
  String get draftMessageSendViaSms => 'Copy & Send via SMS';

  @override
  String get draftMessageDiscard => 'Discard';

  @override
  String get draftMessageDiscardSemantics => 'Discard suggestion';

  @override
  String get draftMessageError =>
      "Couldn't generate suggestions right now. You can write your own message below.";

  @override
  String get draftMessageGenerateMore => 'Generate more';

  @override
  String draftMessageSendSemantics(String channel) {
    return 'Copy and send via $channel';
  }
}
