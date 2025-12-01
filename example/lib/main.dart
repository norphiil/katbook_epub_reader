import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:katbook_epub_reader/katbook_epub_reader.dart';

/// Example of how to use the Katbook EPUB Reader package.
/// 
/// This example demonstrates:
/// - Loading EPUB from network URL
/// - Loading EPUB from assets
/// - Full reader with all callbacks
/// - Position tracking and restoration
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katbook EPUB Reader Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.dark,
      // Wrap with FocusScope to prevent focus-related errors on web
      builder: (context, child) {
        return FocusScope(
          autofocus: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final KatbookEpubController _controller = KatbookEpubController();
  final GlobalKey<KatbookEpubReaderState> _readerKey =
      GlobalKey<KatbookEpubReaderState>();
  bool _isLoading = false;
  String? _error;

  // Example URLs for public domain EPUB books
  static const String _exampleUrl =
      'https://www.example.url';

  /// Load EPUB from a network URL
  Future<void> _loadFromUrl(String url) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('📥 Downloading EPUB from: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }

      final epubBytes = response.bodyBytes;
      if (epubBytes.isEmpty) {
        throw Exception('Downloaded file is empty');
      }

      debugPrint('✅ Downloaded ${epubBytes.length} bytes');

      final success = await _controller.openBook(epubBytes);
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

  /// Load EPUB from assets (bundle)
  /// 
  /// To use this, add your EPUB file to pubspec.yaml:
  /// ```yaml
  /// flutter:
  ///   assets:
  ///     - assets/books/my_book.epub
  /// ```
  Future<void> _loadFromAssets(String assetPath) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('📂 Loading EPUB from assets: $assetPath');
      final byteData = await rootBundle.load(assetPath);
      final epubBytes = byteData.buffer.asUint8List();

      final success = await _controller.openBook(epubBytes);
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

  /// Load EPUB from Uint8List bytes directly
  Future<void> loadFromBytes(Uint8List epubBytes) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await _controller.openBook(epubBytes);
      if (!success) {
        throw Exception(_controller.loadingError ?? 'Failed to parse EPUB');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Downloading and parsing EPUB...'),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
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
                  onPressed: () => setState(() => _error = null),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show home screen with load options
    if (!_controller.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Katbook EPUB Reader')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.menu_book, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Katbook EPUB Reader',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A powerful Flutter EPUB reader with hierarchical chapter support',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Load from assets button
                ElevatedButton.icon(
                  onPressed: () => _loadFromAssets('assets/example.epub'),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Load example Epub (from assets)'),
                ),
                const SizedBox(height: 12),

                // Load from URL button (may fail due to CORS on web)
                ElevatedButton.icon(
                  onPressed: () => _loadFromUrl(_exampleUrl),
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Load from URL (desktop only)'),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Or integrate in your app with:\ncontroller.openBook(epubBytes)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show the EPUB reader
    return KatbookEpubReader(
      key: _readerKey,
      controller: _controller,
      
      // Theme and font settings
      initialTheme: ReaderTheme.dark,
      initialFontSize: 16.0,
      
      // Layout settings
      contentWidthPercent: 0.70, // 70% of screen width, centered
      showAppBar: true,
      
      // Callbacks for tracking
      onPositionChanged: (position) {
        debugPrint(
          '📖 Position: Chapter ${position.chapterIndex}, '
          'Paragraph ${position.paragraphIndex}/${position.totalParagraphs}, '
          'Progress: ${position.progressPercent.toStringAsFixed(1)}%',
        );
        // Save position to persistent storage here
        // Example: prefs.setString('position', position.paragraphIndex.toString());
      },
      onProgressChanged: (progress) {
        debugPrint('📊 Progress: ${(progress * 100).toStringAsFixed(1)}%');
      },
      onChapterChanged: (chapter) {
        debugPrint('📑 Chapter: ${chapter.title} (Depth: ${chapter.depth})');
      },
    );
  }
}
