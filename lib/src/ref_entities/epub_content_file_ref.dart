import 'dart:async';
import 'dart:convert' as convert;

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';

import '../entities/epub_content_type.dart';
import '../utils/zip_path_utils.dart';
import '../zip/lazy_archive_file.dart';
import 'epub_book_ref.dart';

abstract class EpubContentFileRef {
  final EpubBookRef epubBookRef;
  final String? fileName;
  final EpubContentType? contentType;
  final String? contentMimeType;

  const EpubContentFileRef({
    required this.epubBookRef,
    this.fileName,
    this.contentType,
    this.contentMimeType,
  });

  @override
  int get hashCode {
    return epubBookRef.hashCode ^
        fileName.hashCode ^
        contentType.hashCode ^
        contentMimeType.hashCode;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpubContentFileRef &&
        other.fileName == fileName &&
        other.contentType == contentType &&
        other.contentMimeType == contentMimeType;
  }

  ArchiveFile getContentFileEntry() {
    var contentFilePath = ZipPathUtils.combine(
        epubBookRef.schema!.contentDirectoryPath, fileName);
    var contentFileEntry = epubBookRef.epubArchive.files
        .firstWhereOrNull((ArchiveFile x) => x.name == contentFilePath);
    if (contentFileEntry == null) {
      throw Exception(
          'EPUB parsing error: file $contentFilePath not found in archive.');
    }
    return contentFileEntry;
  }

  List<int> getContentStream() {
    return openContentStream(getContentFileEntry());
  }

  Future<List<int>> openContentStreamAsync(ArchiveFile contentFileEntry) async {
    // Handle lazy loading for LazyArchiveFile
    if (contentFileEntry is LazyArchiveFile) {
      final content = await contentFileEntry.readContent();
      if (content.isEmpty) {
        throw Exception(
            'Incorrect EPUB file: content file "$fileName" specified in manifest is not found.');
      }
      return content;
    } else {
      // Fallback for standard ArchiveFile
      var contentStream = <int>[];
      if (contentFileEntry.content.isEmpty) {
        throw Exception(
            'Incorrect EPUB file: content file "$fileName" specified in manifest is not found.');
      }
      contentStream.addAll(contentFileEntry.content);
      return contentStream;
    }
  }

  List<int> openContentStream(ArchiveFile contentFileEntry) {
    // This is the legacy synchronous method - try to use cached content for lazy files
    if (contentFileEntry is LazyArchiveFile) {
      if (contentFileEntry.isContentLoaded) {
        return contentFileEntry.content;
      } else {
        throw Exception(
            'Content not loaded for lazy file: $fileName. Use readContentAsBytes() for async loading.');
      }
    } else {
      var contentStream = <int>[];
      if (contentFileEntry.content.isEmpty) {
        throw Exception(
            'Incorrect EPUB file: content file "$fileName" specified in manifest is not found.');
      }
      contentStream.addAll(contentFileEntry.content);
      return contentStream;
    }
  }

  Future<List<int>> readContentAsBytes() async {
    var contentFileEntry = getContentFileEntry();
    var content = await openContentStreamAsync(contentFileEntry);
    return content;
  }

  Future<String> readContentAsText() async {
    var content = await readContentAsBytes();
    var result = convert.utf8.decode(content);
    return result;
  }
}
