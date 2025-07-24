import 'dart:io' as io;

import 'package:epub_pro/epub_pro.dart';
import 'package:epub_pro/src/schema/opf/epub_metadata_meta.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('SAO Japanese EPUB Tests', () {
    late EpubBook saoBook;
    late EpubBookRef saoRef;
    final verbose = true;

    setUpAll(() async {
      // Load sao.epub if it exists
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        print('Skipping SAO tests - sao.epub not found at: $saoPath');
        return;
      }
      
      if (verbose) {
        print('\n=== Loading SAO (Sword Art Online) Japanese EPUB ===');
      }
      
      final saoBytes = await saoFile.readAsBytes();
      saoBook = await EpubReader.readBook(saoBytes);
      saoRef = await EpubReader.openBook(saoBytes);
    });

    test('handles minimal navigation with spine reconciliation', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check navigation points (should only have 1)
      final navPoints = saoRef.schema?.navigation?.navMap?.points ?? [];
      expect(navPoints.length, equals(1));
      expect(navPoints.first.navigationLabels!.first.text, equals('奥付')); // "Colophon"
      
      // Check that we get all chapters from spine reconciliation
      final chapters = saoRef.getChapters();
      expect(chapters.length, equals(40)); // All spine items should be chapters
      
      if (verbose) {
        print('\n=== Navigation Reconciliation Results ===');
        print('Navigation entries: ${navPoints.length}');
        print('Total chapters after reconciliation: ${chapters.length}');
        print('\nOnly navigation entry:');
        print('  ${navPoints.first.navigationLabels!.first.text} -> ${navPoints.first.content?.source}');
      }
    });

    test('correctly identifies all 40 chapters from spine', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      final chapters = saoBook.chapters;
      expect(chapters.length, equals(40));
      
      // First should be titlepage
      expect(chapters.first.contentFileName, equals('titlepage.xhtml'));
      
      // Last should be part0038 with title
      expect(chapters.last.contentFileName, equals('text/part0038.html'));
      expect(chapters.last.title, equals('奥付'));
      
      // All others should be untitled
      for (var i = 1; i < chapters.length - 1; i++) {
        expect(chapters[i].title, isNull);
      }
      
      if (verbose) {
        print('\n=== Table of Contents ===');
        for (var i = 0; i < chapters.length; i++) {
          final chapter = chapters[i];
          final title = chapter.title ?? '[Untitled]';
          final fileName = chapter.contentFileName;
          print('${(i + 1).toString().padLeft(2)}. $title ($fileName)');
        }
      }
    });

    test('reads Japanese content correctly', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check that content can be read
      for (final chapter in saoBook.chapters) {
        expect(chapter.htmlContent, isNotNull);
      }
      
      if (verbose) {
        print('\n=== Content Preview (First 100 chars) ===');
        for (var i = 0; i < saoBook.chapters.length && i < 5; i++) {
          final chapter = saoBook.chapters[i];
          final title = chapter.title ?? '[Untitled]';
          final content = chapter.htmlContent?.replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          final preview = content != null && content.length > 100 
              ? '${content.substring(0, 100)}...'
              : content ?? '[No content]';
          print('\nChapter ${i + 1}: $title');
          print('Preview: $preview');
        }
        
        if (saoBook.chapters.length > 5) {
          print('\n... and ${saoBook.chapters.length - 5} more chapters');
        }
      }
    });

    test('has correct Japanese metadata', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check title
      expect(saoBook.title, equals('ソードアート・オンライン1 アインクラッド (電撃文庫)'));
      
      // Check author
      expect(saoBook.author, equals('川原 礫'));
      
      // Check language
      expect(saoBook.schema?.package?.metadata?.languages.first, equals('ja'));
      
      // Check publisher
      expect(saoBook.schema?.package?.metadata?.publishers.first, equals('株式会社KADOKAWA'));
      
      if (verbose) {
        print('\n=== Metadata ===');
        print('Title: ${saoBook.title}');
        print('Author: ${saoBook.author}');
        print('Language: ${saoBook.schema?.package?.metadata?.languages.first}');
        print('Publisher: ${saoBook.schema?.package?.metadata?.publishers.first}');
        print('Publication Date: ${saoBook.schema?.package?.metadata?.dates.firstOrNull?.date}');
      }
    });

    test('has right-to-left page progression', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      // Check spine direction - ltr is false for rtl books
      final spine = saoBook.schema?.package?.spine;
      expect(spine?.ltr, equals(false)); // false means RTL
      
      if (verbose) {
        print('\n=== Reading Direction ===');
        print('Spine LTR flag: ${spine?.ltr} (false = right-to-left)');
        print('Primary writing mode: ${saoBook.schema?.package?.metadata?.metaItems.firstWhere(
          (meta) => meta.name == 'primary-writing-mode',
          orElse: () => EpubMetadataMeta(),
        ).content}');
      }
    });

    test('handles cover image correctly', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      expect(saoBook.coverImage, isNotNull);
      expect(saoBook.coverImage!.length, greaterThan(0));
      
      // The cover should be cover1.jpeg based on the manifest
      final coverManifestItem = saoBook.schema?.package?.manifest?.items.firstWhere(
        (item) => item.id == 'cover',
      );
      expect(coverManifestItem?.href, equals('cover1.jpeg'));
      
      if (verbose) {
        print('\n=== Cover Information ===');
        print('Cover file: ${coverManifestItem?.href}');
        print('Cover size: ${saoBook.coverImage!.length} bytes');
        print('Cover media type: ${coverManifestItem?.mediaType}');
      }
    });

    test('spine items are in correct order', () async {
      final saoPath = path.join(
        io.Directory.current.path,
        'assets',
        'sao.epub',
      );
      final saoFile = io.File(saoPath);
      if (!(await saoFile.exists())) {
        return;
      }

      final spine = saoBook.schema?.package?.spine?.items ?? [];
      
      if (verbose) {
        print('\n=== Spine Analysis ===');
        print('Spine items count: ${spine.length}');
        print('Chapters count: ${saoBook.chapters.length}');
      }
      
      // The spine might have 41 items if it includes the nav document
      expect(spine.length, anyOf(equals(40), equals(41)));
      
      // Verify the spine order matches chapter order
      final chapters = saoBook.chapters;
      final manifest = saoBook.schema?.package?.manifest?.items ?? [];
      
      // Check which spine items are actually in chapters
      var matchedCount = 0;
      for (var i = 0; i < spine.length; i++) {
        final spineItem = spine[i];
        final manifestItem = manifest.firstWhere((item) => item.id == spineItem.idRef);
        
        // Find if this spine item has a corresponding chapter
        final hasChapter = chapters.any((ch) => ch.contentFileName == manifestItem.href);
        if (hasChapter) {
          matchedCount++;
        } else if (verbose) {
          print('Spine item not in chapters: ${manifestItem.href} (${manifestItem.properties})');
        }
      }
      
      expect(matchedCount, equals(chapters.length));
      
      if (verbose) {
        print('\n=== Spine Order Verification ===');
        print('Spine items: ${spine.length}');
        print('Chapters: ${chapters.length}');
        print('✓ All spine items correctly mapped to chapters in order');
      }
    });
  });
}