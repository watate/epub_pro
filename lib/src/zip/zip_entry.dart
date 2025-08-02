import 'dart:io';
import 'dart:typed_data';

import 'zip_compression.dart';

/// Represents a single file entry in a ZIP archive with lazy loading capabilities.
///
/// This class stores only the metadata about a file (position, size, compression info)
/// and loads the actual content on-demand when requested, following Readium's
/// incremental resource fetching approach.
class ZipEntry {
  final String fileName;
  final int compressedSize;
  final int uncompressedSize;
  final int compressionMethod;
  final int localHeaderOffset;
  final DateTime lastModified;
  final int crc32;

  /// Extra field data from the central directory.
  final Uint8List? extraField;

  /// File comment from the central directory.
  final String comment;

  const ZipEntry({
    required this.fileName,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.compressionMethod,
    required this.localHeaderOffset,
    required this.lastModified,
    required this.crc32,
    this.extraField,
    this.comment = '',
  });

  /// Whether this file is compressed (deflated).
  bool get isCompressed => compressionMethod != 0;

  /// The compression ratio as a percentage.
  double get compressionRatio =>
      uncompressedSize > 0 ? (compressedSize / uncompressedSize) * 100 : 0;

  /// Whether this appears to be a directory entry.
  bool get isDirectory => fileName.endsWith('/');

  /// The file extension (if any).
  String get extension {
    final lastDot = fileName.lastIndexOf('.');
    return lastDot > 0 ? fileName.substring(lastDot + 1).toLowerCase() : '';
  }

  /// Reads the file content from a RandomAccessFile.
  /// This is where the on-demand decompression happens.
  Future<Uint8List> readFromFile(RandomAccessFile file) async {
    // Seek to the local header to get the actual data offset
    await file.setPosition(localHeaderOffset);

    // Read local header to get variable-length fields
    final localHeader = await file.read(30); // Fixed part of local header

    if (localHeader.length < 30) {
      throw Exception('Invalid local header for file: $fileName');
    }

    // Parse local header
    final signature = _readUint32(localHeader, 0);
    if (signature != 0x04034b50) {
      throw Exception('Invalid local file header signature for: $fileName');
    }

    final fileNameLength = _readUint16(localHeader, 26);
    final extraFieldLength = _readUint16(localHeader, 28);

    // Skip variable-length fields
    await file.setPosition(
        localHeaderOffset + 30 + fileNameLength + extraFieldLength);

    // Read compressed data
    final compressedData = await file.read(compressedSize);

    if (compressedData.length != compressedSize) {
      throw Exception('Failed to read complete file data for: $fileName');
    }

    // Decompress if necessary
    return _decompressData(Uint8List.fromList(compressedData));
  }

  /// Reads the file content from byte data.
  Future<Uint8List> readFromBytes(Uint8List data) async {
    if (localHeaderOffset >= data.length) {
      throw Exception('Invalid local header offset for file: $fileName');
    }

    // Parse local header
    final signature = _readUint32(data, localHeaderOffset);
    if (signature != 0x04034b50) {
      throw Exception('Invalid local file header signature for: $fileName');
    }

    final fileNameLength = _readUint16(data, localHeaderOffset + 26);
    final extraFieldLength = _readUint16(data, localHeaderOffset + 28);

    final dataOffset =
        localHeaderOffset + 30 + fileNameLength + extraFieldLength;

    if (dataOffset + compressedSize > data.length) {
      throw Exception('File data extends beyond archive bounds: $fileName');
    }

    // Extract compressed data
    final compressedData =
        data.sublist(dataOffset, dataOffset + compressedSize);

    // Decompress if necessary
    return _decompressData(compressedData);
  }

  /// Decompresses the data based on the compression method.
  Future<Uint8List> _decompressData(Uint8List compressedData) async {
    switch (compressionMethod) {
      case 0: // No compression
        return compressedData;
      case 8: // Deflate
        return ZipCompression.inflate(compressedData, uncompressedSize);
      default:
        throw Exception(
            'Unsupported compression method $compressionMethod for file: $fileName');
    }
  }

  /// Reads a 16-bit unsigned integer from byte data.
  static int _readUint16(Uint8List data, int offset) {
    return data[offset] | (data[offset + 1] << 8);
  }

  /// Reads a 32-bit unsigned integer from byte data.
  static int _readUint32(Uint8List data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  @override
  String toString() => 'ZipEntry($fileName, '
      'compressed: ${compressedSize}b, '
      'uncompressed: ${uncompressedSize}b, '
      'method: $compressionMethod)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZipEntry &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName &&
          localHeaderOffset == other.localHeaderOffset;

  @override
  int get hashCode => fileName.hashCode ^ localHeaderOffset.hashCode;
}
