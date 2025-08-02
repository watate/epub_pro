import 'dart:io';
import 'dart:typed_data';

import 'zip_central_directory.dart';
import 'zip_entry.dart';

/// A lazy ZIP archive that only reads the central directory initially
/// and decompresses files on-demand, providing significant memory savings
/// for large EPUB files.
///
/// Unlike the standard Archive package which decompresses all files immediately,
/// this implementation follows Readium's approach of incremental resource fetching.
class LazyZipArchive {
  final RandomAccessFile? _file;
  final Uint8List? _data;
  final ZipCentralDirectory _centralDirectory;
  final Map<String, ZipEntry> _entries = {};

  LazyZipArchive._(this._file, this._data, this._centralDirectory) {
    // Index entries by name for quick lookup
    for (final entry in _centralDirectory.entries) {
      _entries[entry.fileName] = entry;
    }
  }

  /// Creates a lazy ZIP archive from a file path.
  /// Only reads the central directory, not the file contents.
  static Future<LazyZipArchive> fromFile(String filePath) async {
    final file = await File(filePath).open();
    final centralDirectory = await ZipCentralDirectory.readFromFile(file);
    return LazyZipArchive._(file, null, centralDirectory);
  }

  /// Creates a lazy ZIP archive from byte data.
  /// Only reads the central directory, not the file contents.
  static Future<LazyZipArchive> fromBytes(Uint8List data) async {
    final centralDirectory = await ZipCentralDirectory.readFromBytes(data);
    return LazyZipArchive._(null, data, centralDirectory);
  }

  /// Gets all file names in the archive without decompressing any content.
  List<String> get fileNames => _entries.keys.toList();

  /// Gets a specific file entry by name.
  /// Returns null if the file doesn't exist.
  ZipEntry? getEntry(String fileName) => _entries[fileName];

  /// Checks if a file exists in the archive without decompressing it.
  bool containsFile(String fileName) => _entries.containsKey(fileName);

  /// Reads and decompresses a file's content on-demand.
  /// This is where the actual performance benefit occurs - only the requested
  /// file is decompressed, not the entire archive.
  Future<Uint8List> readFile(String fileName) async {
    final entry = _entries[fileName];
    if (entry == null) {
      throw Exception('File not found in ZIP archive: $fileName');
    }

    if (_file != null) {
      return await entry.readFromFile(_file!);
    } else if (_data != null) {
      return await entry.readFromBytes(_data!);
    } else {
      throw Exception('Invalid archive state: no data source available');
    }
  }

  /// Reads a file's content as a UTF-8 string.
  Future<String> readFileAsString(String fileName) async {
    final bytes = await readFile(fileName);
    return String.fromCharCodes(bytes);
  }

  /// Gets file information without reading the content.
  /// Useful for checking file size, compression ratio, etc.
  ZipFileInfo? getFileInfo(String fileName) {
    final entry = _entries[fileName];
    if (entry == null) return null;

    return ZipFileInfo(
      fileName: entry.fileName,
      compressedSize: entry.compressedSize,
      uncompressedSize: entry.uncompressedSize,
      compressionMethod: entry.compressionMethod,
      lastModified: entry.lastModified,
    );
  }

  /// Gets the total number of files in the archive.
  int get fileCount => _entries.length;

  /// Gets the total compressed size of all files in the archive.
  int get totalCompressedSize => _centralDirectory.entries
      .fold(0, (sum, entry) => sum + entry.compressedSize);

  /// Gets the total uncompressed size of all files in the archive.
  int get totalUncompressedSize => _centralDirectory.entries
      .fold(0, (sum, entry) => sum + entry.uncompressedSize);

  /// Closes the archive and releases resources.
  Future<void> close() async {
    await _file?.close();
  }
}

/// Information about a file in the ZIP archive without loading its content.
class ZipFileInfo {
  final String fileName;
  final int compressedSize;
  final int uncompressedSize;
  final int compressionMethod;
  final DateTime lastModified;

  const ZipFileInfo({
    required this.fileName,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.compressionMethod,
    required this.lastModified,
  });

  /// The compression ratio as a percentage (0-100).
  double get compressionRatio =>
      uncompressedSize > 0 ? (compressedSize / uncompressedSize) * 100 : 0;

  /// Whether the file is compressed.
  bool get isCompressed => compressionMethod != 0;

  @override
  String toString() => 'ZipFileInfo($fileName, '
      'compressed: ${compressedSize}b, '
      'uncompressed: ${uncompressedSize}b, '
      'ratio: ${compressionRatio.toStringAsFixed(1)}%)';
}
