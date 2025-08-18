import 'package:collection/collection.dart';

/// Represents the parsed structure of a CFI.
///
/// A CFI can be either:
/// - A simple path (point CFI): just a start path
/// - A range CFI: parent path + start path + end path
class CFIStructure {
  /// The parent path common to both start and end in a range CFI.
  /// Null for simple point CFIs.
  final CFIPath? parent;

  /// The path to the start position.
  /// For point CFIs, this is the complete path.
  /// For range CFIs, this is relative to the parent path.
  final CFIPath start;

  /// The path to the end position.
  /// Only present for range CFIs.
  final CFIPath? end;

  const CFIStructure({
    this.parent,
    required this.start,
    this.end,
  });

  /// Whether this CFI represents a range (has both start and end).
  bool get hasRange => end != null;

  /// Collapses a range CFI to a point CFI.
  CFIStructure collapse({bool toEnd = false}) {
    if (!hasRange) return this;

    final targetPath = toEnd ? end! : start;

    // Combine parent and target path
    if (parent != null) {
      final combinedParts = [...parent!.parts, ...targetPath.parts];
      return CFIStructure(start: CFIPath(parts: combinedParts));
    }

    return CFIStructure(start: targetPath);
  }

  /// Compares this CFI structure with another for reading order.
  int compare(CFIStructure other) {
    // Compare start positions (ranges are compared by start)
    final thisStart = _getEffectiveStartPath();
    final otherStart = other._getEffectiveStartPath();

    return thisStart.compare(otherStart);
  }

  /// Gets the effective start path (combining parent if present).
  CFIPath _getEffectiveStartPath() {
    if (parent != null) {
      return CFIPath(parts: [...parent!.parts, ...start.parts]);
    }
    return start;
  }

  /// Converts this structure back to a CFI string.
  String toCFIString() {
    final buffer = StringBuffer('epubcfi(');

    if (hasRange) {
      // Range CFI: parent,start,end
      if (parent != null) {
        buffer.write(parent!.toCFIString());
      }
      buffer.write(',');
      buffer.write(start.toCFIString());
      buffer.write(',');
      buffer.write(end!.toCFIString());
    } else {
      // Point CFI: just the path
      buffer.write(start.toCFIString());
    }

    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CFIStructure &&
        parent == other.parent &&
        start == other.start &&
        end == other.end;
  }

  @override
  int get hashCode => Object.hash(parent, start, end);
}

/// Represents a CFI path consisting of multiple path parts.
class CFIPath {
  /// The individual parts that make up this path.
  final List<CFIPart> parts;

  const CFIPath({required this.parts});

  /// Compares this path with another for reading order.
  int compare(CFIPath other) {
    final minLength =
        parts.length < other.parts.length ? parts.length : other.parts.length;

    for (int i = 0; i < minLength; i++) {
      final comparison = parts[i].compare(other.parts[i]);
      if (comparison != 0) return comparison;
    }

    // If all compared parts are equal, shorter path comes first
    return parts.length.compareTo(other.parts.length);
  }

  /// Converts this path to a CFI string representation.
  String toCFIString() {
    return parts.map((part) => part.toCFIString()).join('');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CFIPath && const ListEquality().equals(parts, other.parts);
  }

  @override
  int get hashCode => const ListEquality().hash(parts);
}

/// Represents an individual component of a CFI path.
class CFIPart {
  /// The step index (even numbers for elements, odd for text/virtual positions).
  final int index;

  /// Optional ID assertion for the referenced element.
  final String? id;

  /// Character offset within a text node.
  final int? offset;

  /// Temporal offset for time-based media.
  final double? temporal;

  /// Spatial coordinates for 2D positioning.
  final List<double>? spatial;

  /// Text location assertion for content verification.
  final List<String>? text;

  /// Side bias indicator ("before" or "after").
  final String? side;

  /// Whether this part includes step indirection (!).
  final bool hasIndirection;

  const CFIPart({
    required this.index,
    this.id,
    this.offset,
    this.temporal,
    this.spatial,
    this.text,
    this.side,
    this.hasIndirection = false,
  });

  /// Compares this part with another for reading order.
  int compare(CFIPart other) {
    // First compare by index
    final indexComparison = index.compareTo(other.index);
    if (indexComparison != 0) return indexComparison;

    // If indices are equal, compare by offset
    final thisOffset = offset ?? 0;
    final otherOffset = other.offset ?? 0;
    final offsetComparison = thisOffset.compareTo(otherOffset);
    if (offsetComparison != 0) return offsetComparison;

    // If offsets are equal, compare by temporal
    if (temporal != null && other.temporal != null) {
      return temporal!.compareTo(other.temporal!);
    }

    // If one has temporal and other doesn't, non-temporal comes first
    if (temporal != null) return 1;
    if (other.temporal != null) return -1;

    return 0;
  }

  /// Converts this part to a CFI string representation.
  String toCFIString() {
    final buffer = StringBuffer();

    // Add step indirection if present
    if (hasIndirection) buffer.write('!');

    // Add the step reference
    buffer.write('/$index');

    // Add ID assertion
    if (id != null) {
      buffer.write('[${_escapeCFI(id!)}]');
    }

    // Add character offset
    if (offset != null) {
      buffer.write(':$offset');
    }

    // Add temporal offset
    if (temporal != null) {
      buffer.write('~$temporal');
    }

    // Add spatial coordinates
    if (spatial != null && spatial!.isNotEmpty) {
      buffer.write('@${spatial!.join(':')}');
    }

    // Add text assertion
    if (text != null && text!.isNotEmpty) {
      final escapedText = text!.map(_escapeCFI).join(',');
      buffer.write('[,$escapedText]');
    }

    // Add side bias
    if (side != null) {
      buffer.write('[$side]');
    }

    return buffer.toString();
  }

  /// Escapes special CFI characters in text.
  String _escapeCFI(String text) {
    return text.replaceAllMapped(
      RegExp(r'[\^[\](),;=]'),
      (match) => '^${match.group(0)}',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CFIPart &&
        index == other.index &&
        id == other.id &&
        offset == other.offset &&
        temporal == other.temporal &&
        const ListEquality().equals(spatial, other.spatial) &&
        const ListEquality().equals(text, other.text) &&
        side == other.side &&
        hasIndirection == other.hasIndirection;
  }

  @override
  int get hashCode => Object.hash(
        index,
        id,
        offset,
        temporal,
        const ListEquality().hash(spatial ?? []),
        const ListEquality().hash(text ?? []),
        side,
        hasIndirection,
      );
}
