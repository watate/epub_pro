import '../entities/epub_chapter.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_chapter_split_ref.dart';

class ChapterSplitter {
  static const int maxWordsPerChapter = 5000;

  /// Counts the number of words in HTML content by stripping HTML tags
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

  /// Splits HTML content into parts based on word count
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

  /// Splits a chapter into multiple chapters if it exceeds the word limit
  static List<EpubChapter> splitChapter(EpubChapter chapter) {
    final wordCount = countWords(chapter.htmlContent);

    if (wordCount <= maxWordsPerChapter || chapter.htmlContent == null) {
      // Process sub-chapters even if main chapter doesn't need splitting
      if (chapter.subChapters.isNotEmpty) {
        final processedSubChapters = <EpubChapter>[];
        for (final subChapter in chapter.subChapters) {
          processedSubChapters.addAll(splitChapter(subChapter));
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
      final partTitle = chapter.title != null
          ? '${chapter.title} - Part ${i + 1}'
          : 'Part ${i + 1}';

      // Only add sub-chapters to the first part
      final subChapters = i == 0 ? chapter.subChapters : <EpubChapter>[];

      splitChapters.add(
        EpubChapter(
          title: partTitle,
          contentFileName: chapter.contentFileName,
          anchor: i == 0 ? chapter.anchor : null,
          htmlContent: parts[i],
          subChapters: i == 0
              ? subChapters.expand((sub) => splitChapter(sub)).toList()
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
  static Future<List<EpubChapter>> splitChapterRef(
      EpubChapterRef chapterRef) async {
    final htmlContent = await chapterRef.readHtmlContent();
    final wordCount = countWords(htmlContent);

    if (wordCount <= maxWordsPerChapter) {
      // Process sub-chapters even if main chapter doesn't need splitting
      final processedSubChapters = <EpubChapter>[];
      for (final subChapterRef in chapterRef.subChapters) {
        processedSubChapters.addAll(await splitChapterRef(subChapterRef));
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
      final partTitle = chapterRef.title != null
          ? '${chapterRef.title} - Part ${i + 1}'
          : 'Part ${i + 1}';

      // Process sub-chapters for the first part only
      final subChapters = <EpubChapter>[];
      if (i == 0) {
        for (final subChapterRef in chapterRef.subChapters) {
          subChapters.addAll(await splitChapterRef(subChapterRef));
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
