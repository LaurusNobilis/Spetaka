import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Spetaka'**
  String get appTitle;

  /// Bottom nav / AppBar label for daily view
  ///
  /// In en, this message translates to:
  /// **'Suggested actions'**
  String get navDaily;

  /// Bottom nav / AppBar label for friends list
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// AppBar / tooltip label for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Semantics label for the 2-dot page indicator in the Daily/Friends swipe shell
  ///
  /// In en, this message translates to:
  /// **'Current page: {page}. Swipe left or right to switch pages.'**
  String shellPageIndicatorSemantics(String page);

  /// Generic add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// Generic save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Generic delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Generic edit button label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Generic reset button label
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// Generic back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Generic continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Generic rename button label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// Generic flag button label
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get actionFlag;

  /// Generic clear button label
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// Generic confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// Error when save fails
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get couldNotSave;

  /// Friends list screen title
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTitle;

  /// FAB tooltip on friends list
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriendTooltip;

  /// Empty state button on friends list
  ///
  /// In en, this message translates to:
  /// **'Add first friend'**
  String get addFirstFriend;

  /// Headline shown when friends list is empty
  ///
  /// In en, this message translates to:
  /// **'No friends yet.'**
  String get emptyFriendsTitle;

  /// Supporting text shown when friends list is empty
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first friend.'**
  String get emptyFriendsSubtitle;

  /// AppBar title when creating a friend
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get addFriendTitle;

  /// AppBar title when editing a friend
  ///
  /// In en, this message translates to:
  /// **'Edit Friend'**
  String get editFriendTitle;

  /// Choice screen headline on friend form
  ///
  /// In en, this message translates to:
  /// **'How would you like to add this friend?'**
  String get howToAddFriend;

  /// Button to import from phone contacts
  ///
  /// In en, this message translates to:
  /// **'Import from contacts'**
  String get importFromContacts;

  /// Button to enter friend data manually
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// Section heading on manual form
  ///
  /// In en, this message translates to:
  /// **'Enter details'**
  String get enterDetails;

  /// Label for the tags section on friend form
  ///
  /// In en, this message translates to:
  /// **'Category tags'**
  String get categoryTagsLabel;

  /// TextField label for friend name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// TextField label for mobile number
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileLabel;

  /// Hint text for mobile field
  ///
  /// In en, this message translates to:
  /// **'e.g. 06 12 34 56 78'**
  String get mobilePlaceholder;

  /// TextField label for notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Hint text for notes field
  ///
  /// In en, this message translates to:
  /// **'Optional context notes…'**
  String get optionalContextNotes;

  /// AppBar title on friend detail screen
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friendTitle;

  /// Link to full friend detail from daily card
  ///
  /// In en, this message translates to:
  /// **'Full details'**
  String get fullDetails;

  /// Semantics label for full details link
  ///
  /// In en, this message translates to:
  /// **'Full details for {name}'**
  String fullDetailsSemantics(String name);

  /// Dialog title when deleting a friend
  ///
  /// In en, this message translates to:
  /// **'Delete friend?'**
  String get deleteFriendTitle;

  /// Action label / dialog title to flag a concern
  ///
  /// In en, this message translates to:
  /// **'Flag concern'**
  String get flagConcernTitle;

  /// Dialog title to clear a concern
  ///
  /// In en, this message translates to:
  /// **'Clear concern?'**
  String get clearConcernTitle;

  /// Button to clear concern
  ///
  /// In en, this message translates to:
  /// **'Clear concern'**
  String get clearConcernAction;

  /// Label displayed when concern is active
  ///
  /// In en, this message translates to:
  /// **'Concern'**
  String get concernLabel;

  /// Empty-state summary shown when no concern is active for a friend
  ///
  /// In en, this message translates to:
  /// **'No concern flagged.'**
  String get concernInactiveSummary;

  /// Tooltip shown on the concern warning icon
  ///
  /// In en, this message translates to:
  /// **'Concern flagged'**
  String get concernFlaggedTooltip;

  /// Suffix appended to friend tile semantics label when concern is active
  ///
  /// In en, this message translates to:
  /// **'concern flagged'**
  String get concernFlaggedSemanticsSuffix;

  /// Section heading for events on friend card
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsLabel;

  /// Button to add an event
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEventAction;

  /// Section heading for contact history
  ///
  /// In en, this message translates to:
  /// **'Contact History'**
  String get contactHistorySection;

  /// Empty state for contact history
  ///
  /// In en, this message translates to:
  /// **'No contact history yet.'**
  String get noContactHistory;

  /// Tooltip/action to log a contact
  ///
  /// In en, this message translates to:
  /// **'Log contact'**
  String get logContactTitle;

  /// Title of the acquittement sheet
  ///
  /// In en, this message translates to:
  /// **'Confirm contact'**
  String get confirmContactLog;

  /// Hint text in the acquittement note field (kept in French)
  ///
  /// In en, this message translates to:
  /// **'Comment ça s\'est passé ?'**
  String get howDidItGo;

  /// Action button label to call
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// Action button label for SMS
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get smsAction;

  /// Action button label for WhatsApp
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappAction;

  /// Tooltip text for contact action buttons
  ///
  /// In en, this message translates to:
  /// **'Saves the contact to history'**
  String get savesContactHistory;

  /// AppBar title for add event screen
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEventTitle;

  /// AppBar title for edit event screen
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEventTitle;

  /// Message shown when an event id is missing/invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid event id.'**
  String get invalidEventIdMessage;

  /// Message shown when loading an event fails
  ///
  /// In en, this message translates to:
  /// **'Could not load event.'**
  String get couldNotLoadEventMessage;

  /// Message shown when an event does not exist
  ///
  /// In en, this message translates to:
  /// **'Event not found.'**
  String get eventNotFoundMessage;

  /// Dialog title to delete an event
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventTitle;

  /// Section heading in add/edit event
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventTypeLabel;

  /// Section heading for date picker
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Switch label for recurring events
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringLabel;

  /// Subtitle for recurring switch
  ///
  /// In en, this message translates to:
  /// **'Set a repeating check-in cadence'**
  String get checkInCadence;

  /// Section heading for comment field in events
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// Hint text for comment field in events
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get addNoteHint;

  /// Hint text for note field in acquittement
  ///
  /// In en, this message translates to:
  /// **'Optional note…'**
  String get optionalNoteHint;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get everyWeek;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get every2Weeks;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every 3 weeks'**
  String get every3Weeks;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every 2 months'**
  String get every2Months;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get every3Months;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every 6 months'**
  String get every6Months;

  /// Cadence label
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get everyYear;

  /// Error message in event type selector
  ///
  /// In en, this message translates to:
  /// **'Could not load event types.'**
  String get couldNotLoadEventTypes;

  /// Fallback message shown when a provided name is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid name.'**
  String get invalidNameFallback;

  /// Message shown when deleting an event type that is used by existing events
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{# event uses this type — it will keep its current label.} other{# events use this type — they will keep their current label.}}'**
  String eventTypeInUseNotice(int count);

  /// AppBar title for manage event types screen
  ///
  /// In en, this message translates to:
  /// **'Event Types'**
  String get eventTypesTitle;

  /// Hint text in add event type field
  ///
  /// In en, this message translates to:
  /// **'New event type…'**
  String get newEventTypePlaceholder;

  /// Tooltip for add event type button
  ///
  /// In en, this message translates to:
  /// **'Add type'**
  String get addTypeTooltip;

  /// Dialog title to rename an event type
  ///
  /// In en, this message translates to:
  /// **'Rename Event Type'**
  String get renameEventTypeTitle;

  /// Dialog title to delete an event type
  ///
  /// In en, this message translates to:
  /// **'Delete Event Type?'**
  String get deleteEventTypeTitle;

  /// Empty state for event types list
  ///
  /// In en, this message translates to:
  /// **'No event types. Add one above.'**
  String get noEventTypes;

  /// Dialog content when deleting a single entry
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteEntryConfirm(String name);

  /// AppBar title for manage category tags screen
  ///
  /// In en, this message translates to:
  /// **'Category Tags'**
  String get categoryTagsTitle;

  /// Tooltip for reset tags button
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaultTagsTooltip;

  /// FAB tooltip on manage category tags
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTagTooltip;

  /// Empty state on manage category tags
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Tap + to add one.'**
  String get noTagsYet;

  /// Explanatory text on manage category tags
  ///
  /// In en, this message translates to:
  /// **'Tags control the priority score. Higher weight = higher priority in the daily view. Drag to reorder.'**
  String get tagsWeightHelp;

  /// Dialog title to reset tags
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults?'**
  String get resetToDefaultsTitle;

  /// Dialog content to reset tags
  ///
  /// In en, this message translates to:
  /// **'This will restore the original 5 tags and weights. Any custom tags you added will be lost.'**
  String get resetToDefaultsContent;

  /// Dialog title to delete a tag
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get deleteTagTitle;

  /// Dialog content when deleting a tag
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? Friends already tagged with it keep the tag label, but it will score as the default weight.'**
  String deleteTagContent(String name);

  /// Dialog title for adding a new tag
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTagTitle;

  /// Dialog title for editing a tag
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get editTagTitle;

  /// TextField label for tag name
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagNameLabel;

  /// Hint text for tag name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Family'**
  String get tagNamePlaceholder;

  /// TextField label for tag weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// Hint text for weight field
  ///
  /// In en, this message translates to:
  /// **'e.g. 2.5'**
  String get weightPlaceholder;

  /// Helper text for weight field
  ///
  /// In en, this message translates to:
  /// **'Positive number — higher = more priority'**
  String get weightHelperText;

  /// Weight display in tag tile subtitle
  ///
  /// In en, this message translates to:
  /// **'Weight: {value}'**
  String weightValueLabel(String value);

  /// Semantics label for drag handle
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder {name}'**
  String dragToReorder(String name);

  /// Semantics label for edit button
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editItemSemantics(String name);

  /// Semantics label for delete button
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String deleteItemSemantics(String name);

  /// AppBar title for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Section heading in settings
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupSectionTitle;

  /// Important note about backup passphrase
  ///
  /// In en, this message translates to:
  /// **'Your passphrase encrypts your backup. It is never stored. If you lose it, your backup cannot be recovered.'**
  String get backupPassphraseNote;

  /// Action label for export backup
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackupLabel;

  /// Action label for import backup
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackupLabel;

  /// Action label for reset backup settings
  ///
  /// In en, this message translates to:
  /// **'Reset backup settings'**
  String get resetBackupSettingsLabel;

  /// Semantics label for export
  ///
  /// In en, this message translates to:
  /// **'Export encrypted backup'**
  String get exportBackupSemantics;

  /// Semantics label for import
  ///
  /// In en, this message translates to:
  /// **'Import encrypted backup from file'**
  String get importBackupSemantics;

  /// Dialog title for reset encryption
  ///
  /// In en, this message translates to:
  /// **'Reset encryption key'**
  String get resetEncryptionKeyTitle;

  /// Dialog content for reset encryption
  ///
  /// In en, this message translates to:
  /// **'This will generate a new encryption key for this device and re-encrypt all your data. Your existing backup files are NOT affected — they carry their own backup passphrase.'**
  String get resetEncryptionKeyContent;

  /// Section heading in settings
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySectionTitle;

  /// Switch label for compact view
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get compactViewLabel;

  /// Subtitle for compact view switch
  ///
  /// In en, this message translates to:
  /// **'Show more friends on screen at once'**
  String get compactViewSubtitle;

  /// Semantics label when compact view is on
  ///
  /// In en, this message translates to:
  /// **'Compact view, on'**
  String get compactViewOn;

  /// Semantics label when compact view is off
  ///
  /// In en, this message translates to:
  /// **'Compact view, off'**
  String get compactViewOff;

  /// Display preference label for the dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkModeLabel;

  /// Display preference label
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSizeLabel;

  /// Display preference label
  ///
  /// In en, this message translates to:
  /// **'Icon size'**
  String get iconSizeLabel;

  /// Language selector label in settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Size option label
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// Size option label
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get sizeMedium;

  /// Size option label
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// French language option
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Section heading in settings
  ///
  /// In en, this message translates to:
  /// **'Category Tags'**
  String get categoryTagsSectionTitle;

  /// List tile label in settings
  ///
  /// In en, this message translates to:
  /// **'Manage Category Tags'**
  String get manageCategoryTagsLabel;

  /// Subtitle for manage category tags tile
  ///
  /// In en, this message translates to:
  /// **'Edit names and priority weights'**
  String get editNamesWeightsSubtitle;

  /// Section heading in settings
  ///
  /// In en, this message translates to:
  /// **'Event Types'**
  String get eventTypesSectionTitle;

  /// List tile label in settings
  ///
  /// In en, this message translates to:
  /// **'Manage Event Types'**
  String get manageEventTypesLabel;

  /// Section heading in settings
  ///
  /// In en, this message translates to:
  /// **'Sync & Backup'**
  String get syncSectionTitle;

  /// Subtitle for the sync placeholder tile
  ///
  /// In en, this message translates to:
  /// **'Coming in Phase 2'**
  String get syncComingSoon;

  /// Semantics label for sync tile
  ///
  /// In en, this message translates to:
  /// **'Sync & Backup — Coming in Phase 2, not yet available'**
  String get syncSemantics;

  /// TextField label for passphrase
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get passphraseLabel;

  /// TextField label for passphrase confirmation
  ///
  /// In en, this message translates to:
  /// **'Confirm passphrase'**
  String get confirmPassphraseLabel;

  /// Tooltip to show passphrase
  ///
  /// In en, this message translates to:
  /// **'Show passphrase'**
  String get showPassphrase;

  /// Tooltip to hide passphrase
  ///
  /// In en, this message translates to:
  /// **'Hide passphrase'**
  String get hidePassphrase;

  /// Hint in export passphrase dialog
  ///
  /// In en, this message translates to:
  /// **'Choose a passphrase to protect your backup. Write it down somewhere safe — it cannot be recovered.'**
  String get exportPassphraseHint;

  /// Hint in import passphrase dialog
  ///
  /// In en, this message translates to:
  /// **'Enter the passphrase you used when creating this backup.'**
  String get importPassphraseHint;

  /// AppBar title for daily view
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyTitle;

  /// Semantics label for density toggle
  ///
  /// In en, this message translates to:
  /// **'Switch to expanded view'**
  String get switchToExpandedView;

  /// Semantics label for density toggle
  ///
  /// In en, this message translates to:
  /// **'Switch to compact view'**
  String get switchToCompactView;

  /// Tooltip for density toggle
  ///
  /// In en, this message translates to:
  /// **'Expanded view'**
  String get expandedViewTooltip;

  /// Tooltip for density toggle
  ///
  /// In en, this message translates to:
  /// **'Compact view'**
  String get compactViewTooltip;

  /// Empty state message on daily view
  ///
  /// In en, this message translates to:
  /// **'Nothing to do today 🎉\nAll caught up!'**
  String get nothingToday;

  /// Snackbar after successful import
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get backupRestoredSuccess;

  /// Snackbar after successful export
  ///
  /// In en, this message translates to:
  /// **'Backup saved to:\n{path}'**
  String backupSavedTo(String path);

  /// Snackbar after reset
  ///
  /// In en, this message translates to:
  /// **'Backup settings have been reset.'**
  String get backupSettingsResetSuccess;

  /// Snackbar when export fails
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get resetExportFailed;

  /// Snackbar when import fails
  ///
  /// In en, this message translates to:
  /// **'Import failed. Please check your passphrase and file.'**
  String get importFailed;

  /// Snackbar when reset fails
  ///
  /// In en, this message translates to:
  /// **'Reset failed. Please try again.'**
  String get resetFailed;

  /// Label for demo friend entries
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demoLabel;

  /// Priority level label
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get importantLabel;

  /// Priority level label
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentLabel;

  /// Section heading for tags on friend card
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsSection;

  /// Empty state when friend has no tags
  ///
  /// In en, this message translates to:
  /// **'No tags'**
  String get noTags;

  /// Section heading for mobile on friend card
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileSection;

  /// Message when concern flag is active
  ///
  /// In en, this message translates to:
  /// **'Concern flag is active'**
  String get concernFlagActive;

  /// Empty state for events list on friend card
  ///
  /// In en, this message translates to:
  /// **'No events yet. Tap + to add one.'**
  String get noEventsYet;

  /// Error when events fail to load
  ///
  /// In en, this message translates to:
  /// **'Could not load events.'**
  String get couldNotLoadEvents;

  /// Error when contact history fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load history.'**
  String get couldNotLoadHistory;

  /// Popup menu item to acknowledge and advance recurring event
  ///
  /// In en, this message translates to:
  /// **'Mark done (advance)'**
  String get markDoneAdvance;

  /// Popup menu item to acknowledge a one-time event
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markAsDone;

  /// Label for the type selector in acquittement sheet
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// Label for the optional note field in acquittement sheet
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// Info banner on the demo friend card
  ///
  /// In en, this message translates to:
  /// **'This is a demo friend. Add a real contact to get started — Sophie will be removed automatically.'**
  String get demoFriendDescription;

  /// Settings section title for feedback / suggestions
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackSectionTitle;

  /// ListTile label to open feedback email
  ///
  /// In en, this message translates to:
  /// **'Send us your suggestions'**
  String get feedbackEmailLabel;

  /// Error when friend record cannot be found
  ///
  /// In en, this message translates to:
  /// **'Friend not found.'**
  String get friendNotFound;

  /// Body of the delete-friend confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? All contact history will be permanently removed and cannot be undone.'**
  String deleteFriendConfirmContent(String name);

  /// Body of the clear-concern confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove the concern flag and its note for this friend?'**
  String get clearConcernBody;

  /// Body of the delete-event confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete \"{type}\" on {date}? This action cannot be undone.'**
  String deleteEventConfirmContent(String type, String date);

  /// Label shown when an event is acknowledged, with the date
  ///
  /// In en, this message translates to:
  /// **'Done {date}'**
  String eventDoneLabel(String date);

  /// Tooltip for the event popup menu
  ///
  /// In en, this message translates to:
  /// **'Event actions'**
  String get eventActionsTooltip;

  /// Urgency tier label: normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get tierNormal;

  /// Surfacing reason when friend has no scheduled event
  ///
  /// In en, this message translates to:
  /// **'No upcoming event'**
  String get surfacingNoEvent;

  /// Surfacing reason when event is overdue by multiple days
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days'**
  String surfacingOverdueByDays(int days);

  /// Surfacing reason when event is overdue by exactly 1 day
  ///
  /// In en, this message translates to:
  /// **'Overdue by 1 day'**
  String get surfacingOverdueByOneDay;

  /// Surfacing reason when event is due today
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get surfacingDueToday;

  /// Surfacing reason when event is due tomorrow
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get surfacingDueTomorrow;

  /// Surfacing reason when event is due in multiple days
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String surfacingDueInDays(int days);

  /// Error message when daily view fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load daily view.'**
  String get couldNotLoadDailyView;

  /// Accessibility label when a concern flag is active
  ///
  /// In en, this message translates to:
  /// **'Concern active'**
  String get concernActiveSemantics;

  /// Label above the last note preview in expanded card
  ///
  /// In en, this message translates to:
  /// **'Last note'**
  String get lastNoteLabel;

  /// Snackbar shown after a contact is successfully logged
  ///
  /// In en, this message translates to:
  /// **'Contact enregistré — bien joué 💛'**
  String get contactLoggedFeedback;

  /// Cadence label fallback when the exact interval has no named label
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String cadenceEveryNDays(int days);

  /// Title of the heart briefing section in the daily view
  ///
  /// In en, this message translates to:
  /// **'Heart Briefing'**
  String get heartBriefingTitle;

  /// Empty state when tag filter yields zero results — Story 8.1 AC4
  ///
  /// In en, this message translates to:
  /// **'No friends with these tags yet.'**
  String get noFriendsWithTagsYet;

  /// TalkBack label and hint for friend list search field — Story 8.2 AC6
  ///
  /// In en, this message translates to:
  /// **'Search friends by name'**
  String get searchFriendsByName;

  /// Empty state when friend search yields no results — Story 8.2 AC4
  ///
  /// In en, this message translates to:
  /// **'No friend named \"{query}\" in your circle.'**
  String noFriendNamedSearch(String query);

  /// TalkBack content description for a tag filter chip — Story 8.1 AC7
  ///
  /// In en, this message translates to:
  /// **'Filter by {tag}, {state}'**
  String filterByTagSemantics(String tag, String state);

  /// Chip state for screen readers when a filter chip is selected
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get chipStateSelected;

  /// Chip state for screen readers when a filter chip is not selected
  ///
  /// In en, this message translates to:
  /// **'not selected'**
  String get chipStateNotSelected;

  /// Section heading for concern cadence settings — Story 9.2 AC1
  ///
  /// In en, this message translates to:
  /// **'Concern Follow-up'**
  String get concernCadenceSectionTitle;

  /// Label for the concern cadence setting tile — Story 9.2 AC1
  ///
  /// In en, this message translates to:
  /// **'Follow-up cadence'**
  String get concernCadenceLabel;

  /// Human-readable label for cadence interval — Story 9.2 AC1
  ///
  /// In en, this message translates to:
  /// **'Every {days} days'**
  String concernCadenceEveryNDays(int days);

  /// Suffix shown next to the default cadence option — Story 9.2 AC1
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get concernCadenceDefault;

  /// Subtitle note clarifying cadence change scope — Story 9.2 AC3
  ///
  /// In en, this message translates to:
  /// **'Applies to new concern flags — existing cadences are not changed.'**
  String get concernCadenceAppliesNote;

  /// TalkBack content description for cadence option — Story 9.2 AC5
  ///
  /// In en, this message translates to:
  /// **'Concern cadence: Every {days} days, {state}'**
  String concernCadenceSemantics(int days, String state);

  /// Banner message when a saved draft is restored — Story 10.4 AC1
  ///
  /// In en, this message translates to:
  /// **'Resuming your draft'**
  String get draftResumingBanner;

  /// Secondary label showing the most recent contact date for a friend
  ///
  /// In en, this message translates to:
  /// **'Last contact: {date}'**
  String lastContactLabel(String date);

  /// Action button on draft banner to discard the draft — Story 10.4 AC4
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get draftDiscard;

  /// Title of the model download screen — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'AI Model Setup'**
  String get modelDownloadTitle;

  /// Storage requirement notice on model download screen — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'This feature requires downloading an AI model (~2 GB). Make sure you have enough storage space.'**
  String get modelDownloadStorageRequired;

  /// Button to start AI model download — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'Download model'**
  String get modelDownloadButton;

  /// Button to cancel in-progress AI model download — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get modelDownloadCancelButton;

  /// Button to retry AI model download after error — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get modelDownloadRetryButton;

  /// TalkBack label for download progress — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'Downloading AI model, {percent} percent complete'**
  String modelDownloadProgressSemantics(int percent);

  /// Error message when AI model download fails — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String modelDownloadErrorMessage(String error);

  /// Success message after AI model download completes — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'AI model ready — you can now use smart suggestions.'**
  String get modelDownloadComplete;

  /// Button to dismiss the AI model ready screen — Story 10.1 AC5
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get modelDownloadOkButton;

  /// Section heading in ModelDownloadScreen for token entry — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'HuggingFace Access Token'**
  String get hfTokenSectionTitle;

  /// Explanation text shown when user needs to enter their HF token — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'To download the AI model, you need a free HuggingFace account token. Visit huggingface.co/settings/tokens to generate one (read-only access is sufficient).'**
  String get hfTokenExplainer;

  /// Label for the HuggingFace token text field — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'HuggingFace token'**
  String get hfTokenFieldLabel;

  /// Button that saves the HF token and starts model download — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'Save & Download'**
  String get hfTokenSaveAndDownload;

  /// Validation error when token field is empty — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'Please enter your HuggingFace token before downloading.'**
  String get hfTokenErrorEmpty;

  /// Title of the "how to get a HF token" info dialog — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'How to get a HuggingFace token'**
  String get hfTokenHowToTitle;

  /// Step-by-step instructions inside the HF token info dialog — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'1. Go to huggingface.co and create a free account (or sign in).\n2. Click your avatar → Settings → Access Tokens.\n3. Click "New token", choose type Read, give it any name.\n4. Copy the token (starts with hf_…) and paste it here.'**
  String get hfTokenHowToSteps;

  /// Close button label for the HF token info dialog — p2-llm-hf-token
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get hfTokenHowToClose;

  /// Title of the model info card on the download screen — Story 10.1
  ///
  /// In en, this message translates to:
  /// **'Gemma 3n E2B — on-device AI model'**
  String get modelInfoTitle;

  /// Description in the model info card explaining why this model was chosen — Story 10.1
  ///
  /// In en, this message translates to:
  /// **'A lightweight 2-billion-parameter model by Google, optimised for mobile devices. It runs entirely on your phone — no internet connection required after download, no data leaves your device.'**
  String get modelInfoDescription;

  /// Label showing the approximate size of the model — Story 10.1
  ///
  /// In en, this message translates to:
  /// **'Size: ~2 GB (one-time download)'**
  String get modelInfoSize;

  /// Tooltip/label for the button that opens the model info dialog — Story 10.1
  ///
  /// In en, this message translates to:
  /// **'Model info'**
  String get modelInfoButtonTooltip;

  /// Tooltip for the status filter funnel icon in the friends list AppBar — Story 8.3 AC1
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get statusFilterTooltip;

  /// TalkBack label for the filter icon when one or more status filters are active — Story 8.3 AC3
  ///
  /// In en, this message translates to:
  /// **'Filter by status, {count} active'**
  String statusFilterActiveSemantics(int count);

  /// Title shown at the top of the status filter bottom sheet — Story 8.3 AC1
  ///
  /// In en, this message translates to:
  /// **'Filter by status'**
  String get statusFilterSheetTitle;

  /// Toggle label for isConcernActive filter in StatusFilterSheet — Story 8.3 AC1
  ///
  /// In en, this message translates to:
  /// **'Active concern'**
  String get statusFilterActiveConcern;

  /// Toggle label for overdue-event filter in StatusFilterSheet — Story 8.3 AC1
  ///
  /// In en, this message translates to:
  /// **'Overdue event'**
  String get statusFilterOverdueEvent;

  /// Toggle label for no-recent-contact filter in StatusFilterSheet — Story 8.3 AC1
  ///
  /// In en, this message translates to:
  /// **'No recent contact'**
  String get statusFilterNoRecentContact;

  /// Button to reset all status filters in StatusFilterSheet — Story 8.3 AC4
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get statusFilterClearAll;

  /// Empty state shown when status filters yield zero results — Story 8.3 AC2
  ///
  /// In en, this message translates to:
  /// **'No friends match the active filters.'**
  String get noFriendsMatchingStatus;

  /// Popup menu item label for 'Suggest message' action on event row — Story 10.2 AC1
  ///
  /// In en, this message translates to:
  /// **'Suggest message'**
  String get suggestMessageAction;

  /// Title of the DraftMessageSheet bottom sheet — Story 10.2 AC3
  ///
  /// In en, this message translates to:
  /// **'Message suggestions'**
  String get draftMessageSheetTitle;

  /// Loading body placeholder text in DraftMessageSheet — Story 10.2 AC1
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get draftMessageGenerating;

  /// Event context header in DraftMessageSheet — Story 10.2 AC3
  ///
  /// In en, this message translates to:
  /// **'For {name} — {eventContext}'**
  String draftMessageEventHeader(String name, String eventContext);

  /// Semantics label for variant cards — Story 10.2 AC8
  ///
  /// In en, this message translates to:
  /// **'Message option {n}: {preview}'**
  String draftMessageVariantSemantics(int n, String preview);

  /// Channel chip label for WhatsApp — Story 10.2 AC3
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get draftMessageChannelWhatsApp;

  /// Channel chip label for SMS — Story 10.2 AC3
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get draftMessageChannelSms;

  /// Semantics label for the WhatsApp channel chip — Story 10.2 AC8
  ///
  /// In en, this message translates to:
  /// **'Send via WhatsApp'**
  String get draftMessageChannelWhatsAppSemantics;

  /// Semantics label for the SMS channel chip — Story 10.2 AC8
  ///
  /// In en, this message translates to:
  /// **'Send via SMS'**
  String get draftMessageChannelSmsSemantics;

  /// Confirm button label when WhatsApp channel is selected — Story 10.2 AC4
  ///
  /// In en, this message translates to:
  /// **'Copy & Send via WhatsApp'**
  String get draftMessageSendViaWhatsApp;

  /// Confirm button label when SMS channel is selected — Story 10.2 AC4
  ///
  /// In en, this message translates to:
  /// **'Copy & Send via SMS'**
  String get draftMessageSendViaSms;

  /// Discard button label — Story 10.2 AC5
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get draftMessageDiscard;

  /// Semantics label for discard button — Story 10.2 AC8
  ///
  /// In en, this message translates to:
  /// **'Discard suggestion'**
  String get draftMessageDiscardSemantics;

  /// Error state message when no suggestions were generated — Story 10.2 AC6
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate suggestions right now. You can write your own message below.'**
  String get draftMessageError;

  /// 'Generate more' button in DraftMessageSheet when < 3 variants — Story 10.2 AC2
  ///
  /// In en, this message translates to:
  /// **'Generate more'**
  String get draftMessageGenerateMore;

  /// Semantics label for the confirm / send button — Story 10.2 AC8
  ///
  /// In en, this message translates to:
  /// **'Copy and send via {channel}'**
  String draftMessageSendSemantics(String channel);

  /// Label for the AI message suggestion button in daily view action row — Story 10.5 AC3
  ///
  /// In en, this message translates to:
  /// **'Message AI'**
  String get suggestMessageDailyAction;

  /// Accessibility semantics for AI message button in daily view — Story 10.5 AC7
  ///
  /// In en, this message translates to:
  /// **'Compose an AI-suggested message for {name}'**
  String suggestMessageDailySemantics(String name);
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
