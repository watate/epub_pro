import 'dart:io';
import 'package:epub_pro/epub_pro.dart';

void main() async {
  final epubFile = File('assets/blackSwan.epub');
  final fileName = epubFile.path.split('/').last;

  if (!await epubFile.exists()) {
    print('❌ $fileName not found in assets directory');
    return;
  }

  final bytes = await epubFile.readAsBytes();
  print('📖 Testing $fileName (${bytes.length} bytes)\n');

  // Chapter numbers to debug (1-indexed as they appear in TOC)
  // Change this array to specify which chapters you want to examine
  final chaptersToDebug = [6,7,8]; // Add chapter numbers you want to debug here

  try {
    final book = await EpubReader.readBook(bytes);
    print('✅ Book loaded successfully');
    print('Title: ${book.title}');
    print('Author: ${book.author}');
    // Create flattened chapter list for easy indexing
    final flatChapters = <EpubChapter>[];
    final chapterPaths = <String>[]; // Track hierarchy like "6" or "6.1"
    
    for (int i = 0; i < book.chapters.length; i++) {
      final chapter = book.chapters[i];
      flatChapters.add(chapter);
      chapterPaths.add('${i + 1}');
      
      // Add sub-chapters to flattened list
      for (int j = 0; j < chapter.subChapters.length; j++) {
        flatChapters.add(chapter.subChapters[j]);
        chapterPaths.add('${i + 1}.${j + 1}');
      }
    }
    
    print('Total chapters found: ${book.chapters.length} (${flatChapters.length} including subchapters)\n');

    // Show flattened chapter list for reference
    print('=== FLATTENED CHAPTER LIST ===');
    for (int i = 0; i < flatChapters.length; i++) {
      final chapter = flatChapters[i];
      final path = chapterPaths[i];
      final indent = path.contains('.') ? '  ' : ''; // Indent subchapters
      print('$indent${i + 1}. "${chapter.title}" -> ${chapter.contentFileName} ($path)');
    }

    print('\n${'=' * 60}\n');

    // Debug specific chapters using flattened list
    print('=== CHAPTER CONTENT DEBUG ===');
    for (final chapterNum in chaptersToDebug) {
      if (chapterNum > 0 && chapterNum <= flatChapters.length) {
        final chapter = flatChapters[chapterNum - 1];
        final path = chapterPaths[chapterNum - 1];
        print('📄 CHAPTER $chapterNum ($path): "${chapter.title}"');
        print('   File: ${chapter.contentFileName}');
        print('   Anchor: ${chapter.anchor ?? "none"}');
        
        try {
          final htmlContent = chapter.htmlContent ?? '';
          
          // Strip HTML tags to get plain text
          final plainText = htmlContent
              .replaceAll(RegExp(r'<[^>]*>'), ' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          final words = plainText.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
          final first100Words = words.take(100).join(' ');
          
          print('   HTML length: ${htmlContent.length} chars');
          print('   Plain text length: ${plainText.length} chars');
          print('   Word count: ${words.length}');
          print('   First 100 words:');
          print('   "$first100Words${words.length > 100 ? "..." : ""}"');
          
          // Show if this chapter would be split (>3000 words)
          if (words.length > 3000) {
            print('   ⚠️  This chapter would be SPLIT (>${words.length} words > 3000 threshold)');
          }
          
        } catch (e) {
          print('   ❌ Error reading content: $e');
        }
        
        print(''); // Empty line between chapters
      } else {
        print('❌ Chapter $chapterNum not found (valid range: 1-${flatChapters.length})');
      }
    }

  } catch (e) {
    print('❌ Error loading book: $e');
  }
}