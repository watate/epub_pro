import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';
import '../schema/navigation/epub_navigation_point.dart';
import '../schema/opf/epub_version.dart';
import 'package:collection/collection.dart';

class ChapterReader {
  static List<EpubChapterRef> getChapters(EpubBookRef bookRef) {
    if (bookRef.schema!.navigation == null) {
      return <EpubChapterRef>[];
    }

    // For EPUB2, we need to consider both the NCX navigation and spine order
    if (bookRef.schema!.package?.version == EpubVersion.epub2) {
      final navChapters = getChaptersImpl(bookRef, bookRef.schema!.navigation!.navMap!.points);
      
      // Create a map of content files to their chapter references
      final contentFileToChapter = <String, EpubChapterRef>{};
      for (var chapter in navChapters) {
        if (chapter.contentFileName != null) {
          contentFileToChapter[chapter.contentFileName!] = chapter;
        }
      }

      // Get chapters in spine order
      final spineChapters = <EpubChapterRef>[];
      
      for (var spineItem in bookRef.schema!.package!.spine!.items) {
        final manifestItem = bookRef.schema!.package!.manifest!.items.firstWhereOrNull(
          (item) => item.id == spineItem.idRef,
        );
        
        if (manifestItem != null && manifestItem.href != null) {
          final contentFileName = manifestItem.href!;
          var chapter = contentFileToChapter[contentFileName];
          
          // If chapter not in NCX, create a new one
          if (chapter == null) {
            if (bookRef.content!.html.containsKey(contentFileName)) {
              final htmlContentFileRef = bookRef.content!.html[contentFileName];
              chapter = EpubChapterRef(
                epubTextContentFileRef: htmlContentFileRef,
                title: null, // No title from NCX
                contentFileName: contentFileName,
                anchor: null,
                subChapters: const <EpubChapterRef>[],
              );
            }
          }
          
          if (chapter != null) {
            spineChapters.add(chapter);
          }
        }
      }

      return spineChapters;
    }

    // For EPUB3, just use the navigation map
    return getChaptersImpl(bookRef, bookRef.schema!.navigation!.navMap!.points);
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
      var chapterRef = EpubChapterRef(
        epubTextContentFileRef: htmlContentFileRef,
        title: navigationPoint.navigationLabels.first.text,
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
