import 'cfi_parser.dart';
import 'cfi_structure.dart';

/// EPUB Canonical Fragment Identifier (CFI) for precise positioning within EPUB content.
///
/// CFI provides a standardized way to uniquely identify any location within an EPUB document.
/// It enables precise positioning that remains valid across different devices, screen sizes,
/// and rendering engines.
///
/// ## CFI Format
/// A CFI has the format: `epubcfi(/6/4[chap01]!/4/10/2:3)`
/// - `/6/4[chap01]` - spine position and chapter reference
/// - `!` - step indirection (crossing document boundaries)
/// - `/4/10/2` - DOM path to specific element
/// - `:3` - character offset within text node
///
/// ## Usage Examples
/// ```dart
/// // Parse an existing CFI
/// final cfi = CFI('epubcfi(/6/4[chap01]!/4/10/2:3)');
/// print('Is range CFI: ${cfi.isRange}');
///
/// // Compare CFIs for reading order
/// final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)');
/// final cfi2 = CFI('epubcfi(/6/4!/4/10/2:5)');
/// final comparison = cfi1.compare(cfi2); // Returns -1, 0, or 1
///
/// // Collapse range CFI to a point
/// final rangeCfi = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
/// final startCfi = rangeCfi.collapse(); // Points to start of range
/// final endCfi = rangeCfi.collapse(toEnd: true); // Points to end of range
/// ```
class CFI {
  /// The raw CFI string as provided.
  final String raw;

  /// The parsed CFI structure.
  late final CFIStructure _structure;

  /// Creates a CFI from a CFI string.
  ///
  /// Throws [FormatException] if the CFI string is malformed.
  CFI(this.raw) {
    _structure = CFIParser.parse(raw);
  }

  /// Creates a CFI from a parsed structure.
  CFI._fromStructure(this.raw, this._structure);

  /// Creates a CFI from a CFI structure.
  factory CFI.fromStructure(CFIStructure structure) {
    final cfiString = structure.toCFIString();
    return CFI._fromStructure(cfiString, structure);
  }

  /// Whether this CFI represents a range (text selection) rather than a point.
  bool get isRange => _structure.hasRange;

  /// Whether this CFI represents a simple point position.
  bool get isPoint => !_structure.hasRange;

  /// Gets the parsed CFI structure.
  CFIStructure get structure => _structure;

  /// Collapses a range CFI to a point CFI.
  ///
  /// For point CFIs, returns the same CFI.
  /// For range CFIs, returns either the start point (default) or end point.
  ///
  /// ```dart
  /// final rangeCfi = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
  /// final startCfi = rangeCfi.collapse(); // Points to character 5
  /// final endCfi = rangeCfi.collapse(toEnd: true); // Points to character 15
  /// ```
  CFI collapse({bool toEnd = false}) {
    if (!isRange) return this;

    return CFI.fromStructure(_structure.collapse(toEnd: toEnd));
  }

  /// Compares this CFI with another CFI for reading order.
  ///
  /// Returns:
  /// - Negative value if this CFI comes before [other]
  /// - Zero if CFIs are equivalent
  /// - Positive value if this CFI comes after [other]
  ///
  /// Range CFIs are compared by their start positions.
  ///
  /// ```dart
  /// final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)');
  /// final cfi2 = CFI('epubcfi(/6/4!/4/10/2:5)');
  /// print(cfi1.compare(cfi2)); // -1 (cfi1 comes before cfi2)
  /// ```
  int compare(CFI other) {
    return _structure.compare(other._structure);
  }

  /// Creates a normalized CFI string representation.
  ///
  /// This may differ from the original [raw] string if the original
  /// contained unnecessary whitespace or formatting variations.
  @override
  String toString() {
    return _structure.toCFIString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CFI && _structure == other._structure;
  }

  @override
  int get hashCode => _structure.hashCode;
}
