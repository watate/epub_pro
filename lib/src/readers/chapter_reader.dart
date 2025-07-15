import '../ref_entities/epub_book_ref.dart';
import '../ref_entities/epub_chapter_ref.dart';
import '../ref_entities/epub_text_content_file_ref.dart';
import '../schema/navigation/epub_navigation_point.dart';
import 'package:collection/collection.dart';

class ChapterReader {
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
    
    // Build initial NCX structure and collect handled items
    final ncxChapters = <EpubChapterRef>[];
    
    for (var i = 0; i < navPoints.length; i++) {
      final navPoint = navPoints[i];
      final nextNavPoint = i < navPoints.length - 1 ? navPoints[i + 1] : null;
      
      final chapter = _processNavPointWithOrphans(
        bookRef, navPoint, nextNavPoint, spinePositions, spine, manifest, handledSpineItems);
      if (chapter != null) {
        ncxChapters.add(chapter);
      }
    }
    
    // Handle any remaining spine items that come before the first NCX item
    // or after the last NCX item
    final remainingOrphans = <EpubChapterRef>[];
    for (var i = 0; i < spine.length; i++) {
      final manifestItem = manifest.firstWhereOrNull(
        (item) => item.id == spine[i].idRef,
      );
      if (manifestItem?.href != null && 
          !handledSpineItems.contains(manifestItem!.href!) &&
          bookRef.content!.html.containsKey(manifestItem.href!)) {
        final htmlContentFileRef = bookRef.content!.html[manifestItem.href!];
        final orphanChapter = EpubChapterRef(
          epubTextContentFileRef: htmlContentFileRef,
          title: null,
          contentFileName: manifestItem.href!,
          anchor: null,
          subChapters: const <EpubChapterRef>[],
        );
        remainingOrphans.add(orphanChapter);
      }
    }
    
    // Insert remaining orphans at appropriate positions
    for (var orphan in remainingOrphans) {
      final orphanPos = spinePositions[orphan.contentFileName] ?? -1;
      var inserted = false;
      for (var i = 0; i < ncxChapters.length; i++) {
        final chapterPos = spinePositions[ncxChapters[i].contentFileName] ?? -1;
        if (chapterPos > orphanPos) {
          ncxChapters.insert(i, orphan);
          inserted = true;
          break;
        }
      }
      if (!inserted) {
        ncxChapters.add(orphan);
      }
    }
    
    return ncxChapters;
  }

  static EpubChapterRef? _processNavPointWithOrphans(
      EpubBookRef bookRef,
      EpubNavigationPoint navPoint,
      EpubNavigationPoint? nextNavPoint,
      Map<String, int> spinePositions,
      List<dynamic> spine,
      List<dynamic> manifest,
      Set<String> handledSpineItems) {
    
    // Process the navigation point as usual
    String? contentFileName;
    String? anchor;
    if (navPoint.content?.source == null) return null;
    
    var contentSourceAnchorCharIndex = navPoint.content!.source!.indexOf('#');
    if (contentSourceAnchorCharIndex == -1) {
      contentFileName = navPoint.content!.source;
      anchor = null;
    } else {
      contentFileName = navPoint.content!.source!
          .substring(0, contentSourceAnchorCharIndex);
      anchor = navPoint.content!.source!
          .substring(contentSourceAnchorCharIndex + 1);
    }
    contentFileName = Uri.decodeFull(contentFileName!);
    
    if (!bookRef.content!.html.containsKey(contentFileName)) {
      throw Exception(
        'Incorrect EPUB manifest: item with href = "$contentFileName" is missing.',
      );
    }
    
    final htmlContentFileRef = bookRef.content!.html[contentFileName];
    handledSpineItems.add(contentFileName);
    
    // Process child navigation points
    final subChapters = <EpubChapterRef>[];
    for (var i = 0; i < navPoint.childNavigationPoints.length; i++) {
      final childNavPoint = navPoint.childNavigationPoints[i];
      final nextChildNavPoint = i < navPoint.childNavigationPoints.length - 1 
          ? navPoint.childNavigationPoints[i + 1] 
          : null;
      
      final childChapter = _processNavPointWithOrphans(
        bookRef, childNavPoint, nextChildNavPoint, spinePositions, spine, manifest, handledSpineItems);
      if (childChapter != null) {
        subChapters.add(childChapter);
      }
    }
    
    // Find orphaned spine items that should be children of this nav point
    final mySpinePos = spinePositions[contentFileName] ?? -1;
    var nextNavPos = spine.length;
    
    // Determine the next navigation point's spine position
    if (nextNavPoint != null && nextNavPoint.content?.source != null) {
      var nextFileName = nextNavPoint.content!.source!;
      final anchorIndex = nextFileName.indexOf('#');
      if (anchorIndex != -1) {
        nextFileName = nextFileName.substring(0, anchorIndex);
      }
      nextFileName = Uri.decodeFull(nextFileName);
      final nextPos = spinePositions[nextFileName] ?? -1;
      if (nextPos > mySpinePos) {
        nextNavPos = nextPos;
      }
    }
    
    // Debug: Check what we're looking for
    // print('NavPoint ${navPoint.navigationLabels.first.text}: spine pos $mySpinePos, next nav pos $nextNavPos');
    
    // Collect orphaned spine items between this nav point and the next
    for (var i = mySpinePos + 1; i < nextNavPos && i < spine.length; i++) {
      final spineItem = spine[i];
      final manifestItem = manifest.firstWhereOrNull(
        (item) => item.id == spineItem.idRef,
      );
      
      if (manifestItem?.href != null && 
          !handledSpineItems.contains(manifestItem!.href!) &&
          bookRef.content!.html.containsKey(manifestItem.href!)) {
        
        // print('  Found orphan: ${manifestItem.href} at spine position $i');
        
        final orphanContentRef = bookRef.content!.html[manifestItem.href!];
        final orphanChapter = EpubChapterRef(
          epubTextContentFileRef: orphanContentRef,
          title: null,
          contentFileName: manifestItem.href!,
          anchor: null,
          subChapters: const <EpubChapterRef>[],
        );
        subChapters.add(orphanChapter);
        handledSpineItems.add(manifestItem.href!);
      }
    }
    
    return EpubChapterRef(
      epubTextContentFileRef: htmlContentFileRef,
      title: navPoint.navigationLabels.first.text,
      contentFileName: contentFileName,
      anchor: anchor,
      subChapters: subChapters,
    );
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
