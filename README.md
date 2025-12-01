# Katbook EPUB Reader

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

## Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:katbook_epub_reader/katbook_epub_reader.dart';
import 'dart:typed_data';

class EpubReaderScreen extends StatefulWidget {
  final Uint8List epubBytes;

  const EpubReaderScreen({super.key, required this.epubBytes});

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late KatbookEpubController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = KatbookEpubController();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final success = await _controller.openBook(widget.epubBytes);
    if (!success) {
      _error = _controller.loadingError ?? 'Failed to load EPUB';
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    return KatbookEpubReader(
      controller: _controller,
      initialTheme: ReaderTheme.dark,
      initialFontSize: 18.0,
    );
  }
}
```

## Detailed Usage

### Controller

The `KatbookEpubController` manages the EPUB book state:

```dart
final controller = KatbookEpubController();

// Open a book from bytes
await controller.openBook(epubBytes);

// Access book metadata
print(controller.title);       // Book title
print(controller.author);      // Author name
print(controller.isLoaded);    // Loading state

// Access content
final chapters = controller.tableOfContents;  // Hierarchical TOC
final flatChapters = controller.flatChapters; // Flat list of all chapters
final paragraphs = controller.paragraphs;     // All paragraphs

// Access images
final images = controller.imageData; // Map<String, Uint8List>

// Navigate
controller.jumpToIndex(100); // Jump to paragraph index

// Get current position
final position = controller.currentPosition;

// Clean up
controller.dispose();
```

### Widget Configuration

The `KatbookEpubReader` widget offers extensive customization:

```dart
KatbookEpubReader(
  // Required
  controller: controller,
  
  // Theme options
  initialTheme: ReaderTheme.light,    // light, sepia, or dark
  initialFontSize: 16.0,              // Font size in pixels (10-40)
  
  // Layout
  contentWidthPercent: 0.65,          // 65% of screen width, centered
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  
  // App bar
  showAppBar: true,                   // Show built-in app bar
  appBarBuilder: null,                // Custom app bar builder
  
  // Callbacks
  onPositionChanged: (position) {
    // Called when reading position changes
    print('Chapter: ${position.chapterIndex}');
    print('Paragraph: ${position.paragraphIndex}');
    print('Progress: ${position.progressPercent}%');
  },
  onChapterChanged: (chapter) {
    // Called when entering a new chapter
    print('Now reading: ${chapter.title}');
  },
  onProgressChanged: (progress) {
    // Called when progress percentage changes
    print('Progress: ${(progress * 100).toStringAsFixed(1)}%');
  },
  
  // Custom builders
  loadingBuilder: (context) => CircularProgressIndicator(),
  errorBuilder: (context, error) => Text('Error: $error'),
  chapterHeaderBuilder: (context, chapter) => MyChapterHeader(chapter),
  paragraphBuilder: (context, paragraph, theme, fontSize) => MyParagraph(...),
  imageErrorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
  tocBuilder: (context, chapters, onTap) => MyTableOfContents(...),
  
  // Restore position
  initialPosition: savedPosition,
  
  // Scroll behavior
  scrollPhysics: BouncingScrollPhysics(),
)
```

### Themes

Three built-in themes are available:

```dart
// Light theme - white background, black text
KatbookEpubReader(
  controller: controller,
  initialTheme: ReaderTheme.light,
)

// Sepia theme - warm paper-like background
KatbookEpubReader(
  controller: controller,
  initialTheme: ReaderTheme.sepia,
)

// Dark theme - dark background, light text
KatbookEpubReader(
  controller: controller,
  initialTheme: ReaderTheme.dark,
)
```

#### Programmatic Theme Control

Access the reader state to control theme programmatically:

```dart
final readerKey = GlobalKey<KatbookEpubReaderState>();

KatbookEpubReader(
  key: readerKey,
  controller: controller,
)

// Change theme
readerKey.currentState?.setTheme(ReaderTheme.dark);

// Cycle through themes
readerKey.currentState?.cycleTheme();

// Change font size
readerKey.currentState?.setFontSize(20.0);
readerKey.currentState?.increaseFontSize(2.0);
readerKey.currentState?.decreaseFontSize(2.0);

// Toggle font slider
readerKey.currentState?.toggleFontSlider();

// Navigate
readerKey.currentState?.jumpToChapter(chapter);
readerKey.currentState?.jumpToParagraph(50);
readerKey.currentState?.scrollToParagraph(50, duration: Duration(milliseconds: 500));

// Table of contents
readerKey.currentState?.showTableOfContents();
readerKey.currentState?.hideTableOfContents();
```

### Reading Position

Save and restore reading positions:

```dart
// Get current position from controller
final position = controller.currentPosition;

// Or from reader state
final position = readerKey.currentState?.getCurrentPosition();

if (position != null) {
  // Convert to JSON for storage
  final json = position.toJson();
  // json = {
  //   'chapterIndex': 2,
  //   'paragraphIndex': 45,
  //   'chapterTitle': 'Chapter 3',
  //   'totalParagraphs': 500,
  //   'paragraphOffset': 0.0
  // }
  await prefs.setString('reading_position', jsonEncode(json));
}

// Restore position from storage
final savedJson = await prefs.getString('reading_position');
if (savedJson != null) {
  final restoredPosition = ReadingPosition.fromJson(jsonDecode(savedJson));
  
  // Jump to restored position after book loads
  WidgetsBinding.instance.addPostFrameCallback((_) {
    readerKey.currentState?.jumpToParagraph(restoredPosition.paragraphIndex);
  });
}

// Position properties
print(position.chapterIndex);      // Current chapter index
print(position.paragraphIndex);    // Current paragraph index
print(position.chapterTitle);      // Current chapter title (nullable)
print(position.totalParagraphs);   // Total paragraphs in book
print(position.progressPercent);   // Reading progress (0-100)
print(position.isAtStart);         // True if at beginning
print(position.isAtEnd);           // True if at end
```

### Table of Contents

The hierarchical table of contents is available via the controller:

```dart
final toc = controller.tableOfContents;

void printChapters(List<ChapterNode> chapters, [int indent = 0]) {
  for (final chapter in chapters) {
    print('${'  ' * indent}${chapter.title}');
    print('${'  ' * indent}  Start index: ${chapter.startIndex}');
    print('${'  ' * indent}  End index: ${chapter.endIndex}');
    
    if (chapter.children.isNotEmpty) {
      printChapters(chapter.children, indent + 1);
    }
  }
}

printChapters(toc);
```

### Custom Table of Contents Widget

```dart
KatbookEpubReader(
  controller: controller,
  tocBuilder: (context, chapters, onChapterTap) {
    return ListView.builder(
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ListTile(
          title: Text(chapter.title),
          leading: Text('${index + 1}'),
          onTap: () => onChapterTap(chapter),
        );
      },
    );
  },
)
```

### Content Width

Control the content width as a percentage of the screen:

```dart
// Content takes 65% of screen width, centered (default)
KatbookEpubReader(
  controller: controller,
  contentWidthPercent: 0.65,
)

// Full width
KatbookEpubReader(
  controller: controller,
  contentWidthPercent: 1.0,
)

// Narrow column (50%)
KatbookEpubReader(
  controller: controller,
  contentWidthPercent: 0.50,
)
```

### Accessing Images

Images embedded in the EPUB are automatically extracted:

```dart
// Access all images
final images = controller.imageData; // Map<String, Uint8List>

// Display an image
if (images.containsKey('cover.jpg')) {
  Image.memory(images['cover.jpg']!);
}
```

## Architecture

### Package Structure

```
lib/
├── katbook_epub_reader.dart      # Main library export
└── src/
    ├── controller/
    │   └── katbook_epub_controller.dart  # Book state management
    ├── models/
    │   ├── chapter_node.dart             # Chapter hierarchy model
    │   ├── paragraph_element.dart        # Paragraph content model
    │   ├── reader_theme.dart             # Theme definitions
    │   └── reading_position.dart         # Position tracking model
    ├── parser/
    │   ├── parser.dart                   # Parser exports
    │   ├── content_parser.dart           # EPUB content parsing
    │   ├── css_parser.dart               # CSS stylesheet parsing
    │   ├── html_parser.dart              # HTML element parsing
    │   └── image_extractor.dart          # Image extraction
    └── widgets/
        ├── katbook_epub_reader.dart      # Main reader widget
        ├── epub_content_renderer.dart    # Content rendering
        └── table_of_contents.dart        # TOC widget
```

### Key Classes

| Class | Description |
|-------|-------------|
| `KatbookEpubController` | Manages book loading, state, and navigation |
| `KatbookEpubReader` | Main widget that displays the EPUB content |
| `ChapterNode` | Represents a chapter with its hierarchy |
| `ParagraphElement` | Represents a paragraph with its HTML element |
| `ReadingPosition` | Tracks reading position and progress |
| `ReaderTheme` / `ReaderThemeData` | Theme configuration |
| `EpubContentRenderer` | Renders individual content elements |
| `TableOfContentsWidget` | Built-in TOC drawer |

## Dependencies

- **epubx** ^4.0.0 - EPUB parsing
- **html** ^0.15.6 - HTML DOM parsing
- **scrollable_positioned_list** ^0.3.8 - Efficient list scrolling
- **collection** ^1.19.1 - Collection utilities

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

## Example App

See the `example/` directory for a complete, runnable example application.

### Minimal Example

```dart
import 'package:flutter/material.dart';
import 'package:katbook_epub_reader/katbook_epub_reader.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPUB Reader Demo',
      theme: ThemeData.dark(),
      home: const BookLoader(),
    );
  }
}

class BookLoader extends StatefulWidget {
  const BookLoader({super.key});

  @override
  State<BookLoader> createState() => _BookLoaderState();
}

class _BookLoaderState extends State<BookLoader> {
  final _controller = KatbookEpubController();
  final _readerKey = GlobalKey<KatbookEpubReaderState>();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      // Load from network
      final response = await http.get(
        Uri.parse('https://www.gutenberg.org/ebooks/84.epub.noimages'),
      );
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      
      final success = await _controller.openBook(response.bodyBytes);
      if (!success) {
        throw Exception(_controller.loadingError ?? 'Failed to parse EPUB');
      }
      
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadBook();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return KatbookEpubReader(
      key: _readerKey,
      controller: _controller,
      initialTheme: ReaderTheme.dark,
      contentWidthPercent: 0.70,
      onPositionChanged: (position) {
        debugPrint('Position: ${position.paragraphIndex}/${position.totalParagraphs}');
        // Save position for later restoration
      },
      onProgressChanged: (progress) {
        debugPrint('Progress: ${(progress * 100).toStringAsFixed(1)}%');
      },
      onChapterChanged: (chapter) {
        debugPrint('Chapter: ${chapter.title}');
      },
    );
  }
}
```

### Loading from Different Sources

```dart
// From network URL with Dio
Future<void> loadFromDio(String url, Dio dio) async {
  final response = await dio.get<Uint8List>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  final epubBytes = response.data!;
  await _controller.openBook(epubBytes);
}

// From Flutter assets
Future<void> loadFromAssets(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final epubBytes = byteData.buffer.asUint8List();
  await _controller.openBook(epubBytes);
}

// From file picker (file_picker package)
Future<void> loadFromPicker() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['epub'],
  );
  if (result != null && result.files.single.bytes != null) {
    await _controller.openBook(result.files.single.bytes!);
  }
}
```

### Restoring Reading Position

```dart
class EpubReaderWithPosition extends StatefulWidget {
  final Uint8List epubBytes;
  final int? savedParagraphIndex;
  final void Function(int paragraphIndex, String? chapterTitle) onPositionChanged;

  const EpubReaderWithPosition({
    super.key,
    required this.epubBytes,
    this.savedParagraphIndex,
    required this.onPositionChanged,
  });

  @override
  State<EpubReaderWithPosition> createState() => _EpubReaderWithPositionState();
}

class _EpubReaderWithPositionState extends State<EpubReaderWithPosition> {
  final _controller = KatbookEpubController();
  final _readerKey = GlobalKey<KatbookEpubReaderState>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    await _controller.openBook(widget.epubBytes);
    
    // Restore position after book is loaded
    if (widget.savedParagraphIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _readerKey.currentState?.jumpToParagraph(widget.savedParagraphIndex!);
      });
    }
    
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return KatbookEpubReader(
      key: _readerKey,
      controller: _controller,
      initialTheme: ReaderTheme.dark,
      onPositionChanged: (position) {
        widget.onPositionChanged(
          position.paragraphIndex,
          position.chapterTitle,
        );
      },
    );
  }
}
```
```

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to the repository.
