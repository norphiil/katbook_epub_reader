import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reader.dart';

/// Page d'accueil de démonstration pour l'exemple.
/// 
/// Cette page est uniquement utilisée pour l'exemple/tutoriel.
/// Elle permet de sélectionner une source d'EPUB et de naviguer
/// vers le reader.
/// 
/// Dans votre application, vous pouvez directement utiliser
/// [EpubReaderScreen] sans passer par cette page.
class HomePage extends StatelessWidget {
  final void Function(Locale)? onLocaleChanged;

  const HomePage({
    super.key,
    this.onLocaleChanged,
  });

  // Example URLs for public domain EPUB books
  static const String _exampleUrl = 'https://www.example.url';

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => _selectAndOpenEpub(context),
                icon: const Icon(Icons.menu_book),
                label: const Text('Select epub from assets'),
              ),
              const SizedBox(height: 12),

              // Load from URL button (may fail due to CORS on web)
              ElevatedButton.icon(
                onPressed: () => _openReader(
                  context,
                  url: _exampleUrl,
                ),
                icon: const Icon(Icons.cloud_download),
                label: const Text('Load from URL (desktop only)'),
              ),

              const SizedBox(height: 24),
              const Text(
                'Or integrate in your app with:\nEpubReaderScreen(epubBytes: bytes)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// List all EPUB files available in the assets folder.
  Future<List<String>> _getEpubAssets() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();
      final epubFiles = <String>[];

      debugPrint('📄 Total assets count: ${allAssets.length}');

      for (final assetPath in allAssets) {
        if (assetPath.startsWith('assets/') && assetPath.endsWith('.epub')) {
          final filename = assetPath.split('/').last;
          epubFiles.add(filename);
          debugPrint('✅ Found EPUB: $filename (path: $assetPath)');
        }
      }

      debugPrint('📚 Total EPUBs found: ${epubFiles.length}');
      return epubFiles;
    } catch (e) {
      debugPrint('❌ Error reading AssetManifest: $e');
      return [];
    }
  }

  /// Show dialog to select and open an EPUB from assets
  Future<void> _selectAndOpenEpub(BuildContext context) async {
    final epubFiles = await _getEpubAssets();

    if (!context.mounted) return;

    if (epubFiles.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No EPUB files found'),
          content: const Text(
            'No EPUB files found in the assets folder.\n\n'
            '1. Add .epub files to the example/assets/ directory\n'
            '2. Run: flutter pub get\n'
            '3. Try again'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select EPUB'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: epubFiles
                .map(
                  (file) => ListTile(
                    title: Text(file),
                    leading: const Icon(Icons.book),
                    onTap: () => Navigator.pop(context, file),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && context.mounted) {
      _openReader(
        context,
        assetPath: 'assets/$selected',
      );
    }
  }

  void _openReader(
    BuildContext context, {
    String? assetPath,
    String? url,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EpubReaderScreen(
          assetPath: assetPath,
          url: url,
          onLocaleChanged: onLocaleChanged,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
