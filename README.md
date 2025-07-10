# epub_pro

This is a fork of a [fork](https://github.com/4akloon/epub_pro), of a [fork](https://github.com/ScerIO/epubx.dart), of [dart-epub](https://github.com/orthros/dart-epub). All of which seem unmaintained.

I'm maintaining this so that I can read EPUBs on my app.

## What's different?
1. Updated dependencies (so your installs will work)
2. Fixed readBook crashing when EPUB manifest cover image doesn't exist
3. Handle unreliable toc.ncx. When your NCX conflicts with your Spine, we try to grab the missing chapters that are in your Spine instead (this seems to be how Apple Books handles it for example)
4. Added chapter splitting functionality - automatically split long chapters (>5000 words) into smaller, more manageable parts
5. Added lazy loading support for chapter splitting - read and split chapters on-demand for better memory efficiency

## Internal
dart pub publish --dry-run
dart format .
dart test

# Documentation from previous forks

Epub Reader and Writer for Dart inspired by [this fantastic C# Epub Reader](https://github.com/versfx/EpubReader)

This does not rely on the ```dart:io``` package in any way, so it is avilable for both desktop and web-based implementations

[![pub package](https://img.shields.io/pub/v/epub_pro.svg)](https://pub.dartlang.org/packages/epub_pro)
## Installing
Add the package to the ```dependencies``` section of your pubspec.yaml
```yaml
dependencies:
  epub_pro: any
```

## Example
```dart

  //Get the epub into memory somehow
  String fileName = 'sample.epub';
  String fullPath = path.join(io.Directory.current.path, fileName);
  var targetFile = new io.File(fullPath);
  List<int> bytes = await targetFile.readAsBytes();

  // Opens a book and reads all of its content into the memory
  EpubBook epubBook = await EpubReader.readBook(bytes);

  // COMMON PROPERTIES

  // Book's title
  String? title = epubBook.title;

  // Book's authors (comma separated list)
  String? author = epubBook.author;

  // Book's authors (list of authors names)
  List<String?>? authors = epubBook.authors;

  // Book's cover image (null if there is no cover)
  Image? coverImage = epubBook.coverImage;

  // CHAPTERS

  // Enumerating chapters
  epubBook.chapters.forEach((EpubChapter chapter) {
    // Title of chapter
    String? chapterTitle = chapter.title;

    // HTML content of current chapter
    String? chapterHtmlContent = chapter.htmlContent;

    // Nested chapters
    List<EpubChapter> subChapters = chapter.subChapters;
  });

  // CONTENT

  // Book's content (HTML files, stlylesheets, images, fonts, etc.)
  EpubContent? bookContent = epubBook.content;

  // IMAGES

  // All images in the book (file name is the key)
  Map<String, EpubByteContentFile>? images = bookContent?.images;

  EpubByteContentFile? firstImage =
      images?.values.firstOrNull; // Get the first image in the book

  // Content type (e.g. EpubContentType.IMAGE_JPEG, EpubContentType.IMAGE_PNG)
  EpubContentType contentType = firstImage!.contentType!;

  // MIME type (e.g. "image/jpeg", "image/png")
  String mimeContentType = firstImage.contentMimeType!;

  // HTML & CSS

  // All XHTML files in the book (file name is the key)
  Map<String, EpubTextContentFile>? htmlFiles = bookContent?.html;

  // All CSS files in the book (file name is the key)
  Map<String, EpubTextContentFile>? cssFiles = bookContent?.css;

  // Entire HTML content of the book
  htmlFiles?.values.forEach((EpubTextContentFile htmlFile) {
    String? htmlContent = htmlFile.content;
  });

  // All CSS content in the book
  cssFiles?.values.forEach((EpubTextContentFile cssFile) {
    String cssContent = cssFile.content!;
  });

  // OTHER CONTENT

  // All fonts in the book (file name is the key)
  Map<String, EpubByteContentFile>? fonts = bookContent?.fonts;

  // All files in the book (including HTML, CSS, images, fonts, and other types of files)
  Map<String, EpubContentFile>? allFiles = bookContent?.allFiles;

  // ACCESSING RAW SCHEMA INFORMATION

  // EPUB OPF data
  EpubPackage? package = epubBook.schema?.package;

  // Enumerating book's contributors
  package?.metadata?.contributors.forEach((contributor) {
    String contributorName = contributor.contributor!;
    String contributorRole = contributor.role!;
  });

  // EPUB NCX data
  EpubNavigation navigation = epubBook.schema!.navigation!;

  // Enumerating NCX metadata
  navigation.head?.metadata.forEach((meta) {
    String metadataItemName = meta.name!;
    String metadataItemContent = meta.content!;
  });

  // Write the Book
  var written = EpubWriter.writeBook(epubBook);

  if (written != null) {
    // Read the book into a new object!
    var newBook = await EpubReader.readBook(written);
  }

  // CHAPTER SPLITTING

  // Read book with automatic chapter splitting (chapters > 5000 words are split)
  EpubBook splitBook = await EpubReader.readBookWithSplitChapters(bytes);
  
  // The chapters are now split into manageable parts
  splitBook.chapters.forEach((EpubChapter chapter) {
    // Chapters with >5000 words will have titles like:
    // "Original Chapter Title - Part 1"
    // "Original Chapter Title - Part 2"
    String? chapterTitle = chapter.title;
    String? chapterHtmlContent = chapter.htmlContent;
  });

  // LAZY LOADING WITH CHAPTER SPLITTING

  // Open book for lazy loading with automatic chapter splitting
  EpubBookRef lazyBookRef = await EpubReader.openBookWithSplitChapters(bytes);
  
  // Get chapter references that will be split as needed
  List<EpubChapterRef> chapterRefs = await lazyBookRef.getChapterRefsWithSplitting();
  
  // Content is loaded on-demand when you read it
  for (var chapterRef in chapterRefs) {
    if (chapterRef is EpubChapterSplitRef) {
      // This is a split chapter part
      print('${chapterRef.title} (Part ${chapterRef.partNumber} of ${chapterRef.totalParts})');
    }
    // Content is only loaded when you call readHtmlContent()
    String content = await chapterRef.readHtmlContent();
  }

  // For comparison: regular lazy loading with splitting
  EpubBookRef bookRef = await EpubReader.openBook(bytes);
  List<EpubChapter> splitChapters = await bookRef.getChaptersWithSplitting();
  
  // Each chapter is guaranteed to have ≤5000 words
  for (var chapter in splitChapters) {
    print('${chapter.title}: ${chapter.htmlContent?.length} characters');
  }
```