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
  - `readBookWithSplitChapters()`: Automatically splits chapters >3000 words (eager loading)
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
- `ChapterReader`: Builds chapter hierarchy with smart NCX/spine reconciliation
  - Handles EPUBs where NCX doesn't include all spine items
  - Preserves NCX hierarchy for items in navigation
  - Inserts orphaned spine items as subchapters under logical parents
  - Uses spine position to determine parent-child relationships
- `ContentReader`: Loads actual content files (HTML, CSS, images, fonts)
- `BookCoverReader`: Extracts cover images with fallback strategies

**Writer Architecture**:
Each writer handles a specific OPF component:
- `PackageWriter`: Orchestrates all other writers
- `MetadataWriter`, `ManifestWriter`, `SpineWriter`, `GuideWriter`: Handle respective OPF sections

**Utility Classes**:
- `ChapterSplitter`: Handles splitting of long chapters
  - Counts words in HTML content (strips tags)
  - Splits chapters exceeding 3000 words
  - Maintains paragraph boundaries when splitting
  - Preserves sub-chapters in the first part only
  - Supports both eager and lazy splitting:
    - `splitChapter()`: Splits a loaded chapter, optionally with parent title inheritance
    - `splitChapterRef()`: Splits a chapter reference (loads content)
    - `createSplitRefs()`: Creates lazy-loading split references
    - `analyzeChapterForSplitting()`: Analyzes if splitting is needed
  - Uses (X/Y) format for split titles to avoid confusion with actual "Part" titles
  - Handles parent title inheritance for orphaned subchapters when split

### Important Implementation Details

1. **EPUB Format Handling**: The library robustly handles malformed EPUBs, including:
   - Missing cover images (falls back to first image in manifest)
   - NCX/spine mismatches through smart reconciliation:
     - Identifies spine items not present in NCX navigation
     - Groups orphaned items under their logical parent chapters
     - Maintains spine reading order while preserving NCX hierarchy
     - Example: If NCX only lists "Part 1" but spine contains "part1.xhtml, chapter01.xhtml, chapter02.xhtml", the chapters become subchapters of Part 1
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
   - Chapters exceeding 3000 words are automatically split into parts
   - Split titles follow the pattern: "Original Title (1/2)", "Original Title (2/2)", etc.
   - Orphaned subchapters inherit parent titles when split: "Parent Title (1/3)" instead of generic "Chapter (1/3)"
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
- Chapter splitting functionality (both eager and lazy) with (X/Y) format
- Memory efficiency of lazy loading
- Performance characteristics of different loading modes
- NCX/spine reconciliation for malformed EPUBs
- Parent title inheritance for orphaned subchapters when split
- Section-wrapped content handling (e.g., piranesi.epub)

### NCX/Spine Reconciliation Algorithm

The `ChapterReader` implements a sophisticated algorithm to handle EPUBs where the navigation (NCX) doesn't include all spine items:

1. **Build Spine Position Map**: Maps each spine item to its position in the reading order
2. **Process NCX Navigation**: Build initial chapter structure from NCX nav points
3. **Identify Orphaned Items**: Find spine items not referenced in NCX
4. **Find Logical Parents**: For each orphaned item:
   - Look for the nearest preceding NCX item in spine order
   - Insert as a subchapter under that parent
   - If no parent found, add as top-level chapter
5. **Maintain Order**: Ensure all items appear in spine order within their hierarchical level

This approach ensures users can access all content while preserving the author's intended navigation structure.