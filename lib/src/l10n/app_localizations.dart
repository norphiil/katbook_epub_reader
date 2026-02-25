import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the app bar when no book title is available
  String get appBarTitleDefault;

  /// Tooltip for the back button
  String get tooltipBack;

  /// Tooltip for the table of contents button
  String get tooltipTableOfContents;

  /// Tooltip for the font size button
  String get tooltipFontSize;

  /// Tooltip for the reading mode button
  String get tooltipReadingMode;

  /// Tooltip for the theme button
  String get tooltipTheme;

  /// Label for scroll reading mode
  String get readingModeScroll;

  /// Label for page reading mode
  String get readingModePage;

  /// Label for light theme
  String get themeLight;

  /// Label for sepia theme
  String get themeSepia;

  /// Label for dark theme
  String get themeDark;

  /// Loading message displayed when book is loading
  String get loadingBook;

  /// Error title when book fails to load
  String get errorLoadingTitle;

  /// Message displayed when no book is loaded
  String get noBookLoaded;

  /// Message displayed when book has no content
  String get bookEmpty;

  /// Label for sections in table of contents
  String get sectionsCount;

  /// Label for font size decrease button
  String get fontSizeDecrease;

  /// Label for font size increase button
  String get fontSizeIncrease;

  /// Tooltip for the language button
  String get tooltipLanguage;

  /// Label for English language
  String get languageEnglish;

  /// Label for Chinese language
  String get languageChinese;

  /// Get the display name for a locale
  String getLocaleDisplayName(String languageCode);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". '
      'This is likely an issue with the localizations generation tool. '
      'Please file an issue on GitHub with a reproducible sample app and the '
      'gen-l10n configuration that was used.');
}

/// A fake [Intl] class to avoid importing the full intl package
class Intl {
  static String canonicalizedLocale(String locale) {
    return locale;
  }
}
