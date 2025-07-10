# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development Commands
- **Install dependencies**: `dart pub get`
- **Run tests**: `dart test`
- **Run specific test**: `dart test test/path/to/test_file.dart`
- **Lint code**: `dart analyze`
- **Format code**: `dart format .`
- **Check publishing readiness**: `dart pub publish --dry-run`

## Architecture Overview

This is a Dart library for reading and writing EPUB files, supporting both EPUB 2 and EPUB 3 formats. The library is designed to be cross-platform (server, web, Flutter) with no dependency on `dart:io`.

### Core Architecture Pattern

The library follows a clear separation between:
1. **Entities**: Immutable data models representing EPUB components
2. **Ref Entities**: Reference-based versions for lazy loading (e.g., `EpubBookRef` loads content on-demand)
3. **Readers**: Parse EPUB components from raw data
4. **Writers**: Serialize entities back to EPUB format
5. **Schema**: EPUB specification structures (OPF, NCX, Navigation)
6. **Utils**: Utility classes including `ChapterSplitter` for splitting long chapters

### Key Components

**Main Entry Points**:
- `EpubReader`: Read EPUB files (supports both byte arrays and lazy loading)
  - `readBook()`: Standard reading method
  - `readBookWithSplitChapters()`: Automatically splits chapters >5000 words (eager loading)
  - `openBook()`: Opens book for lazy loading
  - `openBookWithSplitChapters()`: Opens book with lazy loading and automatic chapter splitting
- `EpubWriter`: Write EPUB files back to disk
- `EpubBook`: Complete book representation
- `EpubBookRef`: Reference-based book for lazy loading
  - `getChapters()`: Standard chapter retrieval
  - `getChaptersWithSplitting()`: Retrieves chapters with automatic splitting (eager)
  - `getChapterRefsWithSplitting()`: Returns chapter references with lazy splitting
- `EpubBookSplitRef`: Wrapper for lazy loading books with split chapter support
- `EpubChapterSplitRef`: Represents a split chapter part with lazy content loading

**Reader Architecture**:
- `PackageReader`: Parses OPF package document (the EPUB manifest)
- `NavigationReader`: Handles both NCX (EPUB2) and Navigation Document (EPUB3)
- `ChapterReader`: Builds chapter hierarchy, handling spine/NCX conflicts
- `ContentReader`: Loads actual content files (HTML, CSS, images, fonts)
- `BookCoverReader`: Extracts cover images with fallback strategies

**Writer Architecture**:
Each writer handles a specific OPF component:
- `PackageWriter`: Orchestrates all other writers
- `MetadataWriter`, `ManifestWriter`, `SpineWriter`, `GuideWriter`: Handle respective OPF sections

**Utility Classes**:
- `ChapterSplitter`: Handles splitting of long chapters
  - Counts words in HTML content (strips tags)
  - Splits chapters exceeding 5000 words
  - Maintains paragraph boundaries when splitting
  - Preserves sub-chapters in the first part only
  - Supports both eager and lazy splitting:
    - `splitChapter()`: Splits a loaded chapter
    - `splitChapterRef()`: Splits a chapter reference (loads content)
    - `createSplitRefs()`: Creates lazy-loading split references
    - `analyzeChapterForSplitting()`: Analyzes if splitting is needed

### Important Implementation Details

1. **EPUB Format Handling**: The library robustly handles malformed EPUBs, including:
   - Missing cover images (falls back to first image in manifest)
   - NCX/spine mismatches (includes spine items not in NCX for EPUB2)
   - Invalid manifest references

2. **Memory Efficiency**: Multiple loading modes:
   - Eager loading: `EpubReader.readBook()` - loads everything into memory
   - Eager with splitting: `EpubReader.readBookWithSplitChapters()` - loads and splits all chapters
   - Lazy loading: `EpubReader.openBook()` - loads content on-demand via refs
   - Lazy with splitting: `EpubReader.openBookWithSplitChapters()` - splits chapters on-demand

3. **Chapter Structure**: Chapters can be hierarchical. The library correctly handles:
   - EPUB2: NCX-based navigation with spine fallback
   - EPUB3: Navigation Document with landmarks and page lists

4. **Content References**: All content references are normalized relative to the OPF file location.

5. **Chapter Splitting**: For books with very long chapters (like Fahrenheit 451):
   - Chapters exceeding 5000 words are automatically split into parts
   - Split titles follow the pattern: "Original Title - Part 1", "Original Title - Part 2", etc.
   - Splitting attempts to break at paragraph boundaries for better readability
   - Sub-chapters are preserved only in the first part of a split chapter
   - Available through multiple methods:
     - `readBookWithSplitChapters()`: Eager loading with splitting
     - `getChaptersWithSplitting()`: Get split chapters from a book reference
     - `openBookWithSplitChapters()`: Lazy loading with on-demand splitting
     - `getChapterRefsWithSplitting()`: Get split chapter references for lazy loading

### Testing Approach

Tests use real EPUB files from `test/assets/` including classics like "Alice's Adventures in Wonderland" and "Frankenstein". Test files verify:
- Entity serialization/deserialization
- Schema parsing accuracy
- Reader/writer round-trip consistency
- Edge case handling (malformed EPUBs)
- Chapter splitting functionality (both eager and lazy)
- Memory efficiency of lazy loading
- Performance characteristics of different loading modes