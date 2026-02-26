import 'app_localizations.dart';

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr() : super('fr');

  @override
  String get appBarTitleDefault => 'Lecteur EPUB';

  @override
  String get tooltipBack => 'Retour';

  @override
  String get tooltipTableOfContents => 'Table des matières';

  @override
  String get tooltipFontSize => 'Taille de police';

  @override
  String get tooltipReadingMode => 'Mode de lecture';

  @override
  String get tooltipTheme => 'Thème';

  @override
  String get readingModeScroll => 'Mode défilement';

  @override
  String get readingModePage => 'Mode page';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeSepia => 'Sépia';

  @override
  String get themeDark => 'Sombre';

  @override
  String get loadingBook => 'Chargement du livre...';

  @override
  String get errorLoadingTitle => 'Erreur de chargement';

  @override
  String get noBookLoaded => 'Aucun livre chargé';

  @override
  String get bookEmpty => 'Le livre n\'a pas de contenu';

  @override
  String get sectionsCount => 'sections';

  @override
  String get fontSizeDecrease => 'Réduire la police';

  @override
  String get fontSizeIncrease => 'Augmenter la police';

  @override
  String get tooltipLanguage => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageChinese => 'Chinois';

  @override
  String getLocaleDisplayName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Anglais';
      case 'zh':
        return 'Chinois';
      case 'fr':
        return 'Français';
      default:
        return languageCode;
    }
  }
}
