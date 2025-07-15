import 'package:collection/collection.dart';
import 'package:image/image.dart';

import 'epub_chapter.dart';
import 'epub_content.dart';
import 'epub_schema.dart';

/// Represents a complete EPUB book with all content loaded into memory.
///
/// An [EpubBook] contains all the data from an EPUB file including metadata,
/// content files, and chapters. This is the result of calling [EpubReader.readBook]
/// or similar methods that load the entire book into memory.
///
/// For memory-efficient lazy loading, use [EpubBookRef] instead.
///
/// ## Structure
/// - **Metadata**: title, author(s)
/// - **Schema**: EPUB structure information (OPF, NCX)
/// - **Content**: all files (HTML, CSS, images, fonts)
/// - **Chapters**: hierarchical chapter structure with full HTML content
/// - **Cover**: extracted cover image
///
/// ## Example
/// ```dart
/// final bytes = await File('book.epub').readAsBytes();
/// final book = await EpubReader.readBook(bytes);
///
/// print('Title: ${book.title}');
/// print('Author: ${book.author}');
/// print('Chapters: ${book.chapters.length}');
///
/// // Access first chapter
/// if (book.chapters.isNotEmpty) {
///   final firstChapter = book.chapters[0];
///   print('Chapter: ${firstChapter.title}');
///   print('Content: ${firstChapter.htmlContent}');
/// }
///
/// // Access images
/// book.content?.images?.forEach((name, image) {
///   print('Image: $name');
/// });
/// ```
class EpubBook {
  /// The book's title as specified in the metadata.
  final String? title;

  /// The book's author as a comma-separated string.
  /// For multiple authors, this contains all names joined with commas.
  final String? author;

  /// List of all author names.
  /// Each author is a separate element in the list.
  final List<String?> authors;

  /// The complete EPUB schema information.
  /// Contains OPF package data, navigation (NCX), and other structural information.
  final EpubSchema? schema;

  /// All content files in the EPUB.
  /// Includes HTML files, CSS stylesheets, images, fonts, and other resources.
  final EpubContent? content;

  /// The book's cover image, if available.
  /// Extracted from the OPF manifest or as a fallback from the first image.
  final Image? coverImage;

  /// The hierarchical chapter structure.
  /// Each chapter may contain subchapters, representing the book's navigation structure.
  /// With NCX/spine reconciliation, all content files are guaranteed to be accessible.
  final List<EpubChapter> chapters;

  const EpubBook({
    this.title,
    this.author,
    this.authors = const <String>[],
    this.schema,
    this.content,
    this.coverImage,
    this.chapters = const <EpubChapter>[],
  });

  @override
  int get hashCode {
    final hash = const DeepCollectionEquality().hash;
    return title.hashCode ^
        author.hashCode ^
        hash(authors) ^
        schema.hashCode ^
        content.hashCode ^
        coverImage.hashCode ^
        hash(chapters);
  }

  @override
  bool operator ==(covariant EpubBook other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.title == title &&
        other.author == author &&
        listEquals(other.authors, authors) &&
        other.schema == schema &&
        other.content == content &&
        other.coverImage == coverImage &&
        listEquals(other.chapters, chapters);
  }
}
