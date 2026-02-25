import 'package:flutter/material.dart';
import 'package:katbook_epub_reader/katbook_epub_reader.dart';

import 'homepage.dart';

/// Example of how to use the Katbook EPUB Reader package.
///
/// This example demonstrates:
/// - Loading EPUB from network URL
/// - Loading EPUB from assets
/// - Full reader with all callbacks
/// - Position tracking and restoration
/// - Internationalization (i18n) support
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
      // Internationalization support
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'), // Default to French (original project language), change to Locale('en') for English or Locale('zh') for Chinese
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
