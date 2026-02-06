import 'package:flutter/material.dart';

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
  const HomePage({super.key});

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
                onPressed: () => _openReader(
                  context,
                  assetPath: 'assets/example.epub',
                ),
                icon: const Icon(Icons.menu_book),
                label: const Text('Load example Epub (from assets)'),
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
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
