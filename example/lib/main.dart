import 'package:flutter/material.dart';

import 'homepage.dart';

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
