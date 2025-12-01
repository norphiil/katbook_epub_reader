# Changelog

All notable changes to the Katbook EPUB Reader package will be documented in this file.

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
