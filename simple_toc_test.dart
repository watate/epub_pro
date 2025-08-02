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

  // Test 1: Standard readBook
  print('=== TEST 1: EpubReader.readBook() ===');
  try {
    final book = await EpubReader.readBook(bytes);
    print('✅ Book loaded successfully');
    print('Title: ${book.title}');
    print('Author: ${book.author}');
    print('Chapters found: ${book.chapters.length}');

    for (int i = 0; i < book.chapters.length; i++) {
      final chapter = book.chapters[i];
      print('  ${i + 1}. "${chapter.title}"');

      // Show sub-chapters if any
      for (int j = 0; j < chapter.subChapters.length; j++) {
        print('     ${i + 1}.${j + 1} "${chapter.subChapters[j].title}"');
      }
    }

    // Show images
    if (book.content?.images != null && book.content!.images.isNotEmpty) {
      print('\nImages found: ${book.content!.images.length}');
      for (var image in book.content!.images.values.take(5)) {
        print('  - ${image.fileName} (${image.contentType})');
      }
    }

    if (book.coverImage != null) {
      print('\nCover image: Found (${book.coverImage!.length} bytes)');
    }
  } catch (e) {
    print('❌ Error with readBook(): $e');
  }

  print('\n${'=' * 50}\n');

  // Test 2: readBookWithSplitChapters
  print('=== TEST 2: EpubReader.readBookWithSplitChapters() ===');
  try {
    final book = await EpubReader.readBookWithSplitChapters(bytes);
    print('✅ Book with splitting loaded successfully');
    print('Title: ${book.title}');
    print('Author: ${book.author}');
    print('Chapters found: ${book.chapters.length}');

    for (int i = 0; i < book.chapters.length; i++) {
      final chapter = book.chapters[i];
      print('  ${i + 1}. "${chapter.title}"');

      // Show sub-chapters if any
      for (int j = 0; j < chapter.subChapters.length; j++) {
        print('     ${i + 1}.${j + 1} "${chapter.subChapters[j].title}"');
      }
    }
  } catch (e) {
    print('❌ Error with readBookWithSplitChapters(): $e');
  }
}
