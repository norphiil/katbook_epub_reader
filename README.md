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

- **epubx_kuebiko** ^4.2.1 - EPUB parsing
- **html** ^0.15.6 - HTML DOM parsing
- **scrollable_positioned_list** ^0.3.8 - Efficient list scrolling
- **collection** ^1.19.1 - Collection utilities
- **google_fonts** ^8.0.2 - Custom fonts for better typography
- **intl** ^0.20.2 - Internationalization support
- **flutter_localizations** - Flutter localization framework

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
