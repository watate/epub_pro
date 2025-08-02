import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'zip_entry.dart';

/// Reads and parses the ZIP central directory to enable lazy loading.
///
/// The central directory contains metadata about all files in the ZIP
/// without their actual content, allowing us to implement true lazy loading
/// by only reading what we need when we need it.
class ZipCentralDirectory {
  final List<ZipEntry> entries;
  final String comment;

  const ZipCentralDirectory({
    required this.entries,
    this.comment = '',
  });

  /// Reads the central directory from a RandomAccessFile.
  static Future<ZipCentralDirectory> readFromFile(RandomAccessFile file) async {
    // Find end of central directory record
    final endRecord = await _findEndOfCentralDirectory(file);

    if (endRecord == null) {
      throw Exception('Invalid ZIP file: End of central directory not found');
    }

    final totalEntries = endRecord['totalEntries'] as int;
    final centralDirOffset = endRecord['centralDirOffset'] as int;
    final comment = endRecord['comment'] as String;

    // Read central directory entries
    await file.setPosition(centralDirOffset);
    final entries = <ZipEntry>[];

    for (var i = 0; i < totalEntries; i++) {
      final entry = await _readCentralDirectoryEntry(file);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return ZipCentralDirectory(entries: entries, comment: comment);
  }

  /// Reads the central directory from byte data.
  static Future<ZipCentralDirectory> readFromBytes(Uint8List data) async {
    // Find end of central directory record
    final endRecord = _findEndOfCentralDirectoryInBytes(data);

    if (endRecord == null) {
      throw Exception('Invalid ZIP file: End of central directory not found');
    }

    final totalEntries = endRecord['totalEntries'] as int;
    final centralDirOffset = endRecord['centralDirOffset'] as int;
    final comment = endRecord['comment'] as String;

    // Read central directory entries
    var offset = centralDirOffset;
    final entries = <ZipEntry>[];

    for (var i = 0; i < totalEntries; i++) {
      final entry = _readCentralDirectoryEntryFromBytes(data, offset);
      if (entry != null) {
        entries.add(entry['entry'] as ZipEntry);
        offset = entry['nextOffset'] as int;
      }
    }

    return ZipCentralDirectory(entries: entries, comment: comment);
  }

  /// Finds the end of central directory record by searching from the end.
  static Future<Map<String, dynamic>?> _findEndOfCentralDirectory(
      RandomAccessFile file) async {
    final fileLength = await file.length();

    // Search backwards from end of file for EOCD signature
    const maxCommentLength = 65535;
    final searchLength =
        (fileLength < maxCommentLength) ? fileLength : maxCommentLength + 22;

    await file.setPosition(fileLength - searchLength);
    final searchData = await file.read(searchLength);

    // Look for end of central directory signature (0x06054b50)
    for (var i = searchData.length - 22; i >= 0; i--) {
      if (_readUint32(searchData, i) == 0x06054b50) {
        final diskNumber = _readUint16(searchData, i + 4);
        final diskWithCentralDir = _readUint16(searchData, i + 6);
        final entriesOnDisk = _readUint16(searchData, i + 8);
        final totalEntries = _readUint16(searchData, i + 10);
        final centralDirSize = _readUint32(searchData, i + 12);
        final centralDirOffset = _readUint32(searchData, i + 16);
        final commentLength = _readUint16(searchData, i + 20);

        String comment = '';
        if (commentLength > 0 && i + 22 + commentLength <= searchData.length) {
          comment =
              utf8.decode(searchData.sublist(i + 22, i + 22 + commentLength));
        }

        return {
          'diskNumber': diskNumber,
          'diskWithCentralDir': diskWithCentralDir,
          'entriesOnDisk': entriesOnDisk,
          'totalEntries': totalEntries,
          'centralDirSize': centralDirSize,
          'centralDirOffset': centralDirOffset,
          'comment': comment,
        };
      }
    }

    return null;
  }

  /// Finds the end of central directory record in byte data.
  static Map<String, dynamic>? _findEndOfCentralDirectoryInBytes(
      Uint8List data) {
    // Search backwards from end for EOCD signature
    for (var i = data.length - 22; i >= 0; i--) {
      if (_readUint32(data, i) == 0x06054b50) {
        final totalEntries = _readUint16(data, i + 10);
        final centralDirOffset = _readUint32(data, i + 16);
        final commentLength = _readUint16(data, i + 20);

        String comment = '';
        if (commentLength > 0 && i + 22 + commentLength <= data.length) {
          comment = utf8.decode(data.sublist(i + 22, i + 22 + commentLength));
        }

        return {
          'totalEntries': totalEntries,
          'centralDirOffset': centralDirOffset,
          'comment': comment,
        };
      }
    }

    return null;
  }

  /// Reads a single central directory entry from file.
  static Future<ZipEntry?> _readCentralDirectoryEntry(
      RandomAccessFile file) async {
    final header = await file.read(46); // Fixed part of central directory entry

    if (header.length < 46) return null;

    final signature = _readUint32(header, 0);
    if (signature != 0x02014b50) return null; // Central directory signature

    final compressionMethod = _readUint16(header, 10);
    final lastModTime = _readUint16(header, 12);
    final lastModDate = _readUint16(header, 14);
    final crc32 = _readUint32(header, 16);
    final compressedSize = _readUint32(header, 20);
    final uncompressedSize = _readUint32(header, 24);
    final fileNameLength = _readUint16(header, 28);
    final extraFieldLength = _readUint16(header, 30);
    final commentLength = _readUint16(header, 32);
    final localHeaderOffset = _readUint32(header, 42);

    // Read variable-length fields
    final fileName = utf8.decode(await file.read(fileNameLength));
    final extraField =
        extraFieldLength > 0 ? await file.read(extraFieldLength) : <int>[];
    final comment =
        commentLength > 0 ? utf8.decode(await file.read(commentLength)) : '';

    final lastModified = _dosDateTimeToDateTime(lastModDate, lastModTime);

    return ZipEntry(
      fileName: fileName,
      compressedSize: compressedSize,
      uncompressedSize: uncompressedSize,
      compressionMethod: compressionMethod,
      localHeaderOffset: localHeaderOffset,
      lastModified: lastModified,
      crc32: crc32,
      extraField: extraFieldLength > 0 ? Uint8List.fromList(extraField) : null,
      comment: comment,
    );
  }

  /// Reads a single central directory entry from byte data.
  static Map<String, dynamic>? _readCentralDirectoryEntryFromBytes(
      Uint8List data, int offset) {
    if (offset + 46 > data.length) return null;

    final signature = _readUint32(data, offset);
    if (signature != 0x02014b50) return null; // Central directory signature

    final compressionMethod = _readUint16(data, offset + 10);
    final lastModTime = _readUint16(data, offset + 12);
    final lastModDate = _readUint16(data, offset + 14);
    final crc32 = _readUint32(data, offset + 16);
    final compressedSize = _readUint32(data, offset + 20);
    final uncompressedSize = _readUint32(data, offset + 24);
    final fileNameLength = _readUint16(data, offset + 28);
    final extraFieldLength = _readUint16(data, offset + 30);
    final commentLength = _readUint16(data, offset + 32);
    final localHeaderOffset = _readUint32(data, offset + 42);

    final dataOffset = offset + 46;
    final totalLength = 46 + fileNameLength + extraFieldLength + commentLength;

    if (dataOffset + fileNameLength + extraFieldLength + commentLength >
        data.length) {
      return null;
    }

    final fileName =
        utf8.decode(data.sublist(dataOffset, dataOffset + fileNameLength));
    final extraField = extraFieldLength > 0
        ? data.sublist(dataOffset + fileNameLength,
            dataOffset + fileNameLength + extraFieldLength)
        : <int>[];
    final comment = commentLength > 0
        ? utf8.decode(data.sublist(
            dataOffset + fileNameLength + extraFieldLength,
            dataOffset + fileNameLength + extraFieldLength + commentLength))
        : '';

    final lastModified = _dosDateTimeToDateTime(lastModDate, lastModTime);

    final entry = ZipEntry(
      fileName: fileName,
      compressedSize: compressedSize,
      uncompressedSize: uncompressedSize,
      compressionMethod: compressionMethod,
      localHeaderOffset: localHeaderOffset,
      lastModified: lastModified,
      crc32: crc32,
      extraField: extraFieldLength > 0 ? Uint8List.fromList(extraField) : null,
      comment: comment,
    );

    return {
      'entry': entry,
      'nextOffset': offset + totalLength,
    };
  }

  /// Converts DOS date/time to DateTime.
  static DateTime _dosDateTimeToDateTime(int dosDate, int dosTime) {
    final year = 1980 + ((dosDate >> 9) & 0x7f);
    final month = (dosDate >> 5) & 0x0f;
    final day = dosDate & 0x1f;
    final hour = (dosTime >> 11) & 0x1f;
    final minute = (dosTime >> 5) & 0x3f;
    final second = (dosTime & 0x1f) * 2;

    return DateTime(year, month, day, hour, minute, second);
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
}
