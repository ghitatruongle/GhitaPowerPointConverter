// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ghita PPT Converter';

  @override
  String get homeTitle => 'Home';

  @override
  String get editorTitle => 'Editor';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get templatesTitle => 'Templates';

  @override
  String get aiChatTitle => 'AI Chat';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get newSlide => 'New Slide';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get export => 'Export';

  @override
  String get import => 'Import';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get present => 'Present';

  @override
  String get presentation => 'Presentation';

  @override
  String get slides => 'Slides';

  @override
  String slideCount(int count) {
    return 'Slides ($count)';
  }

  @override
  String get noSlidesYet => 'No slides yet';

  @override
  String get clickToAddSlide => 'Click + to add a slide';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get notes => 'Notes';

  @override
  String get addSlideTooltip => 'Add new slide';

  @override
  String get deleteSlideTooltip => 'Delete slide';

  @override
  String get duplicateSlideTooltip => 'Duplicate slide';

  @override
  String get previewTooltip => 'Preview slide';

  @override
  String get editSlide => 'Edit Slide';

  @override
  String get preview => 'Preview';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get apply => 'Apply';

  @override
  String get close => 'Close';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get connectionError =>
      'Network connection error. Please check your internet.';

  @override
  String get timeoutError => 'Request timed out. Please try again.';

  @override
  String get invalidFile => 'Invalid file format.';

  @override
  String get fileNotFound => 'File not found.';

  @override
  String get permissionDenied => 'Permission denied.';

  @override
  String get unknownError => 'An unknown error occurred.';

  @override
  String get saveSuccess => 'Saved successfully';

  @override
  String get exportSuccess => 'Exported successfully';

  @override
  String get importSuccess => 'Imported successfully';

  @override
  String get deleteSuccess => 'Deleted successfully';

  @override
  String get duplicateSuccess => 'Duplicated successfully';

  @override
  String deletedWithUndo(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get undoAction => 'Undo';

  @override
  String get addNewProvider => 'Add New';

  @override
  String get details => 'Details';

  @override
  String apiKeySaved(String name) {
    return 'API Key saved for $name';
  }

  @override
  String get apiKeyHint => 'API Key...';

  @override
  String get saveApiKeyTooltip => 'Save API Key';

  @override
  String get exportBackup => 'Export Configuration (JSON)';

  @override
  String get importBackup => 'Import Configuration (JSON)';

  @override
  String get saveBackup => 'Save backup';

  @override
  String get restoreSettings => 'Restore settings?';

  @override
  String restoreSettingsMessage(String date, int count) {
    return 'Backup from $date.\nNumber of providers: $count\n\nCurrent settings will be overwritten. Continue?';
  }

  @override
  String get restore => 'Restore';

  @override
  String backupExported(String filename) {
    return 'Backup exported successfully: $filename';
  }

  @override
  String get settingsRestored => 'Settings restored successfully!';

  @override
  String get about => 'About';

  @override
  String get appearance => 'Appearance';

  @override
  String get interfaceMode => 'Interface Mode';

  @override
  String currentMode(String mode) {
    return 'Current: $mode';
  }

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get autoMode => 'Auto';

  @override
  String get lightModeFull => 'Light Mode';

  @override
  String get darkModeFull => 'Dark Mode';

  @override
  String get systemMode => 'System (Auto)';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get customTheme => 'Customize Theme';

  @override
  String get customThemeSubtitle => 'Colors, fonts, preset themes';

  @override
  String get presetThemes => 'Preset Themes';

  @override
  String get customColors => 'Custom Colors';

  @override
  String get primaryColor => 'Primary Color';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get typography => 'Typography';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get exportTheme => 'Export theme';

  @override
  String get importTheme => 'Import theme';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get themeResetMessage => 'Theme reset to Office Blue';

  @override
  String themeAppliedMessage(String name) {
    return 'Applied $name preset';
  }

  @override
  String get themeCopied => 'Theme copied to clipboard!';

  @override
  String get themeImported => 'Theme imported successfully!';

  @override
  String get themeImportFailed => 'Failed to import theme. Invalid format.';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get pickColor => 'Pick a color';

  @override
  String get pickColorTooltip => 'Pick color';

  @override
  String get officeBlue => 'Office Blue';

  @override
  String get officeBlueDesc => 'Classic Microsoft Office';

  @override
  String get darkProfessional => 'Dark Professional';

  @override
  String get darkProfessionalDesc => 'Elegant dark theme';

  @override
  String get lightMinimal => 'Light Minimal';

  @override
  String get lightMinimalDesc => 'Clean and minimal';

  @override
  String get custom => 'Custom';

  @override
  String get customDesc => 'Your custom theme';

  @override
  String get version => 'Version';

  @override
  String versionInfo(String version, String year) {
    return '$version • Build $year';
  }

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get aiProvider => 'API Key & AI Provider';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get infoSection => 'Information';

  @override
  String get addNew => 'Add New';

  @override
  String get recentProjects => 'Recent Projects';

  @override
  String get noRecentProjects => 'No recent projects';

  @override
  String get openProject => 'Open Project';

  @override
  String get removeFromList => 'Remove from list';

  @override
  String get removeAll => 'Remove All';

  @override
  String get confirmRemoveAll => 'Remove all recent projects?';

  @override
  String get search => 'Search';

  @override
  String get templates => 'Templates';

  @override
  String get noTemplates => 'No templates available';

  @override
  String get useTemplate => 'Use Template';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get typeMessage => 'Type your message...';

  @override
  String get send => 'Send';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get stop => 'Stop';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get clearChatConfirm => 'Clear chat history?';

  @override
  String get selectProvider => 'Select AI Provider';

  @override
  String get noProviders => 'No AI providers configured';

  @override
  String get addProviderFirst => 'Add a provider in Settings first';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get cut => 'Cut';

  @override
  String get selectAll => 'Select All';

  @override
  String get bold => 'Bold';

  @override
  String get italic => 'Italic';

  @override
  String get underline => 'Underline';

  @override
  String get strikethrough => 'Strikethrough';

  @override
  String get alignLeft => 'Align Left';

  @override
  String get alignCenter => 'Align Center';

  @override
  String get alignRight => 'Align Right';

  @override
  String get alignJustify => 'Justify';

  @override
  String get bulletList => 'Bullet List';

  @override
  String get numberedList => 'Numbered List';

  @override
  String get indent => 'Indent';

  @override
  String get outdent => 'Outdent';

  @override
  String get link => 'Link';

  @override
  String get image => 'Image';

  @override
  String get table => 'Table';

  @override
  String get code => 'Code';

  @override
  String get format => 'Format';

  @override
  String get help => 'Help';

  @override
  String get shortcuts => 'Keyboard Shortcuts';

  @override
  String get exitPresentation => 'Exit Presentation';

  @override
  String get nextSlide => 'Next Slide';

  @override
  String get previousSlide => 'Previous Slide';

  @override
  String get firstSlide => 'First Slide';

  @override
  String get lastSlide => 'Last Slide';

  @override
  String get aiTools => 'AI Tools';

  @override
  String get improveWriting => 'Improve Writing';

  @override
  String get fixGrammar => 'Fix Grammar';

  @override
  String get makeShorter => 'Make Shorter';

  @override
  String get makeLonger => 'Make Longer';

  @override
  String translateTo(String language) {
    return 'Translate to $language';
  }

  @override
  String get summary => 'Summary';

  @override
  String get generateSlides => 'Generate Slides';

  @override
  String get fromText => 'From Text';

  @override
  String get fromTopic => 'From Topic';

  @override
  String get topic => 'Topic';

  @override
  String get slideCountQuestion => 'How many slides?';

  @override
  String get style => 'Style';

  @override
  String get professional => 'Professional';

  @override
  String get casual => 'Casual';

  @override
  String get academic => 'Academic';

  @override
  String get creative => 'Creative';

  @override
  String get files => 'Files';

  @override
  String get addFiles => 'Add Files';

  @override
  String get noFiles => 'No files';

  @override
  String get fileName => 'File Name';

  @override
  String get fileSize => 'Size';

  @override
  String get fileType => 'Type';

  @override
  String get uploadedAt => 'Uploaded';

  @override
  String get collaboration => 'Collaboration';

  @override
  String get startSession => 'Start Session';

  @override
  String get joinSession => 'Join Session';

  @override
  String get sessionCode => 'Session Code';

  @override
  String get host => 'Host';

  @override
  String get join => 'Join';

  @override
  String get leave => 'Leave';

  @override
  String get audio => 'Audio';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get playRecording => 'Play Recording';

  @override
  String get deleteRecording => 'Delete Recording';

  @override
  String get audioRecorded => 'Audio recorded';

  @override
  String get recordings => 'Recordings';

  @override
  String get noRecordings => 'No recordings yet';

  @override
  String get advancedExport => 'Advanced Export';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get aspectRatio => 'Aspect Ratio';

  @override
  String get quality => 'Quality';

  @override
  String get exportOptions => 'Options';

  @override
  String get includeSpeakerNotes => 'Include speaker notes';

  @override
  String get includeBackgrounds => 'Include backgrounds';

  @override
  String get slidesToExport => 'Slides to Export';

  @override
  String get allSlides => 'All slides';

  @override
  String selectedSlides(int count) {
    return 'Selected ($count)';
  }

  @override
  String get exporting => 'Exporting...';

  @override
  String exportSuccessful(String summary) {
    return 'Export successful: $summary';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get chooseAtLeastOneSlide =>
      'Select at least one slide or choose \"All slides\".';

  @override
  String get chooseTemplate => 'Choose a Template';

  @override
  String get htmlPreview => 'HTML Preview:';

  @override
  String get useThisTemplate => 'Use This Template';

  @override
  String get clearAllSlides => 'Clear All Slides';

  @override
  String clearAllSlidesMessage(int count) {
    return 'Are you sure you want to delete all $count slides? This action cannot be undone.';
  }

  @override
  String get deletedAllSlides => 'Deleted all slides';

  @override
  String get untitledPresentation => 'Untitled Presentation';

  @override
  String get hideSidebar => 'Hide Sidebar';

  @override
  String get showSidebar => 'Show Sidebar';

  @override
  String get toggleTheme => 'Toggle Theme';

  @override
  String get slideEditor => 'Slide Editor';

  @override
  String get navigation => 'Navigation';

  @override
  String get system => 'System';

  @override
  String get noSlides => 'There are no slides to present.';

  @override
  String get startCollaboration => 'Start collaboration';

  @override
  String get stopCollaboration => 'Stop collaboration';

  @override
  String get leaveCollaboration => 'Leave session';

  @override
  String get hostCollaboration => 'Host a collaboration session';

  @override
  String get hostCollaborationDescription =>
      'Share the current presentation with trusted people on this local network.';

  @override
  String get joinCollaboration => 'Join a session';

  @override
  String get hostOrShareLink => 'Host IP or share link';

  @override
  String get port => 'Port';

  @override
  String get displayName => 'Display name';

  @override
  String get sessionToken => 'Session token';

  @override
  String get connect => 'Connect';

  @override
  String get collaborationHosting => 'Hosting a protected session';

  @override
  String get collaborationConnected => 'Connected and syncing';

  @override
  String collaborationRevision(int revision) {
    return 'Revision $revision';
  }

  @override
  String collaborationParticipants(int count) {
    return 'Participants: $count';
  }

  @override
  String get collaborationSecurityNotice =>
      'Only share the link or token with trusted people on your local network.';

  @override
  String get collaborationStartFailed =>
      'Could not start the protected local server. Check the port and firewall.';

  @override
  String get collaborationJoinFields =>
      'Enter a host/share link and session token.';

  @override
  String get collaborationJoinFailed =>
      'Could not authenticate or connect to this session.';

  @override
  String get collaborationJoined => 'Connected. Slides are now synchronized.';

  @override
  String get collaborationLinkCopied => 'Protected share link copied.';

  @override
  String get collaborationConflict =>
      'A newer revision was found. The authoritative host version was restored.';

  @override
  String get collaborationAuthFailed =>
      'The collaboration token is no longer valid.';

  @override
  String slideListSemantics(int count) {
    return 'Slide list, $count slides';
  }

  @override
  String slideSemanticLabel(int number, String title) {
    return 'Slide $number: $title';
  }

  @override
  String get slideSemanticHint =>
      'Activate to edit. Long press for more actions.';

  @override
  String get workspaceSemantics => 'GhitaPPT presentation workspace';
}
