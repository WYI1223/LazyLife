import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN')
  ];

  /// No description provided for @lazyNoteWorkbenchTitle.
  ///
  /// In en, this message translates to:
  /// **'LazyNote Workbench'**
  String get lazyNoteWorkbenchTitle;

  /// No description provided for @workbenchSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workbenchSectionNotes;

  /// No description provided for @workbenchSectionNotesWithCount.
  ///
  /// In en, this message translates to:
  /// **'Notes ({count})'**
  String workbenchSectionNotesWithCount(int count);

  /// No description provided for @workbenchSectionTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get workbenchSectionTasks;

  /// No description provided for @workbenchSectionCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get workbenchSectionCalendar;

  /// No description provided for @workbenchSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get workbenchSectionSettings;

  /// No description provided for @workbenchSectionRustDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Rust Diagnostics'**
  String get workbenchSectionRustDiagnostics;

  /// No description provided for @workbenchHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Workbench Home'**
  String get workbenchHomeTitle;

  /// No description provided for @workbenchHomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Use Workbench to run Single Entry flow and diagnostics while feature UIs are landing.'**
  String get workbenchHomeDescription;

  /// No description provided for @singleEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Single Entry'**
  String get singleEntryTitle;

  /// No description provided for @openSingleEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Open Single Entry'**
  String get openSingleEntryButton;

  /// No description provided for @focusSingleEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Focus Single Entry'**
  String get focusSingleEntryButton;

  /// No description provided for @hideSingleEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Hide Single Entry'**
  String get hideSingleEntryButton;

  /// No description provided for @workbenchDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get workbenchDiagnosticsTitle;

  /// No description provided for @placeholderRoutesTitle.
  ///
  /// In en, this message translates to:
  /// **'Placeholder Routes'**
  String get placeholderRoutesTitle;

  /// No description provided for @backToWorkbenchButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Workbench'**
  String get backToWorkbenchButton;

  /// No description provided for @settingsCapabilityAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Extension capability audit (v0.2 baseline)'**
  String get settingsCapabilityAuditTitle;

  /// No description provided for @settingsCapabilityAuditDescription.
  ///
  /// In en, this message translates to:
  /// **'Runtime capability checks are deny-by-default. Undeclared capabilities are rejected at invocation time.'**
  String get settingsCapabilityAuditDescription;

  /// No description provided for @settingsRegisteredExtensions.
  ///
  /// In en, this message translates to:
  /// **'Registered Extensions'**
  String get settingsRegisteredExtensions;

  /// No description provided for @settingsCapabilityCatalog.
  ///
  /// In en, this message translates to:
  /// **'Capability Catalog'**
  String get settingsCapabilityCatalog;

  /// No description provided for @settingsNoRuntimePermissionsDeclared.
  ///
  /// In en, this message translates to:
  /// **'No runtime permissions declared (deny-by-default).'**
  String get settingsNoRuntimePermissionsDeclared;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch Workbench UI language immediately.'**
  String get settingsLanguageDescription;

  /// No description provided for @languageOptionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageOptionSystem;

  /// No description provided for @languageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageOptionEnglish;

  /// No description provided for @languageOptionChineseSimplified.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get languageOptionChineseSimplified;

  /// No description provided for @settingsLanguageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save language preference.'**
  String get settingsLanguageSaveFailed;

  /// No description provided for @loggingInitStatusNotAttempted.
  ///
  /// In en, this message translates to:
  /// **'Logging init status: not attempted in this process.'**
  String get loggingInitStatusNotAttempted;

  /// No description provided for @loggingInitStatusValue.
  ///
  /// In en, this message translates to:
  /// **'logging_init status: {status}'**
  String loggingInitStatusValue(String status);

  /// No description provided for @loggingInitLevelValue.
  ///
  /// In en, this message translates to:
  /// **'level: {level}'**
  String loggingInitLevelValue(String level);

  /// No description provided for @loggingInitLogDirValue.
  ///
  /// In en, this message translates to:
  /// **'logDir: {logDir}'**
  String loggingInitLogDirValue(String logDir);

  /// No description provided for @loggingInitErrorValue.
  ///
  /// In en, this message translates to:
  /// **'error: {error}'**
  String loggingInitErrorValue(String error);

  /// No description provided for @rustDiagnosticsInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing Rust bridge...'**
  String get rustDiagnosticsInitializing;

  /// No description provided for @rustDiagnosticsInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Rust bridge initialization failed'**
  String get rustDiagnosticsInitFailed;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @rustDiagnosticsConnected.
  ///
  /// In en, this message translates to:
  /// **'Rust bridge connected'**
  String get rustDiagnosticsConnected;

  /// No description provided for @rustDiagnosticsPingValue.
  ///
  /// In en, this message translates to:
  /// **'ping: {ping}'**
  String rustDiagnosticsPingValue(String ping);

  /// No description provided for @rustDiagnosticsCoreVersionValue.
  ///
  /// In en, this message translates to:
  /// **'coreVersion: {version}'**
  String rustDiagnosticsCoreVersionValue(String version);

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @debugLogsNoVisibleLogsToCopy.
  ///
  /// In en, this message translates to:
  /// **'No visible logs to copy.'**
  String get debugLogsNoVisibleLogsToCopy;

  /// No description provided for @debugLogsVisibleLogsCopied.
  ///
  /// In en, this message translates to:
  /// **'Visible logs copied.'**
  String get debugLogsVisibleLogsCopied;

  /// No description provided for @debugLogsOpenedLogFolder.
  ///
  /// In en, this message translates to:
  /// **'Opened log folder.'**
  String get debugLogsOpenedLogFolder;

  /// No description provided for @debugLogsOpenFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Open folder failed: {error}'**
  String debugLogsOpenFolderFailed(String error);

  /// No description provided for @commonNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get commonNever;

  /// No description provided for @debugLogsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load logs: {error}'**
  String debugLogsLoadFailed(String error);

  /// No description provided for @debugLogsNoContentYet.
  ///
  /// In en, this message translates to:
  /// **'No log content available yet.'**
  String get debugLogsNoContentYet;

  /// No description provided for @debugLogsPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs (Live)'**
  String get debugLogsPanelTitle;

  /// No description provided for @debugLogsAutoRefreshEverySeconds.
  ///
  /// In en, this message translates to:
  /// **'Auto refresh: every {seconds}s'**
  String debugLogsAutoRefreshEverySeconds(int seconds);

  /// No description provided for @debugLogsLastRefreshValue.
  ///
  /// In en, this message translates to:
  /// **'Last refresh: {time}'**
  String debugLogsLastRefreshValue(String time);

  /// No description provided for @debugLogsDirectoryValue.
  ///
  /// In en, this message translates to:
  /// **'Directory: {directory}'**
  String debugLogsDirectoryValue(String directory);

  /// No description provided for @debugLogsActiveFileValue.
  ///
  /// In en, this message translates to:
  /// **'Active file: {file}'**
  String debugLogsActiveFileValue(String file);

  /// No description provided for @debugLogsCopyVisibleButton.
  ///
  /// In en, this message translates to:
  /// **'Copy Visible Logs'**
  String get debugLogsCopyVisibleButton;

  /// No description provided for @debugLogsOpenLogFolderButton.
  ///
  /// In en, this message translates to:
  /// **'Open Log Folder'**
  String get debugLogsOpenLogFolderButton;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @notesBackShort.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get notesBackShort;

  /// No description provided for @notesShellTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes Shell'**
  String get notesShellTitle;

  /// No description provided for @notesWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'My Workspace'**
  String get notesWorkspaceTitle;

  /// No description provided for @notesPaneIndicator.
  ///
  /// In en, this message translates to:
  /// **'Pane {paneOrdinal}/{paneCount}'**
  String notesPaneIndicator(String paneOrdinal, int paneCount);

  /// No description provided for @notesSplitRightTooltip.
  ///
  /// In en, this message translates to:
  /// **'Split right'**
  String get notesSplitRightTooltip;

  /// No description provided for @notesSplitDownTooltip.
  ///
  /// In en, this message translates to:
  /// **'Split down'**
  String get notesSplitDownTooltip;

  /// No description provided for @notesNextPaneTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next pane'**
  String get notesNextPaneTooltip;

  /// No description provided for @notesClosePaneTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close pane'**
  String get notesClosePaneTooltip;

  /// No description provided for @notesReloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload notes'**
  String get notesReloadTooltip;

  /// No description provided for @notesSplitCreatedWithCount.
  ///
  /// In en, this message translates to:
  /// **'Split created. {paneCount} panes ready.'**
  String notesSplitCreatedWithCount(int paneCount);

  /// No description provided for @notesSplitCreatedSimple.
  ///
  /// In en, this message translates to:
  /// **'Split created.'**
  String get notesSplitCreatedSimple;

  /// No description provided for @notesSplitPaneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cannot split: active pane is unavailable.'**
  String get notesSplitPaneUnavailable;

  /// No description provided for @notesSplitMaxPaneReached.
  ///
  /// In en, this message translates to:
  /// **'Cannot split: maximum pane count ({maxPaneCount}) reached.'**
  String notesSplitMaxPaneReached(int maxPaneCount);

  /// No description provided for @notesSplitDirectionLocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot split: v0.2 keeps one split direction per workspace.'**
  String get notesSplitDirectionLocked;

  /// No description provided for @notesSplitMinSizeBlocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot split: each pane must stay at least {minPaneWidth}px.'**
  String notesSplitMinSizeBlocked(int minPaneWidth);

  /// No description provided for @notesOnlyOnePaneAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only one pane is available.'**
  String get notesOnlyOnePaneAvailable;

  /// No description provided for @notesSwitchedToPane.
  ///
  /// In en, this message translates to:
  /// **'Switched to pane {paneOrdinal}.'**
  String notesSwitchedToPane(String paneOrdinal);

  /// No description provided for @notesPaneClosedWithCount.
  ///
  /// In en, this message translates to:
  /// **'Pane closed. {paneCount} remaining.'**
  String notesPaneClosedWithCount(int paneCount);

  /// No description provided for @notesPaneClosedSimple.
  ///
  /// In en, this message translates to:
  /// **'Pane closed.'**
  String get notesPaneClosedSimple;

  /// No description provided for @notesClosePaneSingleBlocked.
  ///
  /// In en, this message translates to:
  /// **'Cannot close pane: only one pane is available.'**
  String get notesClosePaneSingleBlocked;

  /// No description provided for @notesClosePaneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cannot close pane: active pane is unavailable.'**
  String get notesClosePaneUnavailable;

  /// No description provided for @notesUnsavedContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Unsaved content'**
  String get notesUnsavedContentTitle;

  /// No description provided for @notesSaveFailedCloseBody.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Retry or back up content before closing.'**
  String get notesSaveFailedCloseBody;

  /// No description provided for @notesKeepEditingButton.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get notesKeepEditingButton;

  /// No description provided for @notesRetrySaveButton.
  ///
  /// In en, this message translates to:
  /// **'Retry save'**
  String get notesRetrySaveButton;

  /// No description provided for @notesNoOpenNotes.
  ///
  /// In en, this message translates to:
  /// **'No open notes'**
  String get notesNoOpenNotes;

  /// No description provided for @notesTabCloseOthers.
  ///
  /// In en, this message translates to:
  /// **'Close Others'**
  String get notesTabCloseOthers;

  /// No description provided for @notesTabCloseRight.
  ///
  /// In en, this message translates to:
  /// **'Close to the Right'**
  String get notesTabCloseRight;

  /// No description provided for @notesLoadingNotes.
  ///
  /// In en, this message translates to:
  /// **'Loading notes...'**
  String get notesLoadingNotes;

  /// No description provided for @notesDetailUnavailableWhenListError.
  ///
  /// In en, this message translates to:
  /// **'Cannot load detail while list is unavailable.'**
  String get notesDetailUnavailableWhenListError;

  /// No description provided for @notesCreateFirstNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first note in C2.'**
  String get notesCreateFirstNoteHint;

  /// No description provided for @notesSelectNoteToContinue.
  ///
  /// In en, this message translates to:
  /// **'Select a note to continue.'**
  String get notesSelectNoteToContinue;

  /// No description provided for @notesDetailNotAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Detail data is not available yet.'**
  String get notesDetailNotAvailableYet;

  /// No description provided for @notesPathPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Omni-Bar / Private'**
  String get notesPathPlaceholder;

  /// No description provided for @notesAddIconButton.
  ///
  /// In en, this message translates to:
  /// **'Add icon'**
  String get notesAddIconButton;

  /// No description provided for @notesAddImageButton.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get notesAddImageButton;

  /// No description provided for @notesAddCommentButton.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get notesAddCommentButton;

  /// No description provided for @notesUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {value}'**
  String notesUpdatedAt(String value);

  /// No description provided for @notesRetryDetailButton.
  ///
  /// In en, this message translates to:
  /// **'Retry detail'**
  String get notesRetryDetailButton;

  /// No description provided for @notesSaveStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get notesSaveStatusSaved;

  /// No description provided for @notesSaveStatusUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get notesSaveStatusUnsaved;

  /// No description provided for @notesSaveStatusSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get notesSaveStatusSaving;

  /// No description provided for @notesSaveStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get notesSaveStatusFailed;

  /// No description provided for @notesRefreshDetailTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh detail'**
  String get notesRefreshDetailTooltip;

  /// No description provided for @notesShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get notesShareAction;

  /// No description provided for @notesStarAction.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get notesStarAction;

  /// No description provided for @notesMoreAction.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get notesMoreAction;

  /// No description provided for @notesMoreActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get notesMoreActionsTooltip;

  /// No description provided for @notesTagButton.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get notesTagButton;

  /// No description provided for @notesAddTagDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get notesAddTagDialogTitle;

  /// No description provided for @notesTagInputHint.
  ///
  /// In en, this message translates to:
  /// **'tag'**
  String get notesTagInputHint;

  /// No description provided for @notesAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get notesAddButton;

  /// No description provided for @notesEditorHintText.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get notesEditorHintText;

  /// No description provided for @notesNewFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get notesNewFolderTooltip;

  /// No description provided for @notesListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notes.'**
  String get notesListLoadFailed;

  /// No description provided for @notesListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.'**
  String get notesListEmpty;

  /// No description provided for @notesWorkspaceTreeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workspace items yet.'**
  String get notesWorkspaceTreeEmpty;

  /// No description provided for @notesRetryTreeButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get notesRetryTreeButton;

  /// No description provided for @notesNoItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get notesNoItemsLabel;

  /// No description provided for @notesDropToRootLabel.
  ///
  /// In en, this message translates to:
  /// **'Move to root'**
  String get notesDropToRootLabel;

  /// No description provided for @notesLegacyFolderProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get notesLegacyFolderProjects;

  /// No description provided for @notesLegacyFolderPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get notesLegacyFolderPersonal;

  /// No description provided for @notesNewPageButton.
  ///
  /// In en, this message translates to:
  /// **'New Page'**
  String get notesNewPageButton;

  /// No description provided for @notesCreateFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get notesCreateFolderDialogTitle;

  /// No description provided for @notesFolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get notesFolderNameHint;

  /// No description provided for @notesFolderCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Folder created.'**
  String get notesFolderCreatedToast;

  /// No description provided for @notesDeleteFolderDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get notesDeleteFolderDialogTitle;

  /// No description provided for @notesDeleteFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get notesDeleteFolderTooltip;

  /// No description provided for @notesFolderDeletedWithMode.
  ///
  /// In en, this message translates to:
  /// **'Folder deleted with {modeLabel}.'**
  String notesFolderDeletedWithMode(String modeLabel);

  /// No description provided for @notesDeleteModeDissolve.
  ///
  /// In en, this message translates to:
  /// **'Dissolve'**
  String get notesDeleteModeDissolve;

  /// No description provided for @notesDeleteModeDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get notesDeleteModeDeleteAll;

  /// No description provided for @notesDeleteModeDissolveDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep notes, move direct children to root.'**
  String get notesDeleteModeDissolveDescription;

  /// No description provided for @notesDeleteModeDeleteAllDescription.
  ///
  /// In en, this message translates to:
  /// **'Delete folder subtree references and scoped notes.'**
  String get notesDeleteModeDeleteAllDescription;

  /// No description provided for @notesNewChildFolderTooltip.
  ///
  /// In en, this message translates to:
  /// **'New child folder'**
  String get notesNewChildFolderTooltip;

  /// No description provided for @notesMoveAction.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get notesMoveAction;

  /// No description provided for @notesMoveNodeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Move node'**
  String get notesMoveNodeDialogTitle;

  /// No description provided for @notesMoveTargetFolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Target folder'**
  String get notesMoveTargetFolderLabel;

  /// No description provided for @notesMoveTargetRootLabel.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get notesMoveTargetRootLabel;

  /// No description provided for @notesMovedToast.
  ///
  /// In en, this message translates to:
  /// **'Moved.'**
  String get notesMovedToast;

  /// No description provided for @notesNoMoveTargetsToast.
  ///
  /// In en, this message translates to:
  /// **'No available move targets.'**
  String get notesNoMoveTargetsToast;

  /// No description provided for @notesRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get notesRenameAction;

  /// No description provided for @notesRenameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get notesRenameDialogTitle;

  /// No description provided for @notesRenamedToast.
  ///
  /// In en, this message translates to:
  /// **'Renamed.'**
  String get notesRenamedToast;

  /// No description provided for @notesNoteCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Note created.'**
  String get notesNoteCreatedToast;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'CN': return AppLocalizationsZhCn();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
