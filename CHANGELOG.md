# Changelog

All notable changes to the Katbook EPUB Reader package will be documented in this file.

## [2.1.1] - 2026-03-06

### Bug Fixes

#### AssetManifest Compatibility
- **Fixed Flutter 3.41+ AssetManifest Issue**: Updated example app to use `AssetManifest.loadFromAssetBundle()` API instead of manually loading and decoding `AssetManifest.json`
- **Binary Manifest Support**: Now compatible with Flutter 3.16+ binary manifest format (AssetManifest.bin)
- **Removed JSON Parsing**: Eliminated manual JSON decode workaround that was causing HTTP 404 errors on web platform
- **Improved Asset Discovery**: More robust and future-proof asset loading mechanism using the official Flutter API

### Changes

#### Example App
- Updated `_getEpubAssets()` method in `lib/homepage.dart` to use modern AssetManifest API
- Removed unnecessary `dart:convert` import from example app
- Enhanced debug logging for asset enumeration

## [2.1.0] - 2026-03-05

### Features

#### Localization System
- **Full Internationalization Support**: Complete i18n system with 3 languages (English, French, Chinese)
- **Language Selector**: Built-in language menu in reader with instant switching
- **Comprehensive Translations**: All 24 UI strings translated and working across entire app
- **Dynamic Locale Management**: Language changes propagate throughout entire application
- **Unified Language Display Names**: Centralized localization display names using single static map in base `AppLocalizations` class
- **Page Indicator Translation**: Added `pageLabel` translation key for page view indicator, supporting English, French, and Chinese
- **Enhanced Localization Support**: Better language name handling with native language display (English, 中文, Français)

#### EPUB Asset Selection
- **Dynamic EPUB Loading**: Read EPUB files from `assets/` folder via AssetManifest
- **EPUB Picker Dialog**: User-friendly selection dialog for multiple EPUBs
- **Auto-Discovery**: Automatic detection of .epub files in assets folder

#### CSS & Styling Improvements
- **Full CSS Support**: Parse and apply EPUB stylesheets (colors, fonts, alignment)
- **Background Colors**: Detect and apply CSS background colors with proper contrast
- **Font Styling**: Support for bold (font-weight) and italic (font-style) from CSS
- **Removed Forced Indentation**: Eliminated artificial paragraph indentation, respecting EPUB's original styling

#### Build Fixes
- **setState Error Fix**: Resolved "setState during build" error in page viewing mode
- **Font Size Changes**: Smooth font size adjustments without build conflicts

### Changes

#### Localization System
- Removed redundant `languageEnglish`, `languageChinese`, and `languageFrench` getters from all language implementations
- Consolidated language display logic to `getLocaleDisplayName()` method in base class
- Added `pageLabel` translation for "Page" keyword used in page view
- Simplified language selector menu to use unified display names

#### Code Quality
- Improved consistency across localization implementations
- Reduced code duplication in language files
- Better separation of concerns for translation keys

## [1.0.0] - 2025-12-01

### Features

#### Core Reader
- **Full EPUB Support**: Parse and render EPUB 2 and EPUB 3 formats
- **Hierarchical Table of Contents**: Support for nested chapters at any depth with proper tree structure
- **Three Built-in Themes**: Light, Sepia, and Dark themes with seamless switching
- **Adjustable Typography**: Font size control (8-40px) with built-in slider UI
- **Reading Progress Tracking**: Real-time progress percentage and position tracking
- **Position Save/Restore**: Resume reading from where you left off with `ReadingPosition.toJson()` and `ReadingPosition.fromJson()`

#### Content Rendering
- **CSS Parsing**: Parses EPUB stylesheets for proper text alignment and styling
- **Front Matter Support**: Displays cover pages, dedication, copyright, and other pre-chapter content
- **Responsive Content Width**: Configurable `contentWidthPercent` (0.0 to 1.0) for centered, readable text columns
- **Rich HTML Rendering**: Supports headings, paragraphs, lists, blockquotes, code blocks, tables, images, and links
- **Image Handling**: Robust extraction and display of embedded EPUB images with fallback support

#### Navigation
- **Drawer-based TOC**: Slide-out table of contents with hierarchical chapter display
- **Chapter Navigation**: Jump directly to any chapter from TOC
- **Paragraph Navigation**: `jumpToParagraph()` and `scrollToParagraph()` for precise positioning

#### Controller
- `KatbookEpubController`: Manages book loading, state, and navigation
  - `openBook(Uint8List)`: Load EPUB from bytes
  - `tableOfContents`: Hierarchical chapter list
  - `flatChapters`: Flat list of all chapters
  - `paragraphs`: All parsed paragraphs
  - `imageData`: Extracted images as `Map<String, Uint8List>`
  - `currentPosition`: Current reading position
  - `positionStream`: Stream of position changes

#### Customization
- Custom builders for: loading, error, chapter headers, paragraphs, images, and TOC
- Custom AppBar support via `appBarBuilder`
- Callbacks: `onPositionChanged`, `onChapterChanged`, `onProgressChanged`

### Dependencies
- `epubx` ^4.0.0 - EPUB parsing
- `html` ^0.15.6 - HTML DOM parsing  
- `scrollable_positioned_list` ^0.3.8 - Efficient virtualized scrolling
- `collection` ^1.19.1 - Collection utilities
