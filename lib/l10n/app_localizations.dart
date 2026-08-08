import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

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
    Locale('vi')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Ghita PPT Converter'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editorTitle;

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templatesTitle;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChatTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @newSlide.
  ///
  /// In en, this message translates to:
  /// **'New Slide'**
  String get newSlide;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @presentFromCurrent.
  ///
  /// In en, this message translates to:
  /// **'From Current'**
  String get presentFromCurrent;

  /// No description provided for @presentation.
  ///
  /// In en, this message translates to:
  /// **'Presentation'**
  String get presentation;

  /// No description provided for @slides.
  ///
  /// In en, this message translates to:
  /// **'Slides'**
  String get slides;

  /// No description provided for @slideCount.
  ///
  /// In en, this message translates to:
  /// **'Slides ({count})'**
  String slideCount(int count);

  /// No description provided for @noSlidesYet.
  ///
  /// In en, this message translates to:
  /// **'No slides yet'**
  String get noSlidesYet;

  /// No description provided for @clickToAddSlide.
  ///
  /// In en, this message translates to:
  /// **'Click + to add a slide'**
  String get clickToAddSlide;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addSlideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add new slide'**
  String get addSlideTooltip;

  /// No description provided for @deleteSlideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete slide'**
  String get deleteSlideTooltip;

  /// No description provided for @duplicateSlideTooltip.
  ///
  /// In en, this message translates to:
  /// **'Duplicate slide'**
  String get duplicateSlideTooltip;

  /// No description provided for @previewTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview slide'**
  String get previewTooltip;

  /// No description provided for @editSlide.
  ///
  /// In en, this message translates to:
  /// **'Edit Slide'**
  String get editSlide;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Network connection error. Please check your internet.'**
  String get connectionError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get timeoutError;

  /// No description provided for @invalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format.'**
  String get invalidFile;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found.'**
  String get fileNotFound;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied.'**
  String get permissionDenied;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownError;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get saveSuccess;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported successfully'**
  String get exportSuccess;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported successfully'**
  String get importSuccess;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @duplicateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Duplicated successfully'**
  String get duplicateSuccess;

  /// No description provided for @deletedWithUndo.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deletedWithUndo(String title);

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @addNewProvider.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNewProvider;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API Key saved for {name}'**
  String apiKeySaved(String name);

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'API Key...'**
  String get apiKeyHint;

  /// No description provided for @saveApiKeyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save API Key'**
  String get saveApiKeyTooltip;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Configuration (JSON)'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Configuration (JSON)'**
  String get importBackup;

  /// No description provided for @saveBackup.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackup;

  /// No description provided for @restoreSettings.
  ///
  /// In en, this message translates to:
  /// **'Restore settings?'**
  String get restoreSettings;

  /// No description provided for @restoreSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup from {date}.\nNumber of providers: {count}\n\nCurrent settings will be overwritten. Continue?'**
  String restoreSettingsMessage(String date, int count);

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully: {filename}'**
  String backupExported(String filename);

  /// No description provided for @settingsRestored.
  ///
  /// In en, this message translates to:
  /// **'Settings restored successfully!'**
  String get settingsRestored;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @interfaceMode.
  ///
  /// In en, this message translates to:
  /// **'Interface Mode'**
  String get interfaceMode;

  /// No description provided for @currentMode.
  ///
  /// In en, this message translates to:
  /// **'Current: {mode}'**
  String currentMode(String mode);

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @autoMode.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoMode;

  /// No description provided for @lightModeFull.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightModeFull;

  /// No description provided for @darkModeFull.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeFull;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System (Auto)'**
  String get systemMode;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @customTheme.
  ///
  /// In en, this message translates to:
  /// **'Customize Theme'**
  String get customTheme;

  /// No description provided for @customThemeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Colors, fonts, preset themes'**
  String get customThemeSubtitle;

  /// No description provided for @presetThemes.
  ///
  /// In en, this message translates to:
  /// **'Preset Themes'**
  String get presetThemes;

  /// No description provided for @customColors.
  ///
  /// In en, this message translates to:
  /// **'Custom Colors'**
  String get customColors;

  /// No description provided for @primaryColor.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColor;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @typography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get typography;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @exportTheme.
  ///
  /// In en, this message translates to:
  /// **'Export theme'**
  String get exportTheme;

  /// No description provided for @importTheme.
  ///
  /// In en, this message translates to:
  /// **'Import theme'**
  String get importTheme;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @themeResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Theme reset to Office Blue'**
  String get themeResetMessage;

  /// No description provided for @themeAppliedMessage.
  ///
  /// In en, this message translates to:
  /// **'Applied {name} preset'**
  String themeAppliedMessage(String name);

  /// No description provided for @themeCopied.
  ///
  /// In en, this message translates to:
  /// **'Theme copied to clipboard!'**
  String get themeCopied;

  /// No description provided for @themeImported.
  ///
  /// In en, this message translates to:
  /// **'Theme imported successfully!'**
  String get themeImported;

  /// No description provided for @themeImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import theme. Invalid format.'**
  String get themeImportFailed;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickColor;

  /// No description provided for @pickColorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pick color'**
  String get pickColorTooltip;

  /// No description provided for @officeBlue.
  ///
  /// In en, this message translates to:
  /// **'Office Blue'**
  String get officeBlue;

  /// No description provided for @officeBlueDesc.
  ///
  /// In en, this message translates to:
  /// **'Classic Microsoft Office'**
  String get officeBlueDesc;

  /// No description provided for @darkProfessional.
  ///
  /// In en, this message translates to:
  /// **'Dark Professional'**
  String get darkProfessional;

  /// No description provided for @darkProfessionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Elegant dark theme'**
  String get darkProfessionalDesc;

  /// No description provided for @lightMinimal.
  ///
  /// In en, this message translates to:
  /// **'Light Minimal'**
  String get lightMinimal;

  /// No description provided for @lightMinimalDesc.
  ///
  /// In en, this message translates to:
  /// **'Clean and minimal'**
  String get lightMinimalDesc;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customDesc.
  ///
  /// In en, this message translates to:
  /// **'Your custom theme'**
  String get customDesc;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'{version} • Build {year}'**
  String versionInfo(String version, String year);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get vietnamese;

  /// No description provided for @aiProvider.
  ///
  /// In en, this message translates to:
  /// **'API Key & AI Provider'**
  String get aiProvider;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupRestore;

  /// No description provided for @infoSection.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get infoSection;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @recentProjects.
  ///
  /// In en, this message translates to:
  /// **'Recent Projects'**
  String get recentProjects;

  /// No description provided for @noRecentProjects.
  ///
  /// In en, this message translates to:
  /// **'No recent projects'**
  String get noRecentProjects;

  /// No description provided for @openProject.
  ///
  /// In en, this message translates to:
  /// **'Open Project'**
  String get openProject;

  /// No description provided for @removeFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get removeFromList;

  /// No description provided for @removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove All'**
  String get removeAll;

  /// No description provided for @confirmRemoveAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all recent projects?'**
  String get confirmRemoveAll;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @noTemplates.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get noTemplates;

  /// No description provided for @useTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get useTemplate;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @clearChat.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat'**
  String get clearChat;

  /// No description provided for @clearChatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear chat history?'**
  String get clearChatConfirm;

  /// No description provided for @selectProvider.
  ///
  /// In en, this message translates to:
  /// **'Select AI Provider'**
  String get selectProvider;

  /// No description provided for @noProviders.
  ///
  /// In en, this message translates to:
  /// **'No AI providers configured'**
  String get noProviders;

  /// No description provided for @addProviderFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a provider in Settings first'**
  String get addProviderFirst;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @cut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get cut;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get bold;

  /// No description provided for @italic.
  ///
  /// In en, this message translates to:
  /// **'Italic'**
  String get italic;

  /// No description provided for @underline.
  ///
  /// In en, this message translates to:
  /// **'Underline'**
  String get underline;

  /// No description provided for @strikethrough.
  ///
  /// In en, this message translates to:
  /// **'Strikethrough'**
  String get strikethrough;

  /// No description provided for @alignLeft.
  ///
  /// In en, this message translates to:
  /// **'Align Left'**
  String get alignLeft;

  /// No description provided for @alignCenter.
  ///
  /// In en, this message translates to:
  /// **'Align Center'**
  String get alignCenter;

  /// No description provided for @alignRight.
  ///
  /// In en, this message translates to:
  /// **'Align Right'**
  String get alignRight;

  /// No description provided for @alignJustify.
  ///
  /// In en, this message translates to:
  /// **'Justify'**
  String get alignJustify;

  /// No description provided for @bulletList.
  ///
  /// In en, this message translates to:
  /// **'Bullet List'**
  String get bulletList;

  /// No description provided for @numberedList.
  ///
  /// In en, this message translates to:
  /// **'Numbered List'**
  String get numberedList;

  /// No description provided for @indent.
  ///
  /// In en, this message translates to:
  /// **'Indent'**
  String get indent;

  /// No description provided for @outdent.
  ///
  /// In en, this message translates to:
  /// **'Outdent'**
  String get outdent;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get shortcuts;

  /// No description provided for @exitPresentation.
  ///
  /// In en, this message translates to:
  /// **'Exit Presentation'**
  String get exitPresentation;

  /// No description provided for @nextSlide.
  ///
  /// In en, this message translates to:
  /// **'Next Slide'**
  String get nextSlide;

  /// No description provided for @previousSlide.
  ///
  /// In en, this message translates to:
  /// **'Previous Slide'**
  String get previousSlide;

  /// No description provided for @firstSlide.
  ///
  /// In en, this message translates to:
  /// **'First Slide'**
  String get firstSlide;

  /// No description provided for @lastSlide.
  ///
  /// In en, this message translates to:
  /// **'Last Slide'**
  String get lastSlide;

  /// No description provided for @aiTools.
  ///
  /// In en, this message translates to:
  /// **'AI Tools'**
  String get aiTools;

  /// No description provided for @improveWriting.
  ///
  /// In en, this message translates to:
  /// **'Improve Writing'**
  String get improveWriting;

  /// No description provided for @fixGrammar.
  ///
  /// In en, this message translates to:
  /// **'Fix Grammar'**
  String get fixGrammar;

  /// No description provided for @makeShorter.
  ///
  /// In en, this message translates to:
  /// **'Make Shorter'**
  String get makeShorter;

  /// No description provided for @makeLonger.
  ///
  /// In en, this message translates to:
  /// **'Make Longer'**
  String get makeLonger;

  /// No description provided for @translateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to {language}'**
  String translateTo(String language);

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @generateSlides.
  ///
  /// In en, this message translates to:
  /// **'Generate Slides'**
  String get generateSlides;

  /// No description provided for @fromText.
  ///
  /// In en, this message translates to:
  /// **'From Text'**
  String get fromText;

  /// No description provided for @fromTopic.
  ///
  /// In en, this message translates to:
  /// **'From Topic'**
  String get fromTopic;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @slideCountQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many slides?'**
  String get slideCountQuestion;

  /// No description provided for @style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @casual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get casual;

  /// No description provided for @academic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get academic;

  /// No description provided for @creative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get creative;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get addFiles;

  /// No description provided for @noFiles.
  ///
  /// In en, this message translates to:
  /// **'No files'**
  String get noFiles;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fileSize;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fileType;

  /// No description provided for @uploadedAt.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedAt;

  /// No description provided for @collaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get collaboration;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @joinSession.
  ///
  /// In en, this message translates to:
  /// **'Join Session'**
  String get joinSession;

  /// No description provided for @sessionCode.
  ///
  /// In en, this message translates to:
  /// **'Session Code'**
  String get sessionCode;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @playRecording.
  ///
  /// In en, this message translates to:
  /// **'Play Recording'**
  String get playRecording;

  /// No description provided for @deleteRecording.
  ///
  /// In en, this message translates to:
  /// **'Delete Recording'**
  String get deleteRecording;

  /// No description provided for @audioRecorded.
  ///
  /// In en, this message translates to:
  /// **'Audio recorded'**
  String get audioRecorded;

  /// No description provided for @recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get recordings;

  /// No description provided for @noRecordings.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get noRecordings;

  /// No description provided for @advancedExport.
  ///
  /// In en, this message translates to:
  /// **'Advanced Export'**
  String get advancedExport;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @aspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get aspectRatio;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @exportOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get exportOptions;

  /// No description provided for @includeSpeakerNotes.
  ///
  /// In en, this message translates to:
  /// **'Include speaker notes'**
  String get includeSpeakerNotes;

  /// No description provided for @includeBackgrounds.
  ///
  /// In en, this message translates to:
  /// **'Include backgrounds'**
  String get includeBackgrounds;

  /// No description provided for @slidesToExport.
  ///
  /// In en, this message translates to:
  /// **'Slides to Export'**
  String get slidesToExport;

  /// No description provided for @allSlides.
  ///
  /// In en, this message translates to:
  /// **'All slides'**
  String get allSlides;

  /// No description provided for @selectedSlides.
  ///
  /// In en, this message translates to:
  /// **'Selected ({count})'**
  String selectedSlides(int count);

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @exportSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Export successful: {summary}'**
  String exportSuccessful(String summary);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @chooseAtLeastOneSlide.
  ///
  /// In en, this message translates to:
  /// **'Select at least one slide or choose \"All slides\".'**
  String get chooseAtLeastOneSlide;

  /// No description provided for @chooseTemplate.
  ///
  /// In en, this message translates to:
  /// **'Choose a Template'**
  String get chooseTemplate;

  /// No description provided for @htmlPreview.
  ///
  /// In en, this message translates to:
  /// **'HTML Preview:'**
  String get htmlPreview;

  /// No description provided for @useThisTemplate.
  ///
  /// In en, this message translates to:
  /// **'Use This Template'**
  String get useThisTemplate;

  /// No description provided for @clearAllSlides.
  ///
  /// In en, this message translates to:
  /// **'Clear All Slides'**
  String get clearAllSlides;

  /// No description provided for @clearAllSlidesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all {count} slides? This action cannot be undone.'**
  String clearAllSlidesMessage(int count);

  /// No description provided for @deletedAllSlides.
  ///
  /// In en, this message translates to:
  /// **'Deleted all slides'**
  String get deletedAllSlides;

  /// No description provided for @untitledPresentation.
  ///
  /// In en, this message translates to:
  /// **'Untitled Presentation'**
  String get untitledPresentation;

  /// No description provided for @hideSidebar.
  ///
  /// In en, this message translates to:
  /// **'Hide Sidebar'**
  String get hideSidebar;

  /// No description provided for @showSidebar.
  ///
  /// In en, this message translates to:
  /// **'Show Sidebar'**
  String get showSidebar;

  /// No description provided for @toggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle Theme'**
  String get toggleTheme;

  /// No description provided for @slideEditor.
  ///
  /// In en, this message translates to:
  /// **'Slide Editor'**
  String get slideEditor;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @noSlides.
  ///
  /// In en, this message translates to:
  /// **'There are no slides to present.'**
  String get noSlides;

  /// No description provided for @startCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Start collaboration'**
  String get startCollaboration;

  /// No description provided for @stopCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Stop collaboration'**
  String get stopCollaboration;

  /// No description provided for @leaveCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Leave session'**
  String get leaveCollaboration;

  /// No description provided for @hostCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Host a collaboration session'**
  String get hostCollaboration;

  /// No description provided for @hostCollaborationDescription.
  ///
  /// In en, this message translates to:
  /// **'Share the current presentation with trusted people on this local network.'**
  String get hostCollaborationDescription;

  /// No description provided for @joinCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Join a session'**
  String get joinCollaboration;

  /// No description provided for @hostOrShareLink.
  ///
  /// In en, this message translates to:
  /// **'Host IP or share link'**
  String get hostOrShareLink;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @sessionToken.
  ///
  /// In en, this message translates to:
  /// **'Session token'**
  String get sessionToken;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @collaborationHosting.
  ///
  /// In en, this message translates to:
  /// **'Hosting a protected session'**
  String get collaborationHosting;

  /// No description provided for @collaborationConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected and syncing'**
  String get collaborationConnected;

  /// No description provided for @collaborationRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision {revision}'**
  String collaborationRevision(int revision);

  /// No description provided for @collaborationParticipants.
  ///
  /// In en, this message translates to:
  /// **'Participants: {count}'**
  String collaborationParticipants(int count);

  /// No description provided for @collaborationSecurityNotice.
  ///
  /// In en, this message translates to:
  /// **'Only share the link or token with trusted people on your local network.'**
  String get collaborationSecurityNotice;

  /// No description provided for @collaborationStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the protected local server. Check the port and firewall.'**
  String get collaborationStartFailed;

  /// No description provided for @collaborationJoinFields.
  ///
  /// In en, this message translates to:
  /// **'Enter a host/share link and session token.'**
  String get collaborationJoinFields;

  /// No description provided for @collaborationJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not authenticate or connect to this session.'**
  String get collaborationJoinFailed;

  /// No description provided for @collaborationJoined.
  ///
  /// In en, this message translates to:
  /// **'Connected. Slides are now synchronized.'**
  String get collaborationJoined;

  /// No description provided for @collaborationLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Protected share link copied.'**
  String get collaborationLinkCopied;

  /// No description provided for @collaborationConflict.
  ///
  /// In en, this message translates to:
  /// **'A newer revision was found. The authoritative host version was restored.'**
  String get collaborationConflict;

  /// No description provided for @collaborationAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'The collaboration token is no longer valid.'**
  String get collaborationAuthFailed;

  /// No description provided for @slideListSemantics.
  ///
  /// In en, this message translates to:
  /// **'Slide list, {count} slides'**
  String slideListSemantics(int count);

  /// No description provided for @slideSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Slide {number}: {title}'**
  String slideSemanticLabel(int number, String title);

  /// No description provided for @slideSemanticHint.
  ///
  /// In en, this message translates to:
  /// **'Activate to edit. Long press for more actions.'**
  String get slideSemanticHint;

  /// No description provided for @workspaceSemantics.
  ///
  /// In en, this message translates to:
  /// **'GhitaPPT presentation workspace'**
  String get workspaceSemantics;
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
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
