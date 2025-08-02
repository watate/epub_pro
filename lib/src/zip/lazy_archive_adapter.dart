import 'dart:typed_data';
import 'package:archive/archive.dart';

import 'lazy_archive_file.dart';
import 'lazy_zip_archive.dart';

/// An adapter that makes LazyZipArchive compatible with the Archive interface.
/// 
/// This enables drop-in replacement of the standard Archive with lazy loading
/// while maintaining full compatibility with existing epub_pro code.
/// 
/// The adapter provides the same interface as Archive but with lazy loading
/// behavior inspired by Readium's incremental resource fetching.
class LazyArchiveAdapter extends Archive {
  final LazyZipArchive _lazyArchive;
  final List<LazyArchiveFile> _lazyFiles;
  
  LazyArchiveAdapter._(this._lazyArchive, this._lazyFiles);
  
  /// Creates a lazy archive adapter from bytes.
  static Future<LazyArchiveAdapter> fromBytes(List<int> bytes) async {
    final lazyArchive = await LazyZipArchive.fromBytes(Uint8List.fromList(bytes));
    final lazyFiles = <LazyArchiveFile>[];
    
    // Create lazy file wrappers for each entry
    for (final fileName in lazyArchive.fileNames) {
      final entry = lazyArchive.getEntry(fileName);
      if (entry != null) {
        lazyFiles.add(LazyArchiveFile(lazyArchive, entry));
      }
    }
    
    return LazyArchiveAdapter._(lazyArchive, lazyFiles);
  }
  
  /// Creates a lazy archive adapter from a file path.
  static Future<LazyArchiveAdapter> fromFile(String filePath) async {
    final lazyArchive = await LazyZipArchive.fromFile(filePath);
    final lazyFiles = <LazyArchiveFile>[];
    
    // Create lazy file wrappers for each entry
    for (final fileName in lazyArchive.fileNames) {
      final entry = lazyArchive.getEntry(fileName);
      if (entry != null) {
        lazyFiles.add(LazyArchiveFile(lazyArchive, entry));
      }
    }
    
    return LazyArchiveAdapter._(lazyArchive, lazyFiles);
  }
  
  /// Gets all files in the archive.
  /// Unlike the standard Archive, files are not pre-loaded.
  @override
  List<ArchiveFile> get files => _lazyFiles.cast<ArchiveFile>();
  
  /// Adds a file to the archive (not supported in read-only mode).
  @override
  ArchiveFile addFile(ArchiveFile file) {
    throw UnsupportedError('Adding files not supported in lazy read-only mode');
  }
  
  /// Finds a file by name.
  @override
  ArchiveFile? findFile(String name) {
    return _lazyFiles.cast<ArchiveFile?>().firstWhere(
      (file) => file?.name == name,
      orElse: () => null,
    );
  }
  
  /// Gets the number of files in the archive.
  @override
  int numberOfFiles() => _lazyFiles.length;
  
  /// Removes all files from the archive (not supported in read-only mode).
  @override
  Future<void> clear() async {
    throw UnsupportedError('Clearing files not supported in lazy read-only mode');
  }
  
  /// Gets the total compressed size of all files.
  int get totalCompressedSize => _lazyArchive.totalCompressedSize;
  
  /// Gets the total uncompressed size of all files.
  int get totalUncompressedSize => _lazyArchive.totalUncompressedSize;
  
  /// Preloads content for frequently accessed files.
  /// This can improve performance by loading commonly used files
  /// (like OPF, NCX) into memory upfront.
  Future<void> preloadCriticalFiles() async {
    final criticalExtensions = {'.opf', '.ncx', '.xml'};
    final criticalFiles = _lazyFiles.where((file) => 
        criticalExtensions.contains(file.extension.toLowerCase()));
    
    await Future.wait(criticalFiles.map((file) => file.loadContent()));
  }
  
  /// Preloads content for specific files by name.
  Future<void> preloadFiles(List<String> fileNames) async {
    final filesToLoad = _lazyFiles.where((file) => 
        fileNames.contains(file.name));
    
    await Future.wait(filesToLoad.map((file) => file.loadContent()));
  }
  
  /// Clears cached content for all files to free memory.
  void clearAllCaches() {
    for (final file in _lazyFiles) {
      file.clearCache();
    }
  }
  
  /// Gets memory usage statistics.
  Map<String, dynamic> getMemoryStats() {
    final loadedFiles = _lazyFiles.where((file) => file.isContentLoaded).length;
    final totalFiles = _lazyFiles.length;
    final loadedSize = _lazyFiles
        .where((file) => file.isContentLoaded)
        .fold(0, (sum, file) => sum + file.size);
    
    return {
      'loadedFiles': loadedFiles,
      'totalFiles': totalFiles,
      'loadedSize': loadedSize,
      'totalSize': totalUncompressedSize,
      'memoryEfficiency': totalFiles > 0 ? (1 - loadedFiles / totalFiles) * 100 : 0,
    };
  }
  
  /// Closes the archive and releases resources.
  Future<void> close() async {
    clearAllCaches();
    await _lazyArchive.close();
  }
  
  @override
  String toString() => 'LazyArchiveAdapter(${_lazyFiles.length} files, '
      'memory stats: ${getMemoryStats()})';
}