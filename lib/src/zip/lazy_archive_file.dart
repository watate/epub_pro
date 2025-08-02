import 'dart:typed_data';
import 'package:archive/archive.dart';

import 'lazy_zip_archive.dart';
import 'zip_entry.dart';

/// A lazy-loading wrapper around ArchiveFile that provides compatibility
/// with the existing Archive package interface while enabling on-demand
/// content loading.
///
/// This class maintains the same API as ArchiveFile but defers content
/// loading until actually needed, providing the performance benefits
/// of Readium's incremental resource fetching.
class LazyArchiveFile extends ArchiveFile {
  final LazyZipArchive _archive;
  final ZipEntry _entry;
  Uint8List? _cachedContent;

  LazyArchiveFile(this._archive, this._entry)
      : super(_entry.fileName, _entry.uncompressedSize, []);

  /// The file name/path within the archive.
  @override
  String get name => _entry.fileName;

  /// The uncompressed size of the file.
  @override
  int get size => _entry.uncompressedSize;

  /// The file content, loaded on-demand.
  /// This is where the lazy loading magic happens - content is only
  /// decompressed when first accessed.
  @override
  Uint8List get content {
    if (_cachedContent == null) {
      // This is a synchronous getter but we need async loading
      // For now, throw an exception directing users to use the async method
      throw Exception(
          'Content not loaded. Use readContent() for lazy loading or preload with loadContent()');
    }
    return _cachedContent!;
  }

  /// Whether the content has been loaded into memory.
  bool get isContentLoaded => _cachedContent != null;

  /// Loads the content asynchronously and caches it.
  /// This enables lazy loading while maintaining the synchronous interface.
  Future<void> loadContent() async {
    _cachedContent ??= await _archive.readFile(_entry.fileName);
  }

  /// Reads the content asynchronously without caching.
  /// Use this for one-time access to avoid memory usage.
  Future<Uint8List> readContent() async {
    return await _archive.readFile(_entry.fileName);
  }

  /// Reads the content as a string asynchronously.
  Future<String> readContentAsString() async {
    return await _archive.readFileAsString(_entry.fileName);
  }

  /// Forces the content to be loaded if not already cached.
  /// This enables preloading for performance optimization.
  Future<Uint8List> ensureContentLoaded() async {
    if (_cachedContent == null) {
      await loadContent();
    }
    return _cachedContent!;
  }

  /// Clears the cached content to free memory.
  void clearCache() {
    _cachedContent = null;
  }

  /// Gets the compression ratio as a percentage.
  double get compressionRatio => _entry.compressionRatio;

  /// Whether this file is compressed.
  @override
  bool get isCompressed => _entry.isCompressed;

  /// Whether this appears to be a directory.
  @override
  bool get isDirectory => _entry.isDirectory;

  /// The file extension.
  String get extension => _entry.extension;

  /// The compressed size in the archive.
  int get compressedSize => _entry.compressedSize;

  /// The compression method used.
  int get compressionMethod => _entry.compressionMethod;

  /// The last modified date.
  DateTime get lastModified => _entry.lastModified;

  @override
  String toString() => 'LazyArchiveFile(${_entry.fileName}, '
      'compressed: ${_entry.compressedSize}b, '
      'uncompressed: ${_entry.uncompressedSize}b, '
      'loaded: $isContentLoaded)';
}
