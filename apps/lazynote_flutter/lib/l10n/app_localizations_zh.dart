// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get lazyNoteWorkbenchTitle => 'LazyNote 工作台';

  @override
  String get workbenchSectionNotes => '笔记';

  @override
  String workbenchSectionNotesWithCount(int count) {
    return '笔记（$count）';
  }

  @override
  String get workbenchSectionTasks => '任务';

  @override
  String get workbenchSectionCalendar => '日历';

  @override
  String get workbenchSectionSettings => '设置';

  @override
  String get workbenchSectionRustDiagnostics => 'Rust 诊断';

  @override
  String get workbenchHomeTitle => '工作台主页';

  @override
  String get workbenchHomeDescription => '在功能页面逐步落地期间，可在工作台中运行 Single Entry 流程与诊断能力。';

  @override
  String get singleEntryTitle => 'Single Entry';

  @override
  String get openSingleEntryButton => '打开 Single Entry';

  @override
  String get focusSingleEntryButton => '聚焦 Single Entry';

  @override
  String get hideSingleEntryButton => '隐藏 Single Entry';

  @override
  String get workbenchDiagnosticsTitle => '诊断';

  @override
  String get placeholderRoutesTitle => '占位入口';

  @override
  String get backToWorkbenchButton => '返回工作台';

  @override
  String get settingsCapabilityAuditTitle => '扩展能力审计（v0.2 基线）';

  @override
  String get settingsCapabilityAuditDescription => '运行时能力检查默认为拒绝。未声明的能力会在调用时被拒绝。';

  @override
  String get settingsRegisteredExtensions => '已注册扩展';

  @override
  String get settingsCapabilityCatalog => '能力目录';

  @override
  String get settingsNoRuntimePermissionsDeclared => '未声明运行时权限（默认拒绝）。';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageDescription => '立即切换工作台界面语言。';

  @override
  String get languageOptionSystem => '跟随系统';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionChineseSimplified => '简体中文';

  @override
  String get settingsLanguageSaveFailed => '保存语言偏好失败。';

  @override
  String get loggingInitStatusNotAttempted => '日志初始化状态：当前进程未尝试。';

  @override
  String loggingInitStatusValue(String status) {
    return 'logging_init 状态：$status';
  }

  @override
  String loggingInitLevelValue(String level) {
    return '级别：$level';
  }

  @override
  String loggingInitLogDirValue(String logDir) {
    return '日志目录：$logDir';
  }

  @override
  String loggingInitErrorValue(String error) {
    return '错误：$error';
  }

  @override
  String get rustDiagnosticsInitializing => '正在初始化 Rust 桥接...';

  @override
  String get rustDiagnosticsInitFailed => 'Rust 桥接初始化失败';

  @override
  String get retryButton => '重试';

  @override
  String get rustDiagnosticsConnected => 'Rust 桥接已连接';

  @override
  String rustDiagnosticsPingValue(String ping) {
    return 'ping：$ping';
  }

  @override
  String rustDiagnosticsCoreVersionValue(String version) {
    return '核心版本：$version';
  }

  @override
  String get refreshButton => '刷新';

  @override
  String get debugLogsNoVisibleLogsToCopy => '没有可复制的可见日志。';

  @override
  String get debugLogsVisibleLogsCopied => '已复制可见日志。';

  @override
  String get debugLogsOpenedLogFolder => '已打开日志目录。';

  @override
  String debugLogsOpenFolderFailed(String error) {
    return '打开目录失败：$error';
  }

  @override
  String get commonNever => '从未';

  @override
  String debugLogsLoadFailed(String error) {
    return '加载日志失败：$error';
  }

  @override
  String get debugLogsNoContentYet => '暂无日志内容。';

  @override
  String get debugLogsPanelTitle => '调试日志（实时）';

  @override
  String debugLogsAutoRefreshEverySeconds(int seconds) {
    return '自动刷新：每 $seconds 秒';
  }

  @override
  String debugLogsLastRefreshValue(String time) {
    return '最近刷新：$time';
  }

  @override
  String debugLogsDirectoryValue(String directory) {
    return '目录：$directory';
  }

  @override
  String debugLogsActiveFileValue(String file) {
    return '当前文件：$file';
  }

  @override
  String get debugLogsCopyVisibleButton => '复制可见日志';

  @override
  String get debugLogsOpenLogFolderButton => '打开日志目录';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonCreate => '创建';

  @override
  String get notesBackShort => '返回';

  @override
  String get notesShellTitle => '笔记工作区';

  @override
  String get notesWorkspaceTitle => '我的工作区';

  @override
  String notesPaneIndicator(String paneOrdinal, int paneCount) {
    return '窗格 $paneOrdinal/$paneCount';
  }

  @override
  String get notesSplitRightTooltip => '向右分屏';

  @override
  String get notesSplitDownTooltip => '向下分屏';

  @override
  String get notesNextPaneTooltip => '下一个窗格';

  @override
  String get notesClosePaneTooltip => '关闭窗格';

  @override
  String get notesReloadTooltip => '重新加载笔记';

  @override
  String notesSplitCreatedWithCount(int paneCount) {
    return '已创建分屏，当前 $paneCount 个窗格。';
  }

  @override
  String get notesSplitCreatedSimple => '已创建分屏。';

  @override
  String get notesSplitPaneUnavailable => '无法分屏：当前活动窗格不可用。';

  @override
  String notesSplitMaxPaneReached(int maxPaneCount) {
    return '无法分屏：已达到最大窗格数（$maxPaneCount）。';
  }

  @override
  String get notesSplitDirectionLocked => '无法分屏：v0.2 每个工作区仅允许一种分屏方向。';

  @override
  String notesSplitMinSizeBlocked(int minPaneWidth) {
    return '无法分屏：每个窗格至少保留 ${minPaneWidth}px。';
  }

  @override
  String get notesOnlyOnePaneAvailable => '当前仅有一个窗格。';

  @override
  String notesSwitchedToPane(String paneOrdinal) {
    return '已切换到窗格 $paneOrdinal。';
  }

  @override
  String notesPaneClosedWithCount(int paneCount) {
    return '已关闭窗格，剩余 $paneCount。';
  }

  @override
  String get notesPaneClosedSimple => '已关闭窗格。';

  @override
  String get notesClosePaneSingleBlocked => '无法关闭窗格：当前仅有一个窗格。';

  @override
  String get notesClosePaneUnavailable => '无法关闭窗格：当前活动窗格不可用。';

  @override
  String get notesUnsavedContentTitle => '内容未保存';

  @override
  String get notesSaveFailedCloseBody => '保存失败。请重试或备份内容后再关闭。';

  @override
  String get notesKeepEditingButton => '继续编辑';

  @override
  String get notesRetrySaveButton => '重试保存';

  @override
  String get notesNoOpenNotes => '暂无打开的笔记';

  @override
  String get notesTabCloseOthers => '关闭其他';

  @override
  String get notesTabCloseRight => '关闭右侧';

  @override
  String get notesLoadingNotes => '正在加载笔记...';

  @override
  String get notesDetailUnavailableWhenListError => '列表不可用，无法加载详情。';

  @override
  String get notesCreateFirstNoteHint => '在 C2 中创建第一条笔记。';

  @override
  String get notesSelectNoteToContinue => '请选择一条笔记继续。';

  @override
  String get notesDetailNotAvailableYet => '详情数据暂不可用。';

  @override
  String get notesPathPlaceholder => 'Omni-Bar / Private';

  @override
  String get notesAddIconButton => '添加图标';

  @override
  String get notesAddImageButton => '添加图片';

  @override
  String get notesAddCommentButton => '添加评论';

  @override
  String notesUpdatedAt(String value) {
    return '更新于 $value';
  }

  @override
  String get notesRetryDetailButton => '重试详情加载';

  @override
  String get notesSaveStatusSaved => '已保存';

  @override
  String get notesSaveStatusUnsaved => '未保存';

  @override
  String get notesSaveStatusSaving => '保存中...';

  @override
  String get notesSaveStatusFailed => '保存失败';

  @override
  String get notesRefreshDetailTooltip => '刷新详情';

  @override
  String get notesShareAction => '分享';

  @override
  String get notesStarAction => '星标';

  @override
  String get notesMoreAction => '更多';

  @override
  String get notesMoreActionsTooltip => '更多操作';

  @override
  String get notesTagButton => '标签';

  @override
  String get notesAddTagDialogTitle => '添加标签';

  @override
  String get notesTagInputHint => '标签';

  @override
  String get notesAddButton => '添加';

  @override
  String get notesEditorHintText => '开始输入...';

  @override
  String get notesNewFolderTooltip => '新建文件夹';

  @override
  String get notesListLoadFailed => '加载笔记失败。';

  @override
  String get notesListEmpty => '暂无笔记。';

  @override
  String get notesWorkspaceTreeEmpty => '暂无工作区条目。';

  @override
  String get notesRetryTreeButton => '重试';

  @override
  String get notesNoItemsLabel => '暂无内容';

  @override
  String get notesDropToRootLabel => '移动到根级';

  @override
  String get notesLegacyFolderProjects => '项目';

  @override
  String get notesLegacyFolderPersonal => '个人';

  @override
  String get notesNewPageButton => '新建页面';

  @override
  String get notesCreateFolderDialogTitle => '新建文件夹';

  @override
  String get notesFolderNameHint => '文件夹名称';

  @override
  String get notesFolderCreatedToast => '文件夹已创建。';

  @override
  String get notesDeleteFolderDialogTitle => '删除文件夹';

  @override
  String get notesDeleteFolderTooltip => '删除文件夹';

  @override
  String notesFolderDeletedWithMode(String modeLabel) {
    return '已按“$modeLabel”删除文件夹。';
  }

  @override
  String get notesDeleteModeDissolve => '解散';

  @override
  String get notesDeleteModeDeleteAll => '全部删除';

  @override
  String get notesDeleteModeDissolveDescription => '保留笔记，直属子项提升到根级。';

  @override
  String get notesDeleteModeDeleteAllDescription => '删除该文件夹子树引用及其范围内笔记。';

  @override
  String get notesNewChildFolderTooltip => '新建子文件夹';

  @override
  String get notesMoveAction => '移动';

  @override
  String get notesMoveNodeDialogTitle => '移动节点';

  @override
  String get notesMoveTargetFolderLabel => '目标文件夹';

  @override
  String get notesMoveTargetRootLabel => '根级';

  @override
  String get notesMovedToast => '已移动。';

  @override
  String get notesNoMoveTargetsToast => '没有可用的移动目标。';

  @override
  String get notesRenameAction => '重命名';

  @override
  String get notesRenameDialogTitle => '重命名';

  @override
  String get notesRenamedToast => '已重命名。';

  @override
  String get notesNoteCreatedToast => '笔记已创建。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn(): super('zh_CN');

  @override
  String get lazyNoteWorkbenchTitle => 'LazyNote 工作台';

  @override
  String get workbenchSectionNotes => '笔记';

  @override
  String workbenchSectionNotesWithCount(int count) {
    return '笔记（$count）';
  }

  @override
  String get workbenchSectionTasks => '任务';

  @override
  String get workbenchSectionCalendar => '日历';

  @override
  String get workbenchSectionSettings => '设置';

  @override
  String get workbenchSectionRustDiagnostics => 'Rust 诊断';

  @override
  String get workbenchHomeTitle => '工作台主页';

  @override
  String get workbenchHomeDescription => '在功能页面逐步落地期间，可在工作台中运行 Single Entry 流程与诊断能力。';

  @override
  String get singleEntryTitle => 'Single Entry';

  @override
  String get openSingleEntryButton => '打开 Single Entry';

  @override
  String get focusSingleEntryButton => '聚焦 Single Entry';

  @override
  String get hideSingleEntryButton => '隐藏 Single Entry';

  @override
  String get workbenchDiagnosticsTitle => '诊断';

  @override
  String get placeholderRoutesTitle => '占位入口';

  @override
  String get backToWorkbenchButton => '返回工作台';

  @override
  String get settingsCapabilityAuditTitle => '扩展能力审计（v0.2 基线）';

  @override
  String get settingsCapabilityAuditDescription => '运行时能力检查默认为拒绝。未声明的能力会在调用时被拒绝。';

  @override
  String get settingsRegisteredExtensions => '已注册扩展';

  @override
  String get settingsCapabilityCatalog => '能力目录';

  @override
  String get settingsNoRuntimePermissionsDeclared => '未声明运行时权限（默认拒绝）。';

  @override
  String get settingsLanguageTitle => '语言';

  @override
  String get settingsLanguageDescription => '立即切换工作台界面语言。';

  @override
  String get languageOptionSystem => '跟随系统';

  @override
  String get languageOptionEnglish => 'English';

  @override
  String get languageOptionChineseSimplified => '简体中文';

  @override
  String get settingsLanguageSaveFailed => '保存语言偏好失败。';

  @override
  String get loggingInitStatusNotAttempted => '日志初始化状态：当前进程未尝试。';

  @override
  String loggingInitStatusValue(String status) {
    return 'logging_init 状态：$status';
  }

  @override
  String loggingInitLevelValue(String level) {
    return '级别：$level';
  }

  @override
  String loggingInitLogDirValue(String logDir) {
    return '日志目录：$logDir';
  }

  @override
  String loggingInitErrorValue(String error) {
    return '错误：$error';
  }

  @override
  String get rustDiagnosticsInitializing => '正在初始化 Rust 桥接...';

  @override
  String get rustDiagnosticsInitFailed => 'Rust 桥接初始化失败';

  @override
  String get retryButton => '重试';

  @override
  String get rustDiagnosticsConnected => 'Rust 桥接已连接';

  @override
  String rustDiagnosticsPingValue(String ping) {
    return 'ping：$ping';
  }

  @override
  String rustDiagnosticsCoreVersionValue(String version) {
    return '核心版本：$version';
  }

  @override
  String get refreshButton => '刷新';

  @override
  String get debugLogsNoVisibleLogsToCopy => '没有可复制的可见日志。';

  @override
  String get debugLogsVisibleLogsCopied => '已复制可见日志。';

  @override
  String get debugLogsOpenedLogFolder => '已打开日志目录。';

  @override
  String debugLogsOpenFolderFailed(String error) {
    return '打开目录失败：$error';
  }

  @override
  String get commonNever => '从未';

  @override
  String debugLogsLoadFailed(String error) {
    return '加载日志失败：$error';
  }

  @override
  String get debugLogsNoContentYet => '暂无日志内容。';

  @override
  String get debugLogsPanelTitle => '调试日志（实时）';

  @override
  String debugLogsAutoRefreshEverySeconds(int seconds) {
    return '自动刷新：每 $seconds 秒';
  }

  @override
  String debugLogsLastRefreshValue(String time) {
    return '最近刷新：$time';
  }

  @override
  String debugLogsDirectoryValue(String directory) {
    return '目录：$directory';
  }

  @override
  String debugLogsActiveFileValue(String file) {
    return '当前文件：$file';
  }

  @override
  String get debugLogsCopyVisibleButton => '复制可见日志';

  @override
  String get debugLogsOpenLogFolderButton => '打开日志目录';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonCreate => '创建';

  @override
  String get notesBackShort => '返回';

  @override
  String get notesShellTitle => '笔记工作区';

  @override
  String get notesWorkspaceTitle => '我的工作区';

  @override
  String notesPaneIndicator(String paneOrdinal, int paneCount) {
    return '窗格 $paneOrdinal/$paneCount';
  }

  @override
  String get notesSplitRightTooltip => '向右分屏';

  @override
  String get notesSplitDownTooltip => '向下分屏';

  @override
  String get notesNextPaneTooltip => '下一个窗格';

  @override
  String get notesClosePaneTooltip => '关闭窗格';

  @override
  String get notesReloadTooltip => '重新加载笔记';

  @override
  String notesSplitCreatedWithCount(int paneCount) {
    return '已创建分屏，当前 $paneCount 个窗格。';
  }

  @override
  String get notesSplitCreatedSimple => '已创建分屏。';

  @override
  String get notesSplitPaneUnavailable => '无法分屏：当前活动窗格不可用。';

  @override
  String notesSplitMaxPaneReached(int maxPaneCount) {
    return '无法分屏：已达到最大窗格数（$maxPaneCount）。';
  }

  @override
  String get notesSplitDirectionLocked => '无法分屏：v0.2 每个工作区仅允许一种分屏方向。';

  @override
  String notesSplitMinSizeBlocked(int minPaneWidth) {
    return '无法分屏：每个窗格至少保留 ${minPaneWidth}px。';
  }

  @override
  String get notesOnlyOnePaneAvailable => '当前仅有一个窗格。';

  @override
  String notesSwitchedToPane(String paneOrdinal) {
    return '已切换到窗格 $paneOrdinal。';
  }

  @override
  String notesPaneClosedWithCount(int paneCount) {
    return '已关闭窗格，剩余 $paneCount。';
  }

  @override
  String get notesPaneClosedSimple => '已关闭窗格。';

  @override
  String get notesClosePaneSingleBlocked => '无法关闭窗格：当前仅有一个窗格。';

  @override
  String get notesClosePaneUnavailable => '无法关闭窗格：当前活动窗格不可用。';

  @override
  String get notesUnsavedContentTitle => '内容未保存';

  @override
  String get notesSaveFailedCloseBody => '保存失败。请重试或备份内容后再关闭。';

  @override
  String get notesKeepEditingButton => '继续编辑';

  @override
  String get notesRetrySaveButton => '重试保存';

  @override
  String get notesNoOpenNotes => '暂无打开的笔记';

  @override
  String get notesTabCloseOthers => '关闭其他';

  @override
  String get notesTabCloseRight => '关闭右侧';

  @override
  String get notesLoadingNotes => '正在加载笔记...';

  @override
  String get notesDetailUnavailableWhenListError => '列表不可用，无法加载详情。';

  @override
  String get notesCreateFirstNoteHint => '在 C2 中创建第一条笔记。';

  @override
  String get notesSelectNoteToContinue => '请选择一条笔记继续。';

  @override
  String get notesDetailNotAvailableYet => '详情数据暂不可用。';

  @override
  String get notesPathPlaceholder => 'Omni-Bar / Private';

  @override
  String get notesAddIconButton => '添加图标';

  @override
  String get notesAddImageButton => '添加图片';

  @override
  String get notesAddCommentButton => '添加评论';

  @override
  String notesUpdatedAt(String value) {
    return '更新于 $value';
  }

  @override
  String get notesRetryDetailButton => '重试详情加载';

  @override
  String get notesSaveStatusSaved => '已保存';

  @override
  String get notesSaveStatusUnsaved => '未保存';

  @override
  String get notesSaveStatusSaving => '保存中...';

  @override
  String get notesSaveStatusFailed => '保存失败';

  @override
  String get notesRefreshDetailTooltip => '刷新详情';

  @override
  String get notesShareAction => '分享';

  @override
  String get notesStarAction => '星标';

  @override
  String get notesMoreAction => '更多';

  @override
  String get notesMoreActionsTooltip => '更多操作';

  @override
  String get notesTagButton => '标签';

  @override
  String get notesAddTagDialogTitle => '添加标签';

  @override
  String get notesTagInputHint => '标签';

  @override
  String get notesAddButton => '添加';

  @override
  String get notesEditorHintText => '开始输入...';

  @override
  String get notesNewFolderTooltip => '新建文件夹';

  @override
  String get notesListLoadFailed => '加载笔记失败。';

  @override
  String get notesListEmpty => '暂无笔记。';

  @override
  String get notesWorkspaceTreeEmpty => '暂无工作区条目。';

  @override
  String get notesRetryTreeButton => '重试';

  @override
  String get notesNoItemsLabel => '暂无内容';

  @override
  String get notesDropToRootLabel => '移动到根级';

  @override
  String get notesLegacyFolderProjects => '项目';

  @override
  String get notesLegacyFolderPersonal => '个人';

  @override
  String get notesNewPageButton => '新建页面';

  @override
  String get notesCreateFolderDialogTitle => '新建文件夹';

  @override
  String get notesFolderNameHint => '文件夹名称';

  @override
  String get notesFolderCreatedToast => '文件夹已创建。';

  @override
  String get notesDeleteFolderDialogTitle => '删除文件夹';

  @override
  String get notesDeleteFolderTooltip => '删除文件夹';

  @override
  String notesFolderDeletedWithMode(String modeLabel) {
    return '已按“$modeLabel”删除文件夹。';
  }

  @override
  String get notesDeleteModeDissolve => '解散';

  @override
  String get notesDeleteModeDeleteAll => '全部删除';

  @override
  String get notesDeleteModeDissolveDescription => '保留笔记，直属子项提升到根级。';

  @override
  String get notesDeleteModeDeleteAllDescription => '删除该文件夹子树引用及其范围内笔记。';

  @override
  String get notesNewChildFolderTooltip => '新建子文件夹';

  @override
  String get notesMoveAction => '移动';

  @override
  String get notesMoveNodeDialogTitle => '移动节点';

  @override
  String get notesMoveTargetFolderLabel => '目标文件夹';

  @override
  String get notesMoveTargetRootLabel => '根级';

  @override
  String get notesMovedToast => '已移动。';

  @override
  String get notesNoMoveTargetsToast => '没有可用的移动目标。';

  @override
  String get notesRenameAction => '重命名';

  @override
  String get notesRenameDialogTitle => '重命名';

  @override
  String get notesRenamedToast => '已重命名。';

  @override
  String get notesNoteCreatedToast => '笔记已创建。';
}
