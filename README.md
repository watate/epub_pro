# epub_pro

This is a fork of a [fork](https://github.com/4akloon/epub_plus), of a [fork](https://github.com/ScerIO/epubx.dart), of [dart-epub](https://github.com/orthros/dart-epub). All of which seem unmaintained.

I'm maintaining this so that I can read EPUBs on my app.

## What's different?
1. Updated dependencies (so your installs will work)
2. Fixed readBook crashing when EPUB manifest cover image doesn't exist
3. **Smart NCX/Spine reconciliation** - When EPUBs have incomplete navigation (NCX) that doesn't include all spine items, the library automatically reconciles them by:
   - Preserving the NCX hierarchy for items that are in the navigation
   - Including orphaned spine items as subchapters under their logical parents
   - Maintaining the correct reading order from the spine
   - This matches how Apple Books and other readers handle malformed EPUBs
4. Added chapter splitting functionality - automatically split long chapters (>5000 words) into smaller, more manageable parts
5. Added lazy loading support for chapter splitting - read and split chapters on-demand for better memory efficiency

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
});
```

### Chapter Splitting for Long Chapters

```dart
// Automatically split chapters longer than 5000 words
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

### Lazy Loading for Memory Efficiency

```dart
// Open book for lazy loading (metadata only)
final bookRef = await EpubReader.openBook(bytes);

print('Title: ${bookRef.title}'); // Available immediately
print('Author: ${bookRef.author}'); // Available immediately

// Get chapter references (no content loaded yet)
final chapterRefs = bookRef.getChapters();

// Load content only when needed
for (final chapterRef in chapterRefs) {
  print('Chapter: ${chapterRef.title}');
  
  // Content is loaded here
  final htmlContent = await chapterRef.readHtmlContent();
  print('Content loaded: ${htmlContent?.length ?? 0} characters');
}
```

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