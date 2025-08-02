import 'dart:typed_data';

/// Utility class for handling ZIP compression and decompression.
///
/// This class provides efficient decompression methods that work with
/// the lazy loading ZIP implementation, only decompressing data when
/// actually needed.
class ZipCompression {
  /// Inflates (decompresses) deflated data.
  ///
  /// [compressedData] The deflated/compressed bytes
  /// [expectedSize] The expected uncompressed size for validation
  ///
  /// Returns the decompressed bytes.
  /// Note: This is a placeholder implementation that will be completed later.
  static Uint8List inflate(Uint8List compressedData, int expectedSize) {
    // For now, assume data is already uncompressed (stored method)
    // TODO: Implement proper deflate decompression
    if (compressedData.length == expectedSize) {
      return compressedData;
    }

    throw Exception('Compression not yet implemented - '
        'only stored (uncompressed) files supported');
  }

  /// Checks if data appears to be compressed (deflated).
  static bool isDeflated(Uint8List data) {
    if (data.length < 2) return false;

    // Check for deflate header pattern
    final header = (data[0] << 8) | data[1];
    return (header & 0x0f00) == 0x0800; // Deflate compression method
  }

  /// Gets the compression method from ZIP local header.
  static int getCompressionMethod(Uint8List localHeader, int offset) {
    if (offset + 8 >= localHeader.length) return 0;
    return localHeader[offset + 8] | (localHeader[offset + 9] << 8);
  }
}
