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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = const Locale('en'); // Default to english
  }

  void _setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

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
      // IMPORTANT: Internationalization support is REQUIRED for proper tooltip display.
      // Without these delegates, all tooltips will show as "Menu" instead of localized text.
      // When using KatbookEpubReader in your own app, you MUST add these two lines:
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      // Wrap with FocusScope to prevent focus-related errors on web
      builder: (context, child) {
        return FocusScope(
          autofocus: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomePage(onLocaleChanged: _setLocale),
    );
  }
}
