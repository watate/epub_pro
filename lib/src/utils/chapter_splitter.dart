import '../entities/epub_chapter.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_chapter_split_ref.dart';

/// Utility class for splitting long chapters into smaller, more readable parts.
///
/// The [ChapterSplitter] provides functionality to automatically split chapters
/// that exceed a certain word count threshold. This improves readability and
/// performance when rendering chapters in reading applications.
///
/// ## Features
/// - Word counting that strips HTML tags
/// - Intelligent splitting at paragraph boundaries
/// - Preservation of HTML structure
/// - Support for both eager and lazy splitting
///
/// ## Splitting Algorithm
/// 1. Count words in the HTML content (excluding tags)
/// 2. If exceeds [maxWordsPerChapter], calculate number of parts needed
/// 3. Find paragraph boundaries for clean splits
/// 4. Distribute content evenly across parts
/// 5. Preserve subchapters only in the first part
///
/// ## Example
/// ```dart
/// final chapter = EpubChapter(
///   title: 'Long Chapter',
///   htmlContent: veryLongHtml, // 10,000 words
/// );
///
/// final parts = ChapterSplitter.splitChapter(chapter);
/// // Results in:
/// // - "Long Chapter - Part 1" (≤5000 words)
/// // - "Long Chapter - Part 2" (≤5000 words)
/// ```
class ChapterSplitter {
  /// Maximum number of words allowed per chapter part.
  static const int maxWordsPerChapter = 5000;

  /// Counts the number of words in HTML content.
  ///
  /// This method:
  /// - Removes all HTML tags
  /// - Removes HTML entities (e.g., &amp;, &nbsp;)
  /// - Normalizes whitespace
  /// - Counts remaining words
  ///
  /// The [htmlContent] parameter is the HTML string to count words in.
  /// Returns 0 if the content is null or empty.
  ///
  /// ## Example
  /// ```dart
  /// final html = '<p>Hello <strong>world</strong>!</p>';
  /// final count = ChapterSplitter.countWords(html); // Returns 2
  /// ```
  static int countWords(String? htmlContent) {
    if (htmlContent == null || htmlContent.isEmpty) return 0;

    // Remove HTML tags and decode HTML entities
    final textOnly = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), ' ') // Remove HTML tags
        .replaceAll(RegExp(r'&[^;]+;'), ' ') // Remove HTML entities
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    if (textOnly.isEmpty) return 0;

    // Split by whitespace and count non-empty tokens
    // This will count punctuation attached to words as part of the word
    return textOnly
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  /// Splits HTML content into parts based on word count.
  ///
  /// Attempts to split at paragraph boundaries for clean breaks.
  /// If no paragraphs are found, falls back to character-based splitting.
  ///
  /// The [htmlContent] is the HTML to split.
  /// The [maxWords] is the maximum words per part.
  ///
  /// Returns a list of HTML strings, each containing at most [maxWords] words.
  static List<String> splitHtmlContent(String htmlContent, int maxWords) {
    if (htmlContent.isEmpty) return [htmlContent];

    final wordCount = countWords(htmlContent);
    if (wordCount <= maxWords) return [htmlContent];

    // Calculate number of parts needed
    final numParts = (wordCount / maxWords).ceil();

    // Parse the HTML to find paragraph boundaries
    final paragraphs = <String>[];
    final paragraphPattern = RegExp(r'<p[^>]*>.*?</p>', dotAll: true);
    final matches = paragraphPattern.allMatches(htmlContent);

    if (matches.isEmpty) {
      // If no paragraphs found, split by approximate character count
      return _splitByCharacterCount(htmlContent, numParts);
    }

    // Extract all content before first paragraph
    var lastEnd = 0;
    final beforeContent = StringBuffer();

    for (final match in matches) {
      if (match.start > lastEnd) {
        beforeContent.write(htmlContent.substring(lastEnd, match.start));
      }
      paragraphs.add(match.group(0)!);
      lastEnd = match.end;
    }

    // Extract content after last paragraph
    final afterContent =
        lastEnd < htmlContent.length ? htmlContent.substring(lastEnd) : '';

    // Split paragraphs into parts
    final parts = <String>[];
    final wordsPerPart = (wordCount / numParts).ceil();
    var currentPart = StringBuffer(beforeContent.toString());
    var currentWordCount = 0;

    for (final paragraph in paragraphs) {
      final paragraphWords = countWords(paragraph);

      if (currentWordCount > 0 &&
          currentWordCount + paragraphWords > wordsPerPart &&
          parts.length < numParts - 1) {
        // Start a new part
        parts.add(currentPart.toString());
        currentPart = StringBuffer();
        currentWordCount = 0;
      }

      currentPart.write(paragraph);
      currentWordCount += paragraphWords;
    }

    // Add remaining content to last part
    if (afterContent.isNotEmpty) {
      currentPart.write(afterContent);
    }

    if (currentPart.isNotEmpty) {
      parts.add(currentPart.toString());
    }

    return parts;
  }

  /// Fallback method to split by character count when no paragraphs are found
  static List<String> _splitByCharacterCount(String content, int numParts) {
    final parts = <String>[];
    final charsPerPart = (content.length / numParts).ceil();

    for (var i = 0; i < numParts; i++) {
      final start = i * charsPerPart;
      final end = ((i + 1) * charsPerPart).clamp(0, content.length);
      parts.add(content.substring(start, end));
    }

    return parts;
  }

  /// Splits a chapter into multiple parts if it exceeds the word limit.
  ///
  /// If the chapter's word count exceeds [maxWordsPerChapter], it is split
  /// into multiple parts. Each part gets a title like "Original Title (1/3)".
  ///
  /// For orphaned subchapters (those without meaningful titles), the parent
  /// title is used as the base for split part titles.
  ///
  /// Subchapters are preserved only in the first part and are recursively
  /// split if needed.
  ///
  /// The [chapter] parameter is the chapter to potentially split.
  /// The [parentTitle] parameter is used for orphaned subchapters without titles.
  ///
  /// Returns a list containing either:
  /// - The original chapter (if under word limit)
  /// - Multiple chapter parts (if over word limit)
  ///
  /// ## Example
  /// ```dart
  /// final longChapter = EpubChapter(
  ///   title: 'War and Peace',
  ///   htmlContent: veryLongContent, // 15,000 words
  /// );
  ///
  /// final parts = ChapterSplitter.splitChapter(longChapter);
  /// // Returns 3 chapters:
  /// // - "War and Peace (1/3)"
  /// // - "War and Peace (2/3)"
  /// // - "War and Peace (3/3)"
  /// ```
  static List<EpubChapter> splitChapter(EpubChapter chapter,
      {String? parentTitle}) {
    final wordCount = countWords(chapter.htmlContent);

    if (wordCount <= maxWordsPerChapter || chapter.htmlContent == null) {
      // Process sub-chapters even if main chapter doesn't need splitting
      if (chapter.subChapters.isNotEmpty) {
        final processedSubChapters = <EpubChapter>[];
        for (final subChapter in chapter.subChapters) {
          processedSubChapters
              .addAll(splitChapter(subChapter, parentTitle: chapter.title));
        }

        return [
          EpubChapter(
            title: chapter.title,
            contentFileName: chapter.contentFileName,
            anchor: chapter.anchor,
            htmlContent: chapter.htmlContent,
            subChapters: processedSubChapters,
          )
        ];
      }
      return [chapter];
    }

    // Split the content
    final parts = splitHtmlContent(chapter.htmlContent!, maxWordsPerChapter);
    final splitChapters = <EpubChapter>[];

    for (var i = 0; i < parts.length; i++) {
      // Determine the base title for this split part
      String baseTitle;
      if (chapter.title != null && chapter.title!.isNotEmpty) {
        baseTitle = chapter.title!;
      } else if (parentTitle != null && parentTitle.isNotEmpty) {
        baseTitle = parentTitle;
      } else {
        baseTitle = chapter.contentFileName ?? 'Chapter';
      }

      final partTitle = '$baseTitle (${i + 1}/${parts.length})';

      // Only add sub-chapters to the first part
      final subChapters = i == 0 ? chapter.subChapters : <EpubChapter>[];

      splitChapters.add(
        EpubChapter(
          title: partTitle,
          contentFileName: chapter.contentFileName,
          anchor: i == 0 ? chapter.anchor : null,
          htmlContent: parts[i],
          subChapters: i == 0
              ? subChapters
                  .expand(
                      (sub) => splitChapter(sub, parentTitle: chapter.title))
                  .toList()
              : [],
        ),
      );
    }

    return splitChapters;
  }

  /// Splits multiple chapters
  static List<EpubChapter> splitChapters(List<EpubChapter> chapters) {
    final result = <EpubChapter>[];
    for (final chapter in chapters) {
      result.addAll(splitChapter(chapter));
    }
    return result;
  }

  /// Creates a function to split a chapter ref when its content is loaded
  static Future<List<EpubChapter>> splitChapterRef(EpubChapterRef chapterRef,
      {String? parentTitle}) async {
    final htmlContent = await chapterRef.readHtmlContent();
    final wordCount = countWords(htmlContent);

    if (wordCount <= maxWordsPerChapter) {
      // Process sub-chapters even if main chapter doesn't need splitting
      final processedSubChapters = <EpubChapter>[];
      for (final subChapterRef in chapterRef.subChapters) {
        processedSubChapters.addAll(await splitChapterRef(subChapterRef,
            parentTitle: chapterRef.title));
      }

      return [
        EpubChapter(
          title: chapterRef.title,
          contentFileName: chapterRef.contentFileName,
          anchor: chapterRef.anchor,
          htmlContent: htmlContent,
          subChapters: processedSubChapters,
        )
      ];
    }

    // Split the content
    final parts = splitHtmlContent(htmlContent, maxWordsPerChapter);
    final splitChapters = <EpubChapter>[];

    for (var i = 0; i < parts.length; i++) {
      // Determine the base title for this split part
      String baseTitle;
      if (chapterRef.title != null && chapterRef.title!.isNotEmpty) {
        baseTitle = chapterRef.title!;
      } else if (parentTitle != null && parentTitle.isNotEmpty) {
        baseTitle = parentTitle;
      } else {
        baseTitle = chapterRef.contentFileName ?? 'Chapter';
      }

      final partTitle = '$baseTitle (${i + 1}/${parts.length})';

      // Process sub-chapters for the first part only
      final subChapters = <EpubChapter>[];
      if (i == 0) {
        for (final subChapterRef in chapterRef.subChapters) {
          subChapters.addAll(await splitChapterRef(subChapterRef,
              parentTitle: chapterRef.title));
        }
      }

      splitChapters.add(
        EpubChapter(
          title: partTitle,
          contentFileName: chapterRef.contentFileName,
          anchor: i == 0 ? chapterRef.anchor : null,
          htmlContent: parts[i],
          subChapters: subChapters,
        ),
      );
    }

    return splitChapters;
  }

  /// Analyzes a chapter to determine if it needs splitting without loading full content
  /// Returns the number of parts the chapter would be split into
  static Future<int> analyzeChapterForSplitting(
      EpubChapterRef chapterRef) async {
    final htmlContent = await chapterRef.readHtmlContent();
    final wordCount = countWords(htmlContent);

    if (wordCount <= maxWordsPerChapter) {
      return 1;
    }

    return (wordCount / maxWordsPerChapter).ceil();
  }

  /// Creates split chapter references for lazy loading
  /// This method creates references that load content on-demand
  static Future<List<EpubChapterRef>> createSplitRefs(
      EpubChapterRef chapterRef) async {
    final htmlContent = await chapterRef.readHtmlContent();
    final wordCount = countWords(htmlContent);

    if (wordCount <= maxWordsPerChapter) {
      // Process sub-chapters
      final processedSubChapters = <EpubChapterRef>[];
      for (final subChapterRef in chapterRef.subChapters) {
        processedSubChapters.addAll(await createSplitRefs(subChapterRef));
      }

      // Return a new chapter ref with processed sub-chapters
      if (processedSubChapters.length != chapterRef.subChapters.length) {
        return [
          EpubChapterRef(
            epubTextContentFileRef: chapterRef.epubTextContentFileRef,
            title: chapterRef.title,
            contentFileName: chapterRef.contentFileName,
            anchor: chapterRef.anchor,
            subChapters: processedSubChapters,
          )
        ];
      }
      return [chapterRef];
    }

    // Calculate split points
    final parts = splitHtmlContent(htmlContent, maxWordsPerChapter);
    final splitRefs = <EpubChapterRef>[];

    // Since splitHtmlContent returns new strings, we need to store the content directly
    // rather than trying to find offsets in the original

    for (var i = 0; i < parts.length; i++) {
      final partTitle = chapterRef.title != null
          ? '${chapterRef.title} - Part ${i + 1}'
          : 'Part ${i + 1}';

      // Process sub-chapters for the first part only
      final subChapterRefs = <EpubChapterRef>[];
      if (i == 0) {
        for (final subChapterRef in chapterRef.subChapters) {
          subChapterRefs.addAll(await createSplitRefs(subChapterRef));
        }
      }

      splitRefs.add(
        EpubChapterSplitRef(
          originalChapter: chapterRef,
          partNumber: i + 1,
          totalParts: parts.length,
          partContent: parts[i],
          originalTitle: chapterRef.title,
          title: partTitle,
          contentFileName: chapterRef.contentFileName,
          anchor: i == 0 ? chapterRef.anchor : null,
          subChapters: subChapterRefs,
        ),
      );
    }

    return splitRefs;
  }
}
