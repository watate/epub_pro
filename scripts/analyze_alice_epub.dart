import 'dart:io';
import 'package:epub_pro/epub_pro.dart';

void main() async {
  print('=== Alice\'s Adventures Underground EPUB Analysis ===\n');

  final epubFile = File('assets/alicesAdventuresUnderGround.epub');
  if (!epubFile.existsSync()) {
    print(
        'ERROR: Alice EPUB file not found at assets/alicesAdventuresUnderGround.epub');
    exit(1);
  }

  try {
    final epubBytes = await epubFile.readAsBytes();
    print(
        '📖 Loading EPUB file (${(epubBytes.length / 1024).toStringAsFixed(1)} KB)...\n');

    // Load the EPUB
    final book = await EpubReader.readBook(epubBytes);

    print('📚 Book Metadata:');
    print('  Title: ${book.title}');
    print('  Author: ${book.author}');
    print('  Authors: ${book.authors.join(', ')}');
    final languages = book.schema?.package?.metadata?.languages ?? [];
    print(
        '  Language: ${languages.isNotEmpty ? languages.join(', ') : 'Unknown'}');

    // Analyze chapters
    print('\n📑 Chapter Structure:');
    print('  Total chapters: ${book.chapters.length}');

    for (int i = 0; i < book.chapters.length; i++) {
      final chapter = book.chapters[i];
      final content = chapter.htmlContent ?? '';
      final wordCount = _countWords(content);
      final charCount = _stripHtmlTags(content).length;

      print('  Chapter ${i + 1}: "${chapter.title ?? 'Untitled'}"');
      print('    File: ${chapter.contentFileName ?? 'Unknown'}');
      print('    Words: $wordCount | Characters: $charCount');

      if (i < 3) {
        // Show content preview for first few chapters
        final textContent = _stripHtmlTags(content);
        final preview = textContent.length > 200
            ? '${textContent.substring(0, 200)}...'
            : textContent;
        print('    Preview: ${preview.replaceAll('\n', ' ').trim()}');
      }

      // Find interesting passages for CFI testing
      final textContent = _stripHtmlTags(content).toLowerCase();
      final interestingQuotes = [
        'who are you',
        'the first thing i\'ve got to do',
        'you are old, father william',
        'alice to herself',
        'caterpillar',
        'keep your temper',
      ];

      for (final quote in interestingQuotes) {
        final index = textContent.indexOf(quote);
        if (index >= 0) {
          print('    📍 Found quote "$quote" at character offset $index');

          // Find the actual position in the original content
          final originalIndex = _findInOriginalContent(content, quote);
          if (originalIndex >= 0) {
            print('    📍 Original HTML offset: $originalIndex');
          }
        }
      }
      print('');
    }

    // Analyze for CFI generation
    print('🎯 CFI Testing Data:');
    await _analyzeCFIPositions(book);

    // Memory and performance info
    print('\n📊 Performance Metrics:');
    final totalWords = book.chapters
        .fold(0, (sum, ch) => sum + _countWords(ch.htmlContent ?? ''));
    final totalChars =
        book.chapters.fold(0, (sum, ch) => sum + (ch.htmlContent?.length ?? 0));
    print('  Total words: $totalWords');
    print('  Total characters: $totalChars');
    print(
        '  Average words per chapter: ${(totalWords / book.chapters.length).toStringAsFixed(1)}');

    // Spine analysis for CFI
    if (book.schema?.package?.spine != null) {
      print('\n🗂️ Spine Structure (for CFI generation):');
      final spine = book.schema!.package!.spine!;
      for (int i = 0; i < spine.items.length; i++) {
        final item = spine.items[i];
        print('  Spine[$i]: ${item.idRef} (linear: ${item.isLinear})');
      }
    }

    print('\n✅ Analysis complete! Use this data for position tracking tests.');
  } catch (e, stackTrace) {
    print('❌ Error analyzing EPUB: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

int _countWords(String htmlContent) {
  final textContent = _stripHtmlTags(htmlContent);
  return textContent
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .length;
}

String _stripHtmlTags(String htmlContent) {
  return htmlContent
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int _findInOriginalContent(String htmlContent, String searchText) {
  // Find the position in the original HTML content, considering tags
  final lowerContent = htmlContent.toLowerCase();
  return lowerContent.indexOf(searchText.toLowerCase());
}

Future<void> _analyzeCFIPositions(EpubBook book) async {
  print('  Looking for specific test passages...\n');

  final testPassages = [
    {
      'id': 'chapter3_opening',
      'text': 'The first thing I\'ve got to do',
      'description': 'Chapter III opening line - good for position tracking'
    },
    {
      'id': 'caterpillar_question',
      'text': 'Who are you?',
      'description': 'Caterpillar\'s famous question - short, distinctive text'
    },
    {
      'id': 'father_william',
      'text': 'You are old, father William',
      'description': 'Famous poem start - good for range testing'
    },
    {
      'id': 'alice_self_talk',
      'text': 'said Alice to herself',
      'description': 'Common phrase - good for multiple position testing'
    },
    {
      'id': 'keep_temper',
      'text': 'Keep your temper',
      'description': 'Caterpillar advice - mid-chapter position'
    },
  ];

  for (final passage in testPassages) {
    print('  🔍 Searching for: "${passage['text']}"');

    for (int chapterIndex = 0;
        chapterIndex < book.chapters.length;
        chapterIndex++) {
      final chapter = book.chapters[chapterIndex];
      final content = chapter.htmlContent ?? '';
      final textContent = _stripHtmlTags(content);

      final index = textContent
          .toLowerCase()
          .indexOf((passage['text'] as String).toLowerCase());
      if (index >= 0) {
        final htmlIndex =
            _findInOriginalContent(content, passage['text'] as String);

        print(
            '    📍 Found in Chapter ${chapterIndex + 1}: "${chapter.title}"');
        print('    📍 Text position: $index | HTML position: $htmlIndex');
        print('    📍 Context: ${_getContext(textContent, index, 50)}');
        print('    📍 Use case: ${passage['description']}');

        // Calculate approximate CFI components
        final chapterProgress = index / textContent.length;
        print(
            '    📍 Chapter progress: ${(chapterProgress * 100).toStringAsFixed(1)}%');

        break; // Found in this chapter, move to next passage
      }
    }
    print('');
  }
}

String _getContext(String text, int position, int contextLength) {
  final start = (position - contextLength).clamp(0, text.length);
  final end = (position + contextLength).clamp(0, text.length);
  final context = text.substring(start, end).replaceAll('\n', ' ').trim();

  if (start > 0) {
    return '...$context';
  } else if (end < text.length) {
    return '$context...';
  }
  return context;
}
