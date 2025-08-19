import '../core/cfi_parser.dart';
import '../core/cfi_structure.dart';
import '../core/cfi.dart';
import 'split_cfi.dart';

/// Parser extension for Split CFI notation.
///
/// Extends the standard CFI parser to recognize and handle split chapter
/// notation while maintaining full backward compatibility with standard CFI.
///
/// ## Supported Formats
/// ```
/// Standard: epubcfi(/6/4!/4/10/2:15)
/// Split:    epubcfi(/6/4!/split=2,total=3/4/10/2:15)
/// Range:    epubcfi(/6/4!/split=2,total=3/4/10,/2:5,/2:15)
/// ```
class SplitCFIParser {
  /// Parses a CFI string that may contain split information.
  ///
  /// Returns a [SplitCFI] if split information is detected, otherwise
  /// returns a standard [CFI].
  ///
  /// Throws [FormatException] if the CFI string is malformed.
  static CFI parseAny(String cfiString) {
    if (SplitCFI.containsSplitInfo(cfiString)) {
      return SplitCFI(cfiString);
    }
    return CFI(cfiString);
  }

  /// Parses a CFI string specifically as a Split CFI.
  ///
  /// Throws [FormatException] if the CFI string doesn't contain split
  /// information or is malformed.
  static SplitCFI parseSplitCFI(String cfiString) {
    if (!SplitCFI.containsSplitInfo(cfiString)) {
      throw FormatException('CFI does not contain split information: $cfiString');
    }
    return SplitCFI(cfiString);
  }

  /// Parses the structure of a split CFI.
  ///
  /// This method extends the standard CFI parser to handle split notation
  /// by temporarily removing split information, parsing the structure,
  /// and then restoring the split context.
  static CFIStructure parseSplitStructure(String cfiString) {
    // Validate split CFI format
    if (!SplitCFI.containsSplitInfo(cfiString)) {
      throw FormatException('Not a split CFI: $cfiString');
    }

    // Extract split information
    final splitInfo = _extractSplitInfo(cfiString);
    
    // Remove split information for standard parsing
    final cleanCFI = _removeSplitNotation(cfiString);
    
    // Parse using standard parser
    final structure = CFIParser.parse(cleanCFI);
    
    // Add split metadata to the structure
    return _addSplitMetadata(structure, splitInfo);
  }

  /// Validates that a CFI string has valid split notation.
  ///
  /// Checks syntax, part numbers, and structural validity.
  static bool isValidSplitCFI(String cfiString) {
    try {
      // Check if it contains split info
      if (!SplitCFI.containsSplitInfo(cfiString)) {
        return false;
      }

      // Validate split notation syntax
      final splitMatch = RegExp(r'/split=(\d+),total=(\d+)/').firstMatch(cfiString);
      if (splitMatch == null) {
        return false;
      }

      final splitPart = int.parse(splitMatch.group(1)!);
      final totalParts = int.parse(splitMatch.group(2)!);

      // Validate part numbers
      if (splitPart < 1 || totalParts < 1 || splitPart > totalParts) {
        return false;
      }

      // Validate that the base CFI (without split info) is valid
      final cleanCFI = _removeSplitNotation(cfiString);
      CFIParser.parse(cleanCFI); // Will throw if invalid

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extracts split information from a CFI string.
  static SplitInfo _extractSplitInfo(String cfiString) {
    final match = RegExp(r'/split=(\d+),total=(\d+)/').firstMatch(cfiString);
    if (match == null) {
      throw FormatException('Invalid split notation in CFI: $cfiString');
    }

    return SplitInfo(
      splitPart: int.parse(match.group(1)!),
      totalParts: int.parse(match.group(2)!),
      position: match.start,
      length: match.end - match.start,
    );
  }

  /// Removes split notation from a CFI string.
  static String _removeSplitNotation(String cfiString) {
    return cfiString.replaceAll(RegExp(r'/split=\d+,total=\d+'), '');
  }

  /// Adds split metadata to a parsed CFI structure.
  static CFIStructure _addSplitMetadata(CFIStructure structure, SplitInfo splitInfo) {
    // For now, we'll store split info in the structure's metadata
    // This preserves the existing structure while adding split context
    return CFIStructureWithSplitInfo(
      structure,
      splitInfo.splitPart,
      splitInfo.totalParts,
    );
  }

  /// Reconstructs a split CFI string from a structure and split info.
  static String buildSplitCFI(
    CFIStructure structure,
    int splitPart,
    int totalParts,
  ) {
    // Generate standard CFI string
    final standardCFI = structure.toString();
    
    // Find insertion point after spine reference
    final spineEndMatch = RegExp(r'(/6/\d+!)').firstMatch(standardCFI);
    if (spineEndMatch == null) {
      throw FormatException('Invalid CFI structure for split CFI');
    }
    
    final insertionPoint = spineEndMatch.end;
    final splitNotation = '/split=$splitPart,total=$totalParts';
    
    return standardCFI.substring(0, insertionPoint) +
           splitNotation +
           standardCFI.substring(insertionPoint);
  }

  /// Converts a split CFI to its canonical format.
  ///
  /// Ensures consistent formatting and validates the split information.
  static String canonicalize(String splitCFI) {
    final parsed = parseSplitCFI(splitCFI);
    return parsed.raw;
  }
}

/// Information about split part extracted from CFI string.
class SplitInfo {
  final int splitPart;
  final int totalParts;
  final int position;
  final int length;

  const SplitInfo({
    required this.splitPart,
    required this.totalParts,
    required this.position,
    required this.length,
  });

  @override
  String toString() {
    return 'SplitInfo(part: $splitPart/$totalParts, pos: $position, len: $length)';
  }
}

/// CFI Structure extended with split information.
///
/// This wrapper preserves the existing CFI structure while adding
/// split chapter context.
class CFIStructureWithSplitInfo extends CFIStructure {
  final CFIStructure baseStructure;
  final int splitPart;
  final int totalParts;

  CFIStructureWithSplitInfo(
    this.baseStructure,
    this.splitPart,
    this.totalParts,
  ) : super(
    start: baseStructure.start,
    end: baseStructure.end,
    parent: baseStructure.parent,
  );

  /// Whether this structure contains split information.
  bool get hasSplitInfo => true;

  @override
  String toString() {
    // Generate split CFI string using the parser
    return SplitCFIParser.buildSplitCFI(baseStructure, splitPart, totalParts);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CFIStructureWithSplitInfo &&
           other.baseStructure == baseStructure &&
           other.splitPart == splitPart &&
           other.totalParts == totalParts;
  }

  @override
  int get hashCode {
    return Object.hash(baseStructure, splitPart, totalParts);
  }
}