import 'dart:convert' as convert;
import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';
import '../schema/navigation/epub_navigation_point.dart';
import 'package:collection/collection.dart';

/// Reads and constructs the chapter hierarchy from EPUB navigation.
///
/// The [ChapterReader] is responsible for building the chapter structure
/// from EPUB navigation data (NCX for EPUB2, Navigation Document for EPUB3).
/// It implements smart NCX/spine reconciliation to handle malformed EPUBs
/// where the navigation doesn't include all content files.
///
/// ## NCX/Spine Reconciliation Algorithm
///
/// Many EPUBs have incomplete navigation that doesn't reference all spine items.
/// This reader ensures all content is accessible by:
///
/// 1. **Building a spine position map** - Maps each content file to its reading order
/// 2. **Processing NCX navigation** - Creates the intended hierarchical structure
/// 3. **Identifying orphaned items** - Finds spine items not in the navigation
/// 4. **Finding logical parents** - Places orphans under the nearest preceding NCX item
/// 5. **Maintaining order** - Preserves spine reading order within each level
///
/// ## Example Result
/// ```
/// Original NCX: [Part 1, Part 2]
/// Spine: [cover.xhtml, part1.xhtml, ch1.xhtml, ch2.xhtml, part2.xhtml, ch3.xhtml]
///
/// Result:
/// - cover.xhtml (orphaned, becomes top-level)
/// - Part 1
///   - ch1.xhtml (orphaned, under Part 1)
///   - ch2.xhtml (orphaned, under Part 1)
/// - Part 2
///   - ch3.xhtml (orphaned, under Part 2)
/// ```
class ChapterReader {
  /// Gets the complete chapter structure with NCX/spine reconciliation.
  ///
  /// Returns a list of [EpubChapterRef] representing the book's navigation,
  /// including any spine items not present in the NCX/NAV.
  static List<EpubChapterRef> getChapters(EpubBookRef bookRef) {
    if (bookRef.schema!.navigation == null) {
      return <EpubChapterRef>[];
    }

    // For both EPUB2 and EPUB3, we need to consider both the navigation and spine order
    // because some EPUBs don't include all content files in their navigation
    return _getChaptersWithSpineReconciliation(bookRef);
  }

  static List<EpubChapterRef> _getChaptersWithSpineReconciliation(
      EpubBookRef bookRef) {
    // Step 1: Build spine position map
    final spinePositions = <String, int>{};
    final spineItems = bookRef.schema!.package!.spine!.items;
    final manifest = bookRef.schema!.package!.manifest!.items;

    for (var i = 0; i < spineItems.length; i++) {
      final manifestItem = manifest.firstWhereOrNull(
        (item) => item.id == spineItems[i].idRef,
      );
      if (manifestItem?.href != null) {
        spinePositions[manifestItem!.href!] = i;
      }
    }

    // Step 2: Build enhanced NCX structure with orphan placeholders
    final ncxChapters = _buildEnhancedNCXStructure(bookRef, spinePositions);

    return ncxChapters;
  }

  static List<EpubChapterRef> _buildEnhancedNCXStructure(
      EpubBookRef bookRef, Map<String, int> spinePositions) {
    final navPoints = bookRef.schema!.navigation!.navMap!.points;
    final spine = bookRef.schema!.package!.spine!.items;
    final manifest = bookRef.schema!.package!.manifest!.items;

    // Track which spine items are handled by NCX
    final handledSpineItems = <String>{};
    // Track content files to prevent duplicates (ignoring anchors)
    final seenContentFiles = <String>{};

    // Build NCX structure without orphan handling (orphans will be standalone)
    final ncxChapters = <EpubChapterRef>[];

    for (var navPoint in navPoints) {
      final chapter = _processNavPoint(bookRef, navPoint, handledSpineItems, seenContentFiles);
      if (chapter != null) {
        ncxChapters.add(chapter);
      }
    }

    // Create standalone chapters for all orphaned spine items
    final orphanedChapters = <EpubChapterRef>[];
    for (var i = 0; i < spine.length; i++) {
      final manifestItem = manifest.firstWhereOrNull(
        (item) => item.id == spine[i].idRef,
      );
      if (manifestItem?.href != null &&
          !handledSpineItems.contains(manifestItem!.href!) &&
          bookRef.content!.html.containsKey(manifestItem.href!)) {
        final htmlContentFileRef = bookRef.content!.html[manifestItem.href!];
        final extractedTitle =
            _extractTitleFromHtml(htmlContentFileRef, manifestItem.href!);

        final orphanChapter = EpubChapterRef(
          epubTextContentFileRef: htmlContentFileRef,
          title: extractedTitle,
          contentFileName: manifestItem.href!,
          anchor: null,
          subChapters: const <EpubChapterRef>[],
        );
        orphanedChapters.add(orphanChapter);
      }
    }

    // Merge NCX chapters and orphaned chapters in spine order
    final allChapters = <EpubChapterRef>[];
    final ncxByPosition = <int, EpubChapterRef>{};
    final orphansByPosition = <int, EpubChapterRef>{};

    // Map NCX chapters by their spine positions
    for (var chapter in ncxChapters) {
      final pos = spinePositions[chapter.contentFileName] ?? -1;
      if (pos >= 0) {
        ncxByPosition[pos] = chapter;
      }
    }

    // Map orphaned chapters by their spine positions
    for (var chapter in orphanedChapters) {
      final pos = spinePositions[chapter.contentFileName] ?? -1;
      if (pos >= 0) {
        orphansByPosition[pos] = chapter;
      }
    }

    // Merge in spine order
    for (var i = 0; i < spine.length; i++) {
      if (ncxByPosition.containsKey(i)) {
        allChapters.add(ncxByPosition[i]!);
      } else if (orphansByPosition.containsKey(i)) {
        allChapters.add(orphansByPosition[i]!);
      }
    }

    return allChapters;
  }

  /// Processes a navigation point without adding orphaned spine items as sub-chapters.
  /// Orphaned items will be handled separately as standalone chapters.
  static EpubChapterRef? _processNavPoint(EpubBookRef bookRef,
      EpubNavigationPoint navPoint, Set<String> handledSpineItems, [Set<String>? seenContentFiles]) {
    seenContentFiles ??= <String>{};
    String? contentFileName;
    String? anchor;
    if (navPoint.content?.source == null) return null;

    var contentSourceAnchorCharIndex = navPoint.content!.source!.indexOf('#');
    if (contentSourceAnchorCharIndex == -1) {
      contentFileName = navPoint.content!.source;
      anchor = null;
    } else {
      contentFileName =
          navPoint.content!.source!.substring(0, contentSourceAnchorCharIndex);
      anchor =
          navPoint.content!.source!.substring(contentSourceAnchorCharIndex + 1);
    }
    contentFileName = Uri.decodeFull(contentFileName!);

    // Check if we've already processed this base file (ignore anchors for duplicate detection)
    if (seenContentFiles.contains(contentFileName)) {
      return null;
    }
    seenContentFiles.add(contentFileName);

    if (!bookRef.content!.html.containsKey(contentFileName)) {
      throw Exception(
        'Incorrect EPUB manifest: item with href = "$contentFileName" is missing.',
      );
    }

    final htmlContentFileRef = bookRef.content!.html[contentFileName];
    handledSpineItems.add(contentFileName);

    // Process child navigation points recursively
    final subChapters = <EpubChapterRef>[];
    for (var childNavPoint in navPoint.childNavigationPoints) {
      final childChapter =
          _processNavPoint(bookRef, childNavPoint, handledSpineItems, seenContentFiles);
      if (childChapter != null) {
        subChapters.add(childChapter);
      }
    }

    // Get title from NCX, but use HTML extraction as fallback if title is missing/empty
    String title = navPoint.navigationLabels.first.text ?? '';
    if (title.trim().isEmpty) {
      title = _extractTitleFromHtml(htmlContentFileRef, contentFileName);
    }

    return EpubChapterRef(
      epubTextContentFileRef: htmlContentFileRef,
      title: title,
      contentFileName: contentFileName,
      anchor: anchor,
      subChapters: subChapters,
    );
  }

  /// Extracts a title from HTML content for orphaned chapters.
  /// Looks for the first text element (div, p, a, h1, h2, etc.) and uses it as title.
  /// If the first text is ≤ 10 words, uses it as title.
  /// Otherwise, uses the filename without extension.
  static String _extractTitleFromHtml(
      dynamic htmlContentFileRef, String fileName) {
    try {
      // Get the HTML content synchronously
      final contentBytes = htmlContentFileRef.getContentStream();
      final content = convert.utf8.decode(contentBytes);

      // Simple regex to find first text content in body elements (skip title tags from head)
      final patterns = [
        RegExp(r'<h[1-6][^>]*>(.*?)</h[1-6]>', caseSensitive: false),
        RegExp(r'<p[^>]*>(.*?)</p>', caseSensitive: false),
        RegExp(r'<div[^>]*>(.*?)</div>', caseSensitive: false),
        RegExp(r'<a[^>]*>(.*?)</a>', caseSensitive: false),
      ];

      for (var pattern in patterns) {
        final matches = pattern.allMatches(content);
        for (var match in matches) {
          final text =
              match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (text != null && text.isNotEmpty) {
            // Accept whatever text we find, truncate if too long
            final words = text.split(RegExp(r'\s+'));
            if (words.length <= 10) {
              return text;
            } else {
              // Truncate to first 10 words
              return '${words.take(10).join(' ')}...';
            }
          }
        }
      }
    } catch (e) {
      // If we can't extract content, fall back to filename
    }

    // Fallback: use filename without extension
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  static List<EpubChapterRef> getChaptersImpl(
      EpubBookRef bookRef, List<EpubNavigationPoint> navigationPoints) {
    var result = <EpubChapterRef>[];
    // navigationPoints.forEach((EpubNavigationPoint navigationPoint) {
    for (var navigationPoint in navigationPoints) {
      String? contentFileName;
      String? anchor;
      if (navigationPoint.content?.source == null) continue;
      var contentSourceAnchorCharIndex =
          navigationPoint.content!.source!.indexOf('#');
      if (contentSourceAnchorCharIndex == -1) {
        contentFileName = navigationPoint.content!.source;
        anchor = null;
      } else {
        contentFileName = navigationPoint.content!.source!
            .substring(0, contentSourceAnchorCharIndex);
        anchor = navigationPoint.content!.source!
            .substring(contentSourceAnchorCharIndex + 1);
      }
      contentFileName = Uri.decodeFull(contentFileName!);
      EpubTextContentFileRef? htmlContentFileRef;
      if (!bookRef.content!.html.containsKey(contentFileName)) {
        throw Exception(
          'Incorrect EPUB manifest: item with href = "$contentFileName" is missing.',
        );
      }

      htmlContentFileRef = bookRef.content!.html[contentFileName];

      // Get title from NCX, but use HTML extraction as fallback if title is missing/empty
      String title = navigationPoint.navigationLabels.first.text ?? '';
      if (title.trim().isEmpty) {
        title = _extractTitleFromHtml(htmlContentFileRef, contentFileName);
      }

      var chapterRef = EpubChapterRef(
        epubTextContentFileRef: htmlContentFileRef,
        title: title,
        contentFileName: contentFileName,
        anchor: anchor,
        subChapters:
            getChaptersImpl(bookRef, navigationPoint.childNavigationPoints),
      );
      result.add(chapterRef);
    }

    return result;
  }
}
