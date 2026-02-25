import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appBarTitleDefault => 'EPUB Reader';

  @override
  String get tooltipBack => 'Back';

  @override
  String get tooltipTableOfContents => 'Table of Contents';

  @override
  String get tooltipFontSize => 'Font Size';

  @override
  String get tooltipReadingMode => 'Reading Mode';

  @override
  String get tooltipTheme => 'Theme';

  @override
  String get readingModeScroll => 'Scroll Mode';

  @override
  String get readingModePage => 'Page Mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeDark => 'Dark';

  @override
  String get loadingBook => 'Loading book...';

  @override
  String get errorLoadingTitle => 'Error loading book';

  @override
  String get noBookLoaded => 'No book loaded';

  @override
  String get bookEmpty => 'Book has no content';

  @override
  String get sectionsCount => 'sections';

  @override
  String get fontSizeDecrease => 'Decrease font size';

  @override
  String get fontSizeIncrease => 'Increase font size';
}
