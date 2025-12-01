# Changelog

All notable changes to the Katbook EPUB Reader package will be documented in this file.

## [0.1.0] - 2025-11-25

### Added

#### Core Features
- **Hierarchical Chapter Support**: Full support for nested chapters/subchapters at any depth
- **Three Built-in Themes**: Light, Sepia, and Dark themes with automatic luminance detection
- **Customizable Typography**: Font size adjustment (8pt-40pt) with theme-aware styling
- **Reading Progress Tracking**: Real-time progress percentage with position serialization
- **Position Restoration**: Save and restore reading position between sessions

#### Controllers
- `KatbookEpubController`: Complete EPUB lifecycle management
  - Load EPUB from bytes
  - Build hierarchical table of contents
  - Parse all paragraphs with metadata
  - Navigate between chapters and paragraphs
  - Track reading position and progress

#### Widgets
- `KatbookEpubReader`: Main reader widget with:
  - Theme switching in real-time
  - Font size adjustment UI
  - AppBar with book title and progress percentage
  - Drawer with hierarchical table of contents
  - Content area with proper HTML rendering
  
- `TableOfContentsWidget`: Drawer widget featuring:
  - Hierarchical chapter display with indentation
  - Current chapter highlighting
  - Book metadata (title, author)
  - Optional cover image display
  
- `EpubContentRenderer`: Advanced HTML renderer supporting:
  - Text formatting (bold, italic, underline, strikethrough)
  - Headings (h1-h6)
  - Lists (ordered and unordered)
  - Blockquotes and code blocks
  - Images with fallback
  - Tables with horizontal scroll
  - Links (internal and external)
  - Superscript and subscript
  - Figures and captions

#### Models
- `ReaderTheme`: Enum for three built-in themes
- `ReaderThemeData`: Theme configuration with 7 color properties
- `ChapterNode`: Hierarchical chapter representation with recursive structure
- `ReadingPosition`: Reading state tracking with progress calculation
- `ParagraphElement`: Parsed paragraph with metadata

#### Additional Features
- Robust image handling with multiple fallback strategies
- StreamController for position change notifications
- Responsive layout for all screen sizes
- Smooth scrolling with `ScrollablePositionedList`
- Position-based navigation instead of string matching
- Isolate-based EPUB parsing for non-blocking UI

### Changed
- Completely replaced `epub_view` with custom implementation
- Updated `pubspec.yaml` in main Katbook app
- Refactored `epub_reader_view.dart` to use new controller

### Removed
- Dependency on `epub_view` package
- Old epub_reader_view implementation

### Fixed
- **Chapter Ordering**: Proper hierarchical structure instead of flat list
- **Image Rendering**: No more gray blocks or scroll blocking
- **TOC Accuracy**: Correct chapter hierarchy display
- **Position Tracking**: Accurate paragraph indexing

## [Unreleased]

### Planned Features
- [ ] Bookmark system
- [ ] Full-text search
- [ ] Text selection and copying
- [ ] Note taking and highlights
- [ ] Dictionary lookup
- [ ] Cloud sync for reading position
- [ ] Performance optimizations for large books
- [ ] Additional themes
- [ ] Dyslexia-friendly font option
- [ ] Page-by-page reading mode

### Under Consideration
- EPUB3 advanced features
- Comic/manga support
- Experimental: MOBI format support
- Language-specific rendering (RTL support)
- Accessibility improvements (screen reader optimization)
