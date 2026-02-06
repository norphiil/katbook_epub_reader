import 'package:flutter/material.dart';

/// Theme options for the EPUB reader.
///
/// Three built-in themes are provided:
/// - [light]: White background with dark text
/// - [sepia]: Warm paper-like background
/// - [dark]: Dark background with light text
enum ReaderTheme {
  /// Light theme - clean white background
  light,

  /// Sepia theme - warm, paper-like appearance
  sepia,

  /// Dark theme - easy on the eyes in low light
  dark,
}

/// Configuration for a reader theme.
class ReaderThemeData {
  /// Background color of the reader
  final Color backgroundColor;

  /// Primary text color
  final Color textColor;

  /// Accent color for highlights and UI elements
  final Color accentColor;

  /// Secondary text color (for subtitles, hints)
  final Color secondaryTextColor;

  /// Color for links
  final Color linkColor;

  /// Color for the app bar
  final Color appBarColor;

  /// Display name for the theme
  final String displayName;

  const ReaderThemeData({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.secondaryTextColor,
    required this.linkColor,
    required this.appBarColor,
    required this.displayName,
  });

  /// Whether this is a dark theme
  bool get isDark => backgroundColor.computeLuminance() < 0.5;

  /// Get the theme data for a given theme type.
  static ReaderThemeData fromTheme(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.light:
        return const ReaderThemeData(
          backgroundColor: Color(0xFFFFFFF8),
          textColor: Color(0xFF1A1A1A),
          accentColor: Color(0xFF2563EB),
          secondaryTextColor: Color(0xFF6B7280),
          linkColor: Color(0xFF2563EB),
          appBarColor: Color(0xFFFFFFF8),
          displayName: 'Clair',
        );
      case ReaderTheme.sepia:
        return const ReaderThemeData(
          backgroundColor: Color(0xFFD4C4A8), // Warmer, darker sepia
          textColor: Color(0xFF1A1A1A), // Black text for better readability
          accentColor: Color(0xFF8B5A2B), // Warm brown accent
          secondaryTextColor: Color(0xFF5C4B37), // Muted brown
          linkColor: Color(0xFF8B5A2B),
          appBarColor: Color(0xFFC4B494), // Slightly darker app bar
          displayName: 'Sépia',
        );
      case ReaderTheme.dark:
        return const ReaderThemeData(
          backgroundColor: Color(0xFF04060F),
          textColor: Color(0xFFE8DCC8),
          accentColor: Color(0xFFD4A574),
          secondaryTextColor: Color(0xFF9CA3AF),
          linkColor: Color(0xFFD4A574),
          appBarColor: Color(0xFF1A1A2E),
          displayName: 'Sombre',
        );
    }
  }

  /// All available themes as a list.
  static List<ReaderTheme> get allThemes => ReaderTheme.values;
}
