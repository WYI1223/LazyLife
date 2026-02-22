// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get lazyNoteWorkbenchTitle => 'LazyNote Workbench';

  @override
  String get workbenchSectionNotes => 'Notes';

  @override
  String workbenchSectionNotesWithCount(int count) {
    return 'Notes ($count)';
  }

  @override
  String get workbenchSectionTasks => 'Tasks';

  @override
  String get workbenchSectionCalendar => 'Calendar';

  @override
  String get workbenchSectionSettings => 'Settings';

  @override
  String get workbenchSectionRustDiagnostics => 'Rust Diagnostics';

  @override
  String get workbenchHomeTitle => 'Workbench Home';

  @override
  String get workbenchHomeDescription =>
      'Use Workbench to run Single Entry flow and diagnostics while feature UIs are landing.';

  @override
  String get singleEntryTitle => 'Single Entry';

  @override
  String get openSingleEntryButton => 'Open Single Entry';

  @override
  String get focusSingleEntryButton => 'Focus Single Entry';

  @override
  String get hideSingleEntryButton => 'Hide Single Entry';

  @override
  String get workbenchDiagnosticsTitle => 'Diagnostics';

  @override
  String get placeholderRoutesTitle => 'Placeholder Routes';

  @override
  String get backToWorkbenchButton => 'Back to Workbench';

  @override
  String get settingsCapabilityAuditTitle =>
      'Extension capability audit (v0.2 baseline)';

  @override
  String get settingsCapabilityAuditDescription =>
      'Runtime capability checks are deny-by-default. Undeclared capabilities are rejected at invocation time.';

  @override
  String get settingsRegisteredExtensions => 'Registered Extensions';

  @override
  String get settingsCapabilityCatalog => 'Capability Catalog';

  @override
  String get settingsNoRuntimePermissionsDeclared =>
      'No runtime permissions declared (deny-by-default).';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageDescription =>
      'Switch Workbench UI language immediately.';

  @override
  String get languageOptionSystem => 'System';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionChineseSimplified => 'Chinese (Simplified)';

  @override
  String get settingsLanguageSaveFailed =>
      'Failed to save language preference.';

  @override
  String get loggingInitStatusNotAttempted =>
      'Logging init status: not attempted in this process.';

  @override
  String loggingInitStatusValue(String status) {
    return 'logging_init status: $status';
  }

  @override
  String loggingInitLevelValue(String level) {
    return 'level: $level';
  }

  @override
  String loggingInitLogDirValue(String logDir) {
    return 'logDir: $logDir';
  }

  @override
  String loggingInitErrorValue(String error) {
    return 'error: $error';
  }

  @override
  String get rustDiagnosticsInitializing => 'Initializing Rust bridge...';

  @override
  String get rustDiagnosticsInitFailed => 'Rust bridge initialization failed';

  @override
  String get retryButton => 'Retry';

  @override
  String get rustDiagnosticsConnected => 'Rust bridge connected';

  @override
  String rustDiagnosticsPingValue(String ping) {
    return 'ping: $ping';
  }

  @override
  String rustDiagnosticsCoreVersionValue(String version) {
    return 'coreVersion: $version';
  }

  @override
  String get refreshButton => 'Refresh';

  @override
  String get debugLogsNoVisibleLogsToCopy => 'No visible logs to copy.';

  @override
  String get debugLogsVisibleLogsCopied => 'Visible logs copied.';

  @override
  String get debugLogsOpenedLogFolder => 'Opened log folder.';

  @override
  String debugLogsOpenFolderFailed(String error) {
    return 'Open folder failed: $error';
  }

  @override
  String get commonNever => 'never';

  @override
  String debugLogsLoadFailed(String error) {
    return 'Failed to load logs: $error';
  }

  @override
  String get debugLogsNoContentYet => 'No log content available yet.';

  @override
  String get debugLogsPanelTitle => 'Debug Logs (Live)';

  @override
  String debugLogsAutoRefreshEverySeconds(int seconds) {
    return 'Auto refresh: every ${seconds}s';
  }

  @override
  String debugLogsLastRefreshValue(String time) {
    return 'Last refresh: $time';
  }

  @override
  String debugLogsDirectoryValue(String directory) {
    return 'Directory: $directory';
  }

  @override
  String debugLogsActiveFileValue(String file) {
    return 'Active file: $file';
  }

  @override
  String get debugLogsCopyVisibleButton => 'Copy Visible Logs';

  @override
  String get debugLogsOpenLogFolderButton => 'Open Log Folder';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCreate => 'Create';

  @override
  String get notesBackShort => 'Back';

  @override
  String get notesShellTitle => 'Notes Shell';

  @override
  String get notesWorkspaceTitle => 'My Workspace';

  @override
  String notesPaneIndicator(String paneOrdinal, int paneCount) {
    return 'Pane $paneOrdinal/$paneCount';
  }

  @override
  String get notesSplitRightTooltip => 'Split right';

  @override
  String get notesSplitDownTooltip => 'Split down';

  @override
  String get notesNextPaneTooltip => 'Next pane';

  @override
  String get notesClosePaneTooltip => 'Close pane';

  @override
  String get notesReloadTooltip => 'Reload notes';

  @override
  String notesSplitCreatedWithCount(int paneCount) {
    return 'Split created. $paneCount panes ready.';
  }

  @override
  String get notesSplitCreatedSimple => 'Split created.';

  @override
  String get notesSplitPaneUnavailable =>
      'Cannot split: active pane is unavailable.';

  @override
  String notesSplitMaxPaneReached(int maxPaneCount) {
    return 'Cannot split: maximum pane count ($maxPaneCount) reached.';
  }

  @override
  String get notesSplitDirectionLocked =>
      'Cannot split: v0.2 keeps one split direction per workspace.';

  @override
  String notesSplitMinSizeBlocked(int minPaneWidth) {
    return 'Cannot split: each pane must stay at least ${minPaneWidth}px.';
  }

  @override
  String get notesOnlyOnePaneAvailable => 'Only one pane is available.';

  @override
  String notesSwitchedToPane(String paneOrdinal) {
    return 'Switched to pane $paneOrdinal.';
  }

  @override
  String notesPaneClosedWithCount(int paneCount) {
    return 'Pane closed. $paneCount remaining.';
  }

  @override
  String get notesPaneClosedSimple => 'Pane closed.';

  @override
  String get notesClosePaneSingleBlocked =>
      'Cannot close pane: only one pane is available.';

  @override
  String get notesClosePaneUnavailable =>
      'Cannot close pane: active pane is unavailable.';

  @override
  String get notesUnsavedContentTitle => 'Unsaved content';

  @override
  String get notesSaveFailedCloseBody =>
      'Save failed. Retry or back up content before closing.';

  @override
  String get notesKeepEditingButton => 'Keep editing';

  @override
  String get notesRetrySaveButton => 'Retry save';

  @override
  String get notesNoOpenNotes => 'No open notes';

  @override
  String get notesTabCloseOthers => 'Close Others';

  @override
  String get notesTabCloseRight => 'Close to the Right';

  @override
  String get notesLoadingNotes => 'Loading notes...';

  @override
  String get notesDetailUnavailableWhenListError =>
      'Cannot load detail while list is unavailable.';

  @override
  String get notesCreateFirstNoteHint => 'Create your first note in C2.';

  @override
  String get notesSelectNoteToContinue => 'Select a note to continue.';

  @override
  String get notesDetailNotAvailableYet => 'Detail data is not available yet.';

  @override
  String get notesPathPlaceholder => 'Omni-Bar / Private';

  @override
  String get notesAddIconButton => 'Add icon';

  @override
  String get notesAddImageButton => 'Add image';

  @override
  String get notesAddCommentButton => 'Add comment';

  @override
  String notesUpdatedAt(String value) {
    return 'Updated $value';
  }

  @override
  String get notesRetryDetailButton => 'Retry detail';

  @override
  String get notesSaveStatusSaved => 'Saved';

  @override
  String get notesSaveStatusUnsaved => 'Unsaved';

  @override
  String get notesSaveStatusSaving => 'Saving...';

  @override
  String get notesSaveStatusFailed => 'Save failed';

  @override
  String get notesRefreshDetailTooltip => 'Refresh detail';

  @override
  String get notesShareAction => 'Share';

  @override
  String get notesStarAction => 'Star';

  @override
  String get notesMoreAction => 'More';

  @override
  String get notesMoreActionsTooltip => 'More actions';

  @override
  String get notesTagButton => 'Tag';

  @override
  String get notesAddTagDialogTitle => 'Add tag';

  @override
  String get notesTagInputHint => 'tag';

  @override
  String get notesAddButton => 'Add';

  @override
  String get notesEditorHintText => 'Start writing...';

  @override
  String get notesNewFolderTooltip => 'New folder';

  @override
  String get notesListLoadFailed => 'Failed to load notes.';

  @override
  String get notesListEmpty => 'No notes yet.';

  @override
  String get notesWorkspaceTreeEmpty => 'No workspace items yet.';

  @override
  String get notesRetryTreeButton => 'Retry';

  @override
  String get notesNoItemsLabel => 'No items';

  @override
  String get notesDropToRootLabel => 'Move to root';

  @override
  String get notesLegacyFolderProjects => 'Projects';

  @override
  String get notesLegacyFolderPersonal => 'Personal';

  @override
  String get notesNewPageButton => 'New Page';

  @override
  String get notesCreateFolderDialogTitle => 'Create folder';

  @override
  String get notesFolderNameHint => 'Folder name';

  @override
  String get notesFolderCreatedToast => 'Folder created.';

  @override
  String get notesDeleteFolderDialogTitle => 'Delete folder';

  @override
  String get notesDeleteFolderTooltip => 'Delete folder';

  @override
  String notesFolderDeletedWithMode(String modeLabel) {
    return 'Folder deleted with $modeLabel.';
  }

  @override
  String get notesDeleteModeDissolve => 'Dissolve';

  @override
  String get notesDeleteModeDeleteAll => 'Delete all';

  @override
  String get notesDeleteModeDissolveDescription =>
      'Keep notes, move direct children to root.';

  @override
  String get notesDeleteModeDeleteAllDescription =>
      'Delete folder subtree references and scoped notes.';

  @override
  String get notesNewChildFolderTooltip => 'New child folder';

  @override
  String get notesMoveAction => 'Move';

  @override
  String get notesMoveNodeDialogTitle => 'Move node';

  @override
  String get notesMoveTargetFolderLabel => 'Target folder';

  @override
  String get notesMoveTargetRootLabel => 'Root';

  @override
  String get notesMovedToast => 'Moved.';

  @override
  String get notesNoMoveTargetsToast => 'No available move targets.';

  @override
  String get notesRenameAction => 'Rename';

  @override
  String get notesRenameDialogTitle => 'Rename';

  @override
  String get notesRenamedToast => 'Renamed.';

  @override
  String get notesNoteCreatedToast => 'Note created.';
}
