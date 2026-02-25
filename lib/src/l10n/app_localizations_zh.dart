import 'app_localizations.dart';

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh() : super('zh');

  @override
  String get appBarTitleDefault => 'EPUB 阅读器';

  @override
  String get tooltipBack => '返回';

  @override
  String get tooltipTableOfContents => '目录';

  @override
  String get tooltipFontSize => '字体大小';

  @override
  String get tooltipReadingMode => '阅读模式';

  @override
  String get tooltipTheme => '主题';

  @override
  String get readingModeScroll => '滚动模式';

  @override
  String get readingModePage => '翻页模式';

  @override
  String get themeLight => '浅色';

  @override
  String get themeSepia => ' sepia';

  @override
  String get themeDark => '深色';

  @override
  String get loadingBook => '正在加载书籍...';

  @override
  String get errorLoadingTitle => '加载书籍出错';

  @override
  String get noBookLoaded => '没有加载书籍';

  @override
  String get bookEmpty => '书籍没有内容';

  @override
  String get sectionsCount => '章节';

  @override
  String get fontSizeDecrease => '减小字体';

  @override
  String get fontSizeIncrease => '增大字体';
}
