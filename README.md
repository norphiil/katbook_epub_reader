# Katbook EPUB Reader

[![GitHub](https://img.shields.io/badge/GitHub-norphiil%2Fkatbook__epub__reader-blue?logo=github)](https://github.com/norphiil/katbook_epub_reader)
[![pub package](https://img.shields.io/pub/v/katbook_epub_reader.svg)](https://pub.dev/packages/katbook_epub_reader)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful, customizable EPUB reader widget for Flutter with proper hierarchical chapter support, theme customization, reading progress tracking, and robust image handling.

## Features

- 📚 **Full EPUB Support** - Proper parsing of EPUB 2 and EPUB 3 formats
- 📖 **Hierarchical Table of Contents** - Support for nested chapters at any depth
- 🎨 **Built-in Themes** - Light, Sepia, and Dark themes out of the box
- 🔤 **Customizable Typography** - Adjustable font size with slider control
- 📍 **Reading Progress** - Precise position tracking and percentage progress
- 💾 **Position Save/Restore** - Resume reading from where you left off
- 🖼️ **Image Handling** - Robust extraction and display of embedded images
- 📐 **Responsive Layout** - Configurable content width (percentage-based)
- 🎯 **CSS Support** - Parses EPUB stylesheets for proper text alignment and styling
- 📄 **Front Matter Support** - Displays cover, dedication, and other pre-chapter content

## Installation

Add `katbook_epub_reader` to your `pubspec.yaml`:

```yaml
dependencies:
  katbook_epub_reader: ^1.0.0
```

Or run this command in your terminal:

```bash
flutter pub add katbook_epub_reader
```

Then import it in your Dart code:

```dart
import 'package:katbook_epub_reader/katbook_epub_reader.dart';
```

## Dependencies

- **epubx** ^4.0.0 - EPUB parsing
- **html** ^0.15.6 - HTML DOM parsing
- **scrollable_positioned_list** ^0.3.8 - Efficient list scrolling
- **collection** ^1.19.1 - Collection utilities

## Getting Started

To quicly get started create a file to hold your reader and paste in the boilerplate code below:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:katbook_epub_reader/katbook_epub_reader.dart';

class EpubReaderScreen extends StatefulWidget {
  /// Raw bytes of the EPUB file to load. Takes priority over [url] and [assetPath].
  final Uint8List? epubBytes;

  /// A URL pointing to a remote EPUB file to download and display.
  /// Takes priority over [assetPath] but not [epubBytes].
  final String? url;

  /// A Flutter asset path to an EPUB file bundled with the app
  /// (e.g. `'assets/book.epub'`). Lowest priority source.
  final String? assetPath;

  /// Called when the user closes the reader (e.g. taps the back button).
  /// Wire this to `Navigator.pop` or your own navigation logic.
  final VoidCallback? onClose;

  /// The colour theme applied to the reader on first load.
  /// Defaults to [ReaderTheme.dark]. The user can change this at runtime
  /// via the theme button in the app bar.
  final ReaderTheme initialTheme;

  /// The font size (in logical pixels) used for body text when the reader
  /// first opens. Defaults to `16.0`. Valid range is 8–40.
  final double initialFontSize;

  /// How much of the screen width the text column occupies, expressed as a
  /// fraction between 0.0 and 1.0. Defaults to `0.70` (70 %).
  /// Narrower values add more whitespace margin; wider values fill more screen.
  final double contentWidthPercent;

  /// Whether the built-in app bar (with title, progress, and action buttons)
  /// is shown. Set to `false` if you want to provide your own chrome.
  /// Defaults to `true`.
  final bool showAppBar;

// If you saved the position returned by onPositionedChanged you can pass this parameter
  final ReadingPosition? initialPosition;

  /// Fired every time the reader's scroll or page position changes,
  /// providing a [ReadingPosition] with the current chapter index,
  /// paragraph index, and progress percentage. Use this to persist the
  /// user's place between sessions.
  final void Function(ReadingPosition position)? onPositionChanged;

  /// Fired when the overall reading progress changes by more than 0.5 %.
  /// The [double] argument is a value between 0.0 (start) and 1.0 (end).
  final void Function(double progress)? onProgressChanged;

  /// Fired when the reader crosses into a new chapter, providing the
  /// [ChapterNode] for the chapter now on screen.
  final void Function(ChapterNode chapter)? onChapterChanged;

  /// The locale used for the reader's UI strings (app bar tooltips, theme
  /// labels, etc.). Defaults to English if not set.
  /// Currently supported: `en`, `fr`, `zh`.
  final Locale? locale;

  /// Called when the user selects a different language from the language
  /// picker in the app bar. Use this to propagate the change up to your
  /// [MaterialApp] so the rest of your app follows suit.
  final void Function(Locale locale)? onLocaleChanged;

  /// Whether the language-selector button is shown in the app bar.
  /// Defaults to `true`.
  final bool showLanguageButton;

  /// Whether the theme-selector button is shown in the app bar.
  /// Defaults to `true`.
  final bool showThemeButton;

  const EpubReaderScreen({
    super.key,
    this.epubBytes,
    this.url,
    this.assetPath,
    this.onClose,
    this.initialTheme = ReaderTheme.dark,
    this.initialFontSize = 16.0,
    this.contentWidthPercent = 0.70,
    this.showAppBar = true,
    this.onPositionChanged,
    this.onProgressChanged,
    this.onChapterChanged,
    this.locale,
    this.onLocaleChanged,
    this.showLanguageButton = true,
    this.showThemeButton = true,
  }) : assert(
         epubBytes != null || url != null || assetPath != null,
         'At least one of epubBytes, url, or assetPath must be provided',
       );

  @override
  State<EpubReaderScreen> createState() => EpubReaderScreenState();
}

class EpubReaderScreenState extends State<EpubReaderScreen> {
  final KatbookEpubController _controller = KatbookEpubController();
  final GlobalKey<KatbookEpubReaderState> _readerKey =
      GlobalKey<KatbookEpubReaderState>();
  bool _isLoading = true;
  String? _error;

  KatbookEpubController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Uint8List? bytes;

      if (widget.epubBytes != null) {
        bytes = widget.epubBytes;
        debugPrint('📂 Loading EPUB from bytes (${bytes!.length} bytes)');
      } else if (widget.url != null) {
        debugPrint('📥 Downloading EPUB from: ${widget.url}');
        final response = await http.get(Uri.parse(widget.url!));

        if (response.statusCode != 200) {
          throw Exception('Failed to download: HTTP ${response.statusCode}');
        }

        bytes = response.bodyBytes;

        if (bytes.isEmpty) {
          throw Exception('Downloaded file is empty');
        }

        debugPrint('✅ Downloaded ${bytes.length} bytes');
      } else if (widget.assetPath != null) {
        debugPrint('📂 Loading EPUB from assets: ${widget.assetPath}');
        final byteData = await rootBundle.load(widget.assetPath!);
        bytes = byteData.buffer.asUint8List();
      }

      if (bytes == null) {
        throw Exception('No EPUB source provided');
      }

      final success = await _controller.openBook(bytes);

      if (!success) {
        throw Exception(_controller.loadingError ?? 'Failed to parse EPUB');
      }

      debugPrint('✅ EPUB loaded: ${_controller.title}');
    } catch (e) {
      debugPrint('❌ Error: $e');
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> reload() => _loadEpub();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Loading...'),
                leading: widget.onClose != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      )
                    : null,
              )
            : null,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading EPUB...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Error'),
                leading: widget.onClose != null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.onClose,
                      )
                    : null,
              )
            : null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading EPUB',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadEpub,
                  child: const Text('Try Again'),
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Go Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return KatbookEpubReader(
      key: _readerKey,
      controller: _controller,
      initialTheme: widget.initialTheme,
      initialFontSize: widget.initialFontSize,
      contentWidthPercent: widget.contentWidthPercent,
      showAppBar: widget.showAppBar,
      locale: widget.locale,
      showLanguageButton: widget.showLanguageButton,
      showThemeButton: widget.showThemeButton,
      onPositionChanged: widget.onPositionChanged ?? (position) {
        debugPrint(
          '📖 Position: Chapter ${position.chapterIndex}, '
          'Paragraph ${position.paragraphIndex}/${position.totalParagraphs}, '
          'Progress: ${position.progressPercent.toStringAsFixed(1)}%',
        );
      },
      onProgressChanged: widget.onProgressChanged ?? (progress) {
        debugPrint('📊 Progress: ${(progress * 100).toStringAsFixed(1)}%');
      },
      onChapterChanged: widget.onChapterChanged ?? (chapter) {
        debugPrint('📑 Chapter: ${chapter.title} (Depth: ${chapter.depth})');
      },
      onLocaleChanged: widget.onLocaleChanged ?? (locale) {
        debugPrint('🌐 Language changed to: ${locale.languageCode}');
      },
    );
  }
}
```

The reader's built-in UI strings (tooltips, theme labels, etc.) are localised.
Add the required delegates to your `MaterialApp` — **without them, all tooltips
will display as "Menu"**.  So add this to your main.dart file. (Or wherever the entry point to your programme is):

```dart
import 'package:katbook_epub_reader/katbook_epub_reader.dart';

MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
)
```

Currently supported locales: `en` (English), `fr` (Français), `zh` (中文).

Finally you can import your reader and pass it an EPUB file. For example, for an EPUB hosted at a URL:

```dart
class Reader extends StatelessWidget {
  const Reader({super.key, required this.epub});

  final String epub;

  @override
  Widget build(BuildContext context) {
    return EpubReaderScreen(url: epub);
  }
}
```

The `KatBookEpubReader` widget and by extension `EpubReaderScreen` accepts three mutually exclusive source types — pass exactly one:

| Parameter | Type | Description |
|-----------|------|-------------|
| `url` | `String` | A remote URL; the file is downloaded at runtime. |
| `epubBytes` | `Uint8List` | Raw bytes, e.g. from a local file picker or cached download. |
| `assetPath` | `String` | A Flutter asset path such as `'assets/book.epub'`. |

### Loading from a local file on the device

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// Assuming you put the boilerplate in a file named reader.dart
import './reader.dart';

class Reader extends StatelessWidget {
  const Reader({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    // Read the file synchronously and pass the bytes directly.
    final Uint8List epubBytes = File(path).readAsBytesSync();
    return EpubReaderScreen(epubBytes: epubBytes);
  }
}
```

> **Note:** `readAsBytesSync` blocks the UI thread. For large files, prefer
> `readAsBytes()` inside a `FutureBuilder` or load the bytes before navigating
> to the reader screen.

### Persisting and restoring reading position

`onPositionChanged` fires whenever the user scrolls or turns a page and gives
you a `ReadingPosition` object that can be serialised to JSON:

```dart
EpubReaderScreen(
  url: myBookUrl,
  onPositionChanged: (position) async {
    //or your preferred storage method
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_position', jsonEncode(position.toJson()));
  },
)
```

To restore it on next launch, pass an `initialPosition` directly to
`KatbookEpubReader` (or call `controller.jumpToPosition(position)` after the
book has loaded).


### Persisting and restoring reading mode

`onPositionChanged` fires whenever the user changes the reading mode, (scroll or paginated). Returns a `ReadingMode` object that can be serialised to JSON:

```dart
EpubReaderScreen(
  url: myBookUrl,
  onReadingModeChanged: (mode) async {
    //or your preferred storage method
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_reading_mode', jsonEncode(mode.toJson()));
  },
)
```

To restore it on next launch, pass an `initialReadingMode` to
`KatbookEpubReader` 


### Tracking progress

`onProgressChanged` receives a `double` between `0.0` and `1.0` and fires when
progress changes by more than 0.5 %, making it efficient to use for a progress
bar without excessive rebuilds:

```dart
EpubReaderScreen(
  url: myBookUrl,
  onProgressChanged: (progress) {
    setState(() => _readingProgress = progress);
  },
)
```

### Reacting to chapter changes

`onChapterChanged` fires whenever the reader scrolls into a new chapter,
providing the full `ChapterNode` (title, depth, start index):

```dart
EpubReaderScreen(
  url: myBookUrl,
  onChapterChanged: (chapter) {
    print('Now reading: ${chapter.title} (depth ${chapter.depth})');
  },
)
```

---
### Paramters 

The full list of paramters taken by the KatBookEpub reader Widget

```dart 
/// The controller that manages the EPUB book.
  final KatbookEpubController controller;

  /// The initial theme to use.
  final ReaderTheme initialTheme;

  /// The initial font size.
  final double initialFontSize;

  /// Whether to show the built-in app bar.
  final bool showAppBar;

  /// Builder for a custom app bar.
  final PreferredSizeWidget Function(BuildContext context, KatbookEpubReaderState state)? appBarBuilder;

  /// Called when the reading position changes. 
  final void Function(ReadingPosition position)? onPositionChanged;

  /// Called when the current chapter changes.
  final void Function(ChapterNode chapter)? onChapterChanged;

  /// Called when the progress percentage changes.
  final void Function(double progress)? onProgressChanged;

  /// Called when the reading mode changes. 
  final void Function(ReadingMode mode)? onReadingModeChanged;

  /// The initial reading mode (scroll or page).
  final ReadingMode initialReadingMode;

  /// Builder for the loading indicator.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for error display.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builder for custom table of contents.
  final Widget Function(BuildContext context, List<ChapterNode> chapters, void Function(ChapterNode) onTap)? tocBuilder;

  /// Builder for chapter headers.
  final Widget Function(BuildContext context, ChapterNode chapter)? chapterHeaderBuilder;

  /// Builder for paragraph content.
  final Widget Function(BuildContext context, ParagraphElement paragraph, ReaderThemeData theme, double fontSize)? paragraphBuilder;

  /// Builder for image loading errors.
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? imageErrorBuilder;

  /// Padding around each paragraph.
  final EdgeInsets padding;

  /// Scroll physics for the content.
  final ScrollPhysics? scrollPhysics;

  /// Initial reading position to restore.
  final ReadingPosition? initialPosition;

  /// Width of the content area as a percentage of screen width (0.0 to 1.0).
  /// Content will be centered. Defaults to 0.65 (65% of screen width).
  final double contentWidthPercent;

  /// The locale to use for localization. If null, uses the system locale.
  final Locale? locale;

  /// Called when the locale changes.
  final void Function(Locale locale)? onLocaleChanged;

  /// Whether to show the language selector button in the app bar.
  final bool showLanguageButton;

  /// Whether to show the theme selector button in the app bar.
  final bool showThemeButton;
```

## Example App

See the `example/` directory for a complete, runnable example application.

## Comparison with epub_view

| Feature | katbook_epub_reader | epub_view |
|---------|---------------------|-----------|
| Hierarchical TOC | ✅ Any depth | ❌ Flat only |
| CSS Parsing | ✅ Full support | ❌ Limited |
| Front Matter | ✅ Supported | ❌ No |
| Theme System | ✅ 3 built-in | ✅ Basic |
| Font Size Slider | ✅ Built-in | ❌ Manual |
| Position Save/Restore | ✅ Full | ⚠️ Limited |
| Content Width Control | ✅ Percentage-based | ❌ No |
| Image Handling | ✅ Robust | ⚠️ Basic |

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to the repository.
