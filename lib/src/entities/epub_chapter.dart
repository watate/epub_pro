import 'package:collection/collection.dart';

/// Represents a chapter in an EPUB book.
///
/// Chapters form a hierarchical structure where each chapter can contain
/// subchapters. This structure is derived from the EPUB's navigation (NCX/NAV)
/// with smart reconciliation to include all spine items.
///
/// ## Properties
/// - [title]: The chapter's title from navigation
/// - [contentFileName]: The HTML file containing the chapter content
/// - [anchor]: Optional anchor/fragment for linking to specific sections
/// - [htmlContent]: The full HTML content of the chapter
/// - [subChapters]: Child chapters in the hierarchy
///
/// ## Hierarchy Example
/// ```
/// Chapter 1
/// ├── Section 1.1
/// ├── Section 1.2
/// │   ├── Subsection 1.2.1
/// │   └── Subsection 1.2.2
/// └── Section 1.3
/// ```
///
/// ## NCX/Spine Reconciliation
/// When the navigation doesn't include all spine items, orphaned items
/// are inserted as subchapters under their logical parent, ensuring
/// all content remains accessible.
///
/// ## Example
/// ```dart
/// void printChapterTree(EpubChapter chapter, {int indent = 0}) {
///   print('${'  ' * indent}${chapter.title ?? chapter.contentFileName}');
///   for (final sub in chapter.subChapters) {
///     printChapterTree(sub, indent: indent + 1);
///   }
/// }
/// ```
class EpubChapter {
  /// The chapter's title as specified in the navigation.
  /// May be null for spine items not included in the NCX/NAV.
  final String? title;

  /// The filename of the HTML content file.
  /// This is the relative path from the EPUB's content directory.
  final String? contentFileName;

  /// Optional anchor/fragment identifier.
  /// Used to link to specific sections within the HTML file (e.g., "#section1").
  final String? anchor;

  /// The complete HTML content of the chapter.
  /// Contains the full HTML including tags, ready for rendering.
  final String? htmlContent;

  /// Child chapters in the hierarchy.
  /// May include both explicit subchapters from navigation and
  /// orphaned spine items reconciled as children.
  final List<EpubChapter> subChapters;

  const EpubChapter({
    this.title,
    this.contentFileName,
    this.anchor,
    this.htmlContent,
    this.subChapters = const <EpubChapter>[],
  });

  @override
  int get hashCode {
    return title.hashCode ^
        contentFileName.hashCode ^
        anchor.hashCode ^
        htmlContent.hashCode ^
        const DeepCollectionEquality().hash(subChapters);
  }

  @override
  bool operator ==(covariant EpubChapter other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other.title == title &&
        other.contentFileName == contentFileName &&
        other.anchor == anchor &&
        other.htmlContent == htmlContent &&
        listEquals(other.subChapters, subChapters);
  }

  @override
  String toString() {
    return 'Title: $title, Subchapter count: ${subChapters.length}';
  }
}
