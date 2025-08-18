# epub_pro

To my knowledge, this is the *only* working and actively maintained EPUB library for Dart.

History: This is a fork of a [fork](https://github.com/4akloon/epub_plus), of a [fork](https://github.com/ScerIO/epubx.dart), of [dart-epub](https://github.com/orthros/dart-epub). The other forks are unmaintained, and I'm maintaining this so that I can read EPUBs on my app.

## What's different?
1. Updated dependencies (so your installs will work)
2. Fixed readBook crashing when EPUB manifest cover image doesn't exist
3. **🚀 Performance Improvements (1.89x faster loading)** - Inspired by Readium's architecture:
   - **Lazy ZIP loading**: Only reads central directory initially, decompresses files on-demand
   - **Memory efficient**: Only accessed content consumes memory
   - **Incremental resource fetching**: Content loaded progressively as needed
   - **Performance**: 47ms vs 89ms for lazy vs eager loading (1.89x improvement)
4. **Smart NCX/Spine reconciliation** - When EPUBs have incomplete navigation (NCX) that doesn't include all spine items, the library automatically reconciles them by:
   - Preserving the NCX hierarchy for items that are in the navigation
   - Including orphaned spine items as subchapters under their logical parents
   - Maintaining the correct reading order from the spine
   - This matches how Apple Books and other readers handle malformed EPUBs
5. Added chapter splitting functionality (optional) - automatically split long chapters (>3000 words) into smaller, more manageable parts
6. Added lazy loading support for chapter splitting - read and split chapters on-demand for better memory efficiency
7. **📍 CFI (Canonical Fragment Identifier) Support** - Industry-standard precise positioning system:
   - **Position tracking**: Save and restore exact reading positions with CFI precision
   - **Annotation system**: Create highlights, notes, and bookmarks with precise location references  
   - **Reading analytics**: Track reading progress, velocity, and time estimates
   - **Cross-device sync**: Synchronize positions and annotations between devices

## Some useful info
### Mimetype
This file explains to your device that the archive is an ePUB, and needs to be read using an engine that can handle ePUBs. It must be the first file added to your ePUB folder when you are creating a new ePUB.

### META-INF Folder
Inside the META-INF folder is an XML file called container.xml that points the ebook to the OPF file.

This is the XML file that describes the ebook. This doesn't really change from ebook to ebook, can be the same for every ebook. Sometimes, the directory is called an OPS rather than OEBPS.  If that’s the case, then you need change it to OPS in the <rootfile> element too.

### OPS Folder
The OPS or OEBPS folder is where all of the content of your ebook lives. Typically, each chapter in the book will have its own HTML or XHTML page, as will any ancillary materials like the copyright page, title page, preface, epigraph, etc.

Different types of media need their own folders, so you should create a folder to house all of the images contained within the book, and another for fonts, and one for the CSS. If your book has any audio/video materials, those would need their own folders, too.

### content.opf
‘OPF’ stands for Open Package Format. It’s essentially an XML file, although it has the file extension .opf instead of .xml. It lists all of the contents of your ePUB, and tells the reading system what order to display the files in.

This includes:
1. OPF head
2. Metadata
3. OPF Manifest
4. Spine
5. Guide (not common in EPUB 3)

### OPF Manifest
The manifest is an unordered list of all of the files within the OEBPS/OPS directory.  Each item in the manifest has three components:
1. An item ID, which you can make up, and should describe the file.
```
<item id="cover"
```
2. A reference to the actual file.
```
href="cover.xhtml"
```
3. The media-type, which tells the parser what type of file it is.
```
media-type="application/xhtml+xml"/>
```

Things included in the manifest:
- Fonts
- All of the XHTML pages in the book (introduction, copyright, chapters, epigraph, etc.)
- Images
- Audio or Video files, if applicable
- The CSS stylesheet
- The NCX file, if you’re working with the ePUB 2.0 format

### Spine
The spine is an ordered list of all of the contents of the book. It uses the item IDs you’ve created in the manifest. Each item gets an item ref, and you use the item id that you created in the manifest for the id ref.

### NCX file
The NCX file abbreviated as a Navigation Control file for XML, usually named toc.ncx. This file consists of the hierarchical table of contents for an EPUB file. The specification for NCX was developed for Digital Talking Book (DTB) and this file format is maintained by the DAISY Consortium and is not a part of the EPUB specification. The NCX file includes a mime-type of application/x-dtbncx+xml into it.

### Sources
- https://www.eboundcanada.org/resources/whats-in-an-epub-the-root-directory/
- https://www.eboundcanada.org/resources/whats-in-an-epub-the-opf-file/
- https://apln.ca/introduction-to-the-opf-file/

## Internal
dart pub publish --dry-run
dart format .
dart test

## Information from the previous forks

Epub Reader and Writer for Dart inspired by [this fantastic C# Epub Reader](https://github.com/versfx/EpubReader)

This does not rely on the ```dart:io``` package in any way, so it is avilable for both desktop and web-based implementations

[![pub package](https://img.shields.io/pub/v/epub_pro.svg)](https://pub.dartlang.org/packages/epub_pro)

## Installing
Add the package to the ```dependencies``` section of your pubspec.yaml
```yaml
dependencies:
  epub_pro: any
```

## Usage Examples

### Basic EPUB Reading

```dart
import 'package:epub_pro/epub_pro.dart';
import 'dart:io';

// Load EPUB file
final epubFile = File('path/to/book.epub');
final bytes = await epubFile.readAsBytes();

// Read the entire book into memory
final epubBook = await EpubReader.readBook(bytes);

// Access basic properties
print('Title: ${epubBook.title}');
print('Author: ${epubBook.author}');
print('Authors: ${epubBook.authors.join(", ")}');

// Access cover image
if (epubBook.coverImage != null) {
  print('Cover: ${epubBook.coverImage!.width}x${epubBook.coverImage!.height}');
}
```

### Working with Chapters

```dart
// Iterate through chapters
for (final chapter in epubBook.chapters) {
  print('Chapter: ${chapter.title ?? "[No Title]"}');
  print('Content length: ${chapter.htmlContent?.length ?? 0} characters');
  
  // Handle nested chapters (subchapters)
  for (final subChapter in chapter.subChapters) {
    print('  SubChapter: ${subChapter.title ?? subChapter.contentFileName}');
  }
}
```

### Accessing Content Files

```dart
// Get all content
final content = epubBook.content;

// Access images
content?.images?.forEach((fileName, imageFile) {
  print('Image: $fileName (${imageFile.contentMimeType})');
  print('Size: ${imageFile.content?.length ?? 0} bytes');
});

// Access HTML files
content?.html?.forEach((fileName, htmlFile) {
  print('HTML: $fileName');
  print('Content: ${htmlFile.content?.substring(0, 100)}...');
});

// Access CSS files
content?.css?.forEach((fileName, cssFile) {
  print('CSS: $fileName');
  print('Content: ${cssFile.content}');
});

// Access a specific CSS file by path
final mainStylesheet = content?.css?['styles/main.css'];
if (mainStylesheet != null) {
  print('Main CSS content: ${mainStylesheet.content}');
}
```

### Chapter Splitting for Long Chapters

```dart
// Automatically split chapters longer than 3000 words
final splitBook = await EpubReader.readBookWithSplitChapters(bytes);

print('Original chapters: ${epubBook.chapters.length}');
print('After splitting: ${splitBook.chapters.length}');

// Split chapters use (X/Y) format
for (final chapter in splitBook.chapters) {
  print('Chapter: ${chapter.title}');
  // Example output:
  // "Chapter 1 (1/3)" for the first part of a chapter split into 3 parts
  // "Chapter 1 (2/3)" for the second part
  // "Chapter 1 (3/3)" for the third part
}
```

### 🚀 Lazy Loading for Memory Efficiency & Performance

```dart
// Open book for lazy loading (metadata only) - 1.89x faster!
final bookRef = await EpubReader.openBook(bytes);

print('Title: ${bookRef.title}'); // Available immediately
print('Author: ${bookRef.author}'); // Available immediately

// Get chapter references (no content loaded yet)
final chapterRefs = bookRef.getChapters();

// Load content only when needed - saves memory
for (final chapterRef in chapterRefs) {
  print('Chapter: ${chapterRef.title}');
  
  // Content is loaded here on-demand
  final htmlContent = await chapterRef.readHtmlContent();
  print('Content loaded: ${htmlContent?.length ?? 0} characters');
}

// Lazy load CSS files
final cssRefs = bookRef.content?.css;
for (final entry in cssRefs?.entries ?? []) {
  final cssContent = await entry.value.readContentAsText();
  print('CSS ${entry.key}: ${cssContent.length} characters');
}
```

#### Performance Benefits
- **1.89x faster initial loading** (47ms vs 89ms for 2.3MB EPUB)
- **Memory efficient**: Only accessed chapters consume memory
- **Scalable**: Handles large EPUBs without memory constraints
- **Progressive**: Content loaded as user navigates

### Lazy Loading with Chapter Splitting

```dart
// Open book with lazy loading and automatic chapter splitting
final splitBookRef = await EpubReader.openBookWithSplitChapters(bytes);

// Get chapter references that will be split as needed
final chapterRefs = await splitBookRef.getChapterRefsWithSplitting();

// Content is loaded and split on-demand
for (final chapterRef in chapterRefs) {
  if (chapterRef is EpubChapterSplitRef) {
    print('${chapterRef.title} (Part ${chapterRef.partNumber} of ${chapterRef.totalParts})');
  }
  
  // Content is only loaded when you call readHtmlContent()
  final content = await chapterRef.readHtmlContent();
}

// Alternative: Get all split chapters at once
final splitChapters = await bookRef.getChaptersWithSplitting();
for (final chapter in splitChapters) {
  print('${chapter.title}: ${chapter.htmlContent?.length} characters');
}
```

### Smart NCX/Spine Reconciliation

```dart
// The library automatically handles EPUBs with incomplete navigation
// Example: NCX only lists main parts, but spine contains individual chapters

// NCX Navigation: ["Part 1", "Part 2"]
// Spine Reading Order: ["cover.xhtml", "part1.xhtml", "chapter01.xhtml", "chapter02.xhtml", "part2.xhtml", "chapter03.xhtml"]

// The library creates a proper hierarchy:
for (final chapter in epubBook.chapters) {
  print('Chapter: ${chapter.title ?? chapter.contentFileName}');
  
  // Orphaned spine items become subchapters
  for (final subChapter in chapter.subChapters) {
    print('  SubChapter: ${subChapter.title ?? subChapter.contentFileName}');
  }
}

// Output:
// Chapter: cover.xhtml
// Chapter: Part 1
//   SubChapter: chapter01.xhtml
//   SubChapter: chapter02.xhtml
// Chapter: Part 2
//   SubChapter: chapter03.xhtml
```

### 📍 CFI (Canonical Fragment Identifier) Support

CFI provides industry-standard precise positioning within EPUB books, enabling exact reading position tracking, annotations, and cross-device synchronization.

#### Basic CFI Operations

```dart
// Open book with CFI manager access
final bookRef = await EpubReader.openBook(bytes);
final cfiManager = bookRef.cfiManager;

// Create a progress CFI pointing to a specific spine position
final cfi = bookRef.createProgressCFI(2); // Beginning of spine item 2
final cfiWithProgress = bookRef.createProgressCFI(2, fraction: 0.5); // 50% through spine item 2

// Navigate to a CFI location
final location = await bookRef.navigateToCFI(CFI('epubcfi(/6/4!/4/10/2:5)'));
if (location != null) {
  print('Found in chapter: ${location.chapterRef.title}');
  final textContent = await location.getTextContent();
  final context = await location.getContext(beforeChars: 50, afterChars: 50);
}

// Validate CFI before navigation
final isValid = await bookRef.validateCFI(cfi);
if (isValid) {
  final location = await bookRef.navigateToCFI(cfi);
}

// Get spine-to-chapter mapping for CFI operations
final spineMap = bookRef.getSpineChapterMap();
for (final entry in spineMap.entries) {
  print('Spine ${entry.key}: ${entry.value.title}');
}
```

#### Position Tracking & Reading Progress

```dart
// Create position tracker with storage implementation
final tracker = CFIPositionTracker(
  bookId: 'unique_book_id',
  bookRef: bookRef,
  storage: MyPositionStorage(), // Your storage implementation
);

// Save current reading position
await tracker.savePosition(
  cfi: CFI('epubcfi(/6/4!/4/10/2:5)'),
  fractionInChapter: 0.3, // 30% through the chapter
  metadata: {
    'sessionId': 'session_123',
    'deviceId': 'mobile_device',
  },
);

// Restore last reading position
final savedPosition = await tracker.restorePosition();
if (savedPosition != null) {
  print('Last read at: ${savedPosition.cfi}');
  print('Overall progress: ${(savedPosition.overallProgress * 100).toStringAsFixed(1)}%');
  
  // Navigate back to saved position
  final location = await tracker.navigateToSavedPosition();
}

// Get comprehensive reading progress
final progress = await tracker.calculateProgress();
print('Current chapter: ${progress.currentChapterIndex + 1}/${progress.totalChapters}');
print('Chapter: "${progress.currentChapterTitle}"');
print('Progress: ${progress.progressDescription}');
print('Reading speed: ${progress.readingVelocity.toStringAsFixed(1)} words/min');
print('Estimated time remaining: ${progress.estimatedTimeRemaining}');

// Record reading milestones for analytics
await tracker.recordMilestone(
  cfi: currentCFI,
  fractionInChapter: 0.5,
  sessionData: {
    'wordsRead': 1200,
    'timeSpentSeconds': 300, // 5 minutes
    'sessionType': 'focused_reading',
  },
);

// Get detailed reading statistics
final stats = await tracker.getReadingStatistics();
print('Total reading time: ${stats.totalReadingTime}');
print('Average reading speed: ${stats.averageWordsPerMinute} wpm');
print('Reading sessions: ${stats.sessionsCount}');
print('First started: ${stats.firstStarted}');
```

#### Cross-Device Synchronization

```dart
// Export data for sync
final syncData = await tracker.exportData();
final json = syncData.toJson();

// Send to cloud storage or another device...
await uploadToCloud(json);

// On another device, import and merge
final importedData = SyncData.fromJson(await downloadFromCloud());
await tracker.syncWith(importedData);

print('Positions synchronized across devices');
```

#### Annotation Management

```dart
// Create annotation manager
final annotationManager = CFIAnnotationManager(
  bookId: 'unique_book_id',
  bookRef: bookRef,
  storage: MyAnnotationStorage(), // Your storage implementation
);

// Create a highlight annotation
final highlight = await annotationManager.createHighlight(
  startCFI: CFI('epubcfi(/6/4!/4/10/2:5)'),
  endCFI: CFI('epubcfi(/6/4!/4/10/2:15)'),
  selectedText: 'This is important text',
  color: '#ffff00', // Yellow highlight
  note: 'Key concept for the exam',
);

// Create a note annotation
final note = await annotationManager.createNote(
  cfi: CFI('epubcfi(/6/4!/4/10/2:5)'),
  text: 'This reminds me of the discussion in Chapter 1',
  title: 'Connection to earlier material',
  category: 'analysis',
);

// Create a bookmark
final bookmark = await annotationManager.createBookmark(
  cfi: CFI('epubcfi(/6/6!/4/2/1:0)'),
  title: 'Start of important section',
  description: 'Chapter 3: The turning point',
);

// Retrieve annotations
final allAnnotations = await annotationManager.getAllAnnotations();
final highlights = await annotationManager.getAnnotationsByType<HighlightAnnotation>(
  AnnotationType.highlight,
);
final bookmarks = await annotationManager.getAnnotationsByType<BookmarkAnnotation>(
  AnnotationType.bookmark,
);

// Get annotations for a specific chapter
final chapterAnnotations = await annotationManager.getAnnotationsForChapter(2);

// Get annotations in a CFI range
final startCFI = CFI('epubcfi(/6/4!/4/2/1:0)');
final endCFI = CFI('epubcfi(/6/8!/4/2/1:0)');
final rangeAnnotations = await annotationManager.getAnnotationsInRange(startCFI, endCFI);

// Search annotations by content
final searchResults = await annotationManager.searchAnnotations('important concept');

// Find annotations near a specific position
final nearbyAnnotations = await annotationManager.findNearbyAnnotations(
  CFI('epubcfi(/6/4!/4/10/2:10)'),
  maxDistance: 1000, // characters
);
```

#### Advanced CFI Generation

```dart
// Generate CFI from chapter and element path
final chapterRef = bookRef.getChapters()[0];
final cfi = await chapterRef.generateCFI(
  elementPath: '/4/10/2', // XPath-style element path
  characterOffset: 15,
  bookRef: bookRef,
);

// Parse chapter content and generate CFI from DOM position
final document = await chapterRef.parseAsDOM();
final paragraph = document.getElementsByTagName('p').first;
final textNode = paragraph.childNodes.first;

final domPosition = DOMPosition(container: textNode, offset: 10);
final cfiFromDOM = await chapterRef.generateCFIFromPosition(
  position: domPosition,
  bookRef: bookRef,
);

// Create range CFI for text selections
final startPos = DOMPosition(container: textNode, offset: 5);
final endPos = DOMPosition(container: textNode, offset: 25);

final rangeCFI = await chapterRef.generateRangeCFI(
  startPosition: startPos,
  endPosition: endPos,
  bookRef: bookRef,
);

// Get text content at a CFI location
final textAtCFI = await chapterRef.getTextAtCFI(cfi, bookRef: bookRef);
print('Text at CFI: $textAtCFI');
```

#### Annotation Statistics and Export

```dart
// Get annotation statistics
final stats = await annotationManager.getAnnotationStatistics();
print('Total annotations: ${stats.totalCount}');
print('Highlights: ${stats.highlightCount}');
print('Notes: ${stats.noteCount}');
print('Bookmarks: ${stats.bookmarkCount}');
print('First annotation: ${stats.firstCreated}');

// Export annotations for backup
final exportData = await annotationManager.exportAnnotations();
final exportJson = exportData.toJson();
await saveToFile(exportJson);

// Import annotations with merge strategy
final importData = AnnotationExport.fromJson(await loadFromFile());
await annotationManager.importAnnotations(
  importData,
  mergeStrategy: MergeStrategy.skipExisting, // Don't overwrite existing
);
```

#### Storage Implementation

You'll need to implement storage interfaces for persistence:

```dart
// Position storage example (implement PositionStorage)
class MyPositionStorage implements PositionStorage {
  @override
  Future<void> savePosition(ReadingPosition position) async {
    // Save to local database, cloud, etc.
    await database.insert('positions', position.toJson());
  }

  @override
  Future<ReadingPosition?> getPosition(String bookId) async {
    final result = await database.query('positions', where: 'bookId = ?', whereArgs: [bookId]);
    return result.isNotEmpty ? ReadingPosition.fromJson(result.first) : null;
  }

  // ... implement other methods
}

// Annotation storage example (implement AnnotationStorage)  
class MyAnnotationStorage implements AnnotationStorage {
  @override
  Future<void> saveAnnotation(Annotation annotation) async {
    await database.insert('annotations', annotation.toJson());
  }

  @override
  Future<List<Annotation>> getAnnotations(String bookId) async {
    final results = await database.query('annotations', where: 'bookId = ?', whereArgs: [bookId]);
    return results.map((json) => Annotation.fromJson(json)).toList();
  }

  // ... implement other methods
}
```

### Writing EPUB Files

```dart
// Write the book back to bytes
final writtenBytes = EpubWriter.writeBook(epubBook);

if (writtenBytes != null) {
  // Save to file
  final outputFile = File('output.epub');
  await outputFile.writeAsBytes(writtenBytes);
  
  // Or read it back
  final newBook = await EpubReader.readBook(writtenBytes);
  print('Round-trip successful: ${newBook.title}');
}
```

### Advanced: Accessing Raw Schema Information

```dart
// Access EPUB OPF (Open Packaging Format) data
final package = epubBook.schema?.package;

// Enumerate contributors
package?.metadata?.contributors.forEach((contributor) {
  print('Contributor: ${contributor.contributor} (${contributor.role})');
});

// Access EPUB NCX (Navigation Control file) data
final navigation = epubBook.schema?.navigation;

// Enumerate NCX metadata
navigation?.head?.metadata.forEach((meta) {
  print('${meta.name}: ${meta.content}');
});
```

## Performance & Architecture

This library is inspired by **Readium's architecture** for high-performance EPUB processing:

### Key Performance Features
- **Lazy ZIP loading**: Only reads central directory initially
- **On-demand decompression**: Files extracted only when accessed
- **Memory efficiency**: Unaccessed content doesn't consume memory
- **Progressive loading**: Critical files (OPF, NCX) preloaded for speed
- **Cross-platform**: Pure Dart implementation, no `dart:io` dependency

### Performance Metrics
```
Test Results (2.3MB EPUB):
- Lazy loading: 47ms
- Eager loading: 89ms  
- Performance gain: 1.89x faster (44% improvement)
- Memory efficiency: Only accessed chapters loaded
```

### When to Use Each Mode
- **`EpubReader.openBook()`**: Fast loading, memory efficient, progressive reading
- **`EpubReader.readBook()`**: Full compatibility, immediate access to all content
- **`openBookWithSplitChapters()`**: Best of both worlds with automatic chapter splitting
- **`readBookWithSplitChapters()`**: Split long chapters with eager loading

The performance improvements scale with EPUB size - larger files show even greater benefits.