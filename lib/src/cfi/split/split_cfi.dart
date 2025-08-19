import '../core/cfi.dart';

/// A CFI extension that provides precise positioning within split chapters.
///
/// Split CFI extends the standard EPUB CFI format to handle chapters that have
/// been split into multiple parts for better readability. It maintains full
/// backward compatibility with standard CFI while adding split part information.
///
/// ## Split CFI Format
/// ```
/// Standard CFI: epubcfi(/6/4!/4/10/2:15)
/// Split CFI:    epubcfi(/6/4!/split=2,total=3/4/10/2:15)
/// ```
///
/// ## Components
/// - `split=2` - Part number (1-based) within the split chapter
/// - `total=3` - Total number of parts for validation
/// - Maintains all standard CFI components (spine, DOM path, offsets)
///
/// ## Usage
/// ```dart
/// // Create split CFI from standard CFI and split info
/// final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
/// final splitCFI = SplitCFI.fromStandardCFI(
///   standardCFI,
///   splitPart: 2,
///   totalParts: 3,
/// );
///
/// // Parse split CFI string
/// final parsedSplitCFI = SplitCFI('epubcfi(/6/4!/split=2,total=3/4/10/2:15)');
///
/// // Convert back to standard CFI
/// final converted = splitCFI.toStandardCFI();
/// ```
class SplitCFI extends CFI {
  /// The part number within the split chapter (1-based).
  final int splitPart;

  /// The total number of parts in the split chapter.
  final int totalParts;

  /// The original standard CFI without split information.
  late final CFI _baseCFI;

  /// Creates a split CFI from a CFI string containing split notation.
  ///
  /// Throws [FormatException] if the CFI string is malformed or contains
  /// invalid split information.
  SplitCFI(String cfiString)
      : splitPart = _extractSplitPart(cfiString),
        totalParts = _extractTotalParts(cfiString),
        super(cfiString) {
    _validateSplitInfo();
    _baseCFI = CFI(_removeSplitInfo(cfiString));
  }

  /// Creates a split CFI from a standard CFI and split information.
  ///
  /// This is useful when you have a standard CFI and want to add split
  /// part information to make it more precise.
  ///
  /// ```dart
  /// final standardCFI = CFI('epubcfi(/6/4!/4/10/2:15)');
  /// final splitCFI = SplitCFI.fromStandardCFI(
  ///   standardCFI,
  ///   splitPart: 2,
  ///   totalParts: 3,
  /// );
  /// ```
  SplitCFI.fromStandardCFI(
    CFI standardCFI, {
    required this.splitPart,
    required this.totalParts,
  }) : super(_buildSplitCFIString(standardCFI.raw, splitPart, totalParts)) {
    _validateSplitInfo();
    _baseCFI = standardCFI;
  }

  /// The base CFI without split information.
  ///
  /// This can be used to interact with systems that don't understand
  /// split CFI notation.
  CFI get baseCFI => _baseCFI;

  /// Whether this CFI references a split chapter part.
  ///
  /// Always returns true for SplitCFI instances.
  bool get isSplitCFI => true;

  /// Converts this split CFI to a standard CFI.
  ///
  /// The returned CFI will point to the same logical position but without
  /// split part information. This is useful for backward compatibility.
  CFI toStandardCFI() => _baseCFI;

  /// Creates a copy of this split CFI with different split information.
  ///
  /// Useful for mapping positions between different parts of the same
  /// split chapter.
  SplitCFI copyWithSplitInfo({
    int? splitPart,
    int? totalParts,
  }) {
    return SplitCFI.fromStandardCFI(
      _baseCFI,
      splitPart: splitPart ?? this.splitPart,
      totalParts: totalParts ?? this.totalParts,
    );
  }

  /// Compares this split CFI with another CFI for reading order.
  ///
  /// Split CFIs are compared first by their base CFI position, then by
  /// split part number if they reference the same base position.
  @override
  int compare(CFI other) {
    // Compare base positions first
    final baseComparison =
        _baseCFI.compare(other is SplitCFI ? other._baseCFI : other);

    if (baseComparison != 0) {
      return baseComparison;
    }

    // If base positions are equal, compare split parts
    if (other is SplitCFI) {
      return splitPart.compareTo(other.splitPart);
    }

    // Split CFI comes after standard CFI at same base position
    return 1;
  }

  /// Validates that split information is valid.
  void _validateSplitInfo() {
    if (splitPart < 1) {
      throw FormatException('Split part must be >= 1, got: $splitPart');
    }
    if (totalParts < 1) {
      throw FormatException('Total parts must be >= 1, got: $totalParts');
    }
    if (splitPart > totalParts) {
      throw FormatException(
          'Split part ($splitPart) cannot be greater than total parts ($totalParts)');
    }
  }

  /// Extracts the split part number from a CFI string.
  static int _extractSplitPart(String cfiString) {
    final match = RegExp(r'/split=(\d+),total=\d+/').firstMatch(cfiString);
    if (match == null) {
      throw FormatException('No split information found in CFI: $cfiString');
    }
    return int.parse(match.group(1)!);
  }

  /// Extracts the total parts from a CFI string.
  static int _extractTotalParts(String cfiString) {
    final match = RegExp(r'/split=\d+,total=(\d+)/').firstMatch(cfiString);
    if (match == null) {
      throw FormatException('No split information found in CFI: $cfiString');
    }
    return int.parse(match.group(1)!);
  }

  /// Removes split information from a CFI string to get the base CFI.
  static String _removeSplitInfo(String cfiString) {
    return cfiString.replaceAll(RegExp(r'/split=\d+,total=\d+'), '');
  }

  /// Builds a split CFI string from a standard CFI and split information.
  static String _buildSplitCFIString(
    String standardCFI,
    int splitPart,
    int totalParts,
  ) {
    // Find the insertion point after the spine reference
    final spineEndMatch = RegExp(r'(/6/\d+!)').firstMatch(standardCFI);
    if (spineEndMatch == null) {
      throw FormatException('Invalid CFI format: $standardCFI');
    }

    final insertionPoint = spineEndMatch.end;
    final splitInfo = '/split=$splitPart,total=$totalParts';

    return standardCFI.substring(0, insertionPoint) +
        splitInfo +
        standardCFI.substring(insertionPoint);
  }

  /// Checks if a CFI string contains split information.
  static bool containsSplitInfo(String cfiString) {
    return RegExp(r'/split=\d+,total=\d+/').hasMatch(cfiString);
  }

  @override
  String toString() {
    return 'SplitCFI(part: $splitPart/$totalParts, base: ${_baseCFI.raw})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplitCFI &&
        other.splitPart == splitPart &&
        other.totalParts == totalParts &&
        other._baseCFI == _baseCFI;
  }

  @override
  int get hashCode {
    return Object.hash(splitPart, totalParts, _baseCFI);
  }
}

/// Extension to add split CFI detection to base CFI class.
extension CFISplitDetection on CFI {
  /// Whether this CFI contains split chapter information.
  bool get isSplitCFI => false; // Overridden in SplitCFI

  /// Converts this CFI to a SplitCFI if it contains split information.
  ///
  /// Returns null if this CFI doesn't contain split information.
  SplitCFI? toSplitCFI() {
    if (SplitCFI.containsSplitInfo(raw)) {
      return SplitCFI(raw);
    }
    return null;
  }
}
