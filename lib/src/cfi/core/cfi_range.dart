import 'cfi.dart';
import 'cfi_structure.dart';

/// Utilities for working with CFI ranges and text selections.
class CFIRange {
  /// Creates a range CFI from start and end CFIs.
  /// 
  /// Combines two point CFIs into a single range CFI by finding their
  /// common parent path and creating relative start/end paths.
  /// 
  /// ```dart
  /// final start = CFI('epubcfi(/6/4!/4/10/2:5)');
  /// final end = CFI('epubcfi(/6/4!/4/10/2:15)');
  /// final range = CFIRange.fromStartEnd(start, end);
  /// // Result: CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)')
  /// ```
  static CFI fromStartEnd(CFI start, CFI end) {
    if (start.isRange || end.isRange) {
      throw ArgumentError('Start and end CFIs must be point CFIs, not ranges');
    }
    
    final commonParent = _findCommonParent(start.structure.start, end.structure.start);
    final startRelative = _getRelativePath(start.structure.start, commonParent);
    final endRelative = _getRelativePath(end.structure.start, commonParent);
    
    final rangeStructure = CFIStructure(
      parent: commonParent.isNotEmpty ? CFIPath(parts: commonParent) : null,
      start: CFIPath(parts: startRelative),
      end: CFIPath(parts: endRelative),
    );
    
    return CFI.fromStructure(rangeStructure);
  }

  /// Creates a range CFI within a single text node.
  /// 
  /// Creates a range CFI that spans from [startOffset] to [endOffset]
  /// within the same text node identified by [baseCFI].
  /// 
  /// ```dart
  /// final base = CFI('epubcfi(/6/4!/4/10/2)');
  /// final range = CFIRange.fromTextOffsets(base, 5, 15);
  /// // Result: CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)')
  /// ```
  static CFI fromTextOffsets(CFI baseCFI, int startOffset, int endOffset) {
    if (baseCFI.isRange) {
      throw ArgumentError('Base CFI must be a point CFI, not a range');
    }
    
    if (startOffset > endOffset) {
      throw ArgumentError('Start offset must be less than or equal to end offset');
    }
    
    final basePath = baseCFI.structure.start;
    
    // Create start and end parts with offsets
    final lastPart = basePath.parts.last;
    final startPart = CFIPart(
      index: lastPart.index,
      id: lastPart.id,
      offset: startOffset,
      temporal: lastPart.temporal,
      spatial: lastPart.spatial,
      text: lastPart.text,
      side: lastPart.side,
      hasIndirection: lastPart.hasIndirection,
    );
    
    final endPart = CFIPart(
      index: lastPart.index,
      id: lastPart.id,
      offset: endOffset,
      temporal: lastPart.temporal,
      spatial: lastPart.spatial,
      text: lastPart.text,
      side: lastPart.side,
      hasIndirection: lastPart.hasIndirection,
    );
    
    // Parent is everything except the last part
    final parentParts = basePath.parts.take(basePath.parts.length - 1).toList();
    
    final rangeStructure = CFIStructure(
      parent: parentParts.isNotEmpty ? CFIPath(parts: parentParts) : null,
      start: CFIPath(parts: [startPart]),
      end: CFIPath(parts: [endPart]),
    );
    
    return CFI.fromStructure(rangeStructure);
  }

  /// Expands a point CFI into a range around the specified position.
  /// 
  /// Creates a range CFI that extends [before] characters before and
  /// [after] characters after the point specified by [pointCFI].
  /// 
  /// ```dart
  /// final point = CFI('epubcfi(/6/4!/4/10/2:10)');
  /// final range = CFIRange.expandAround(point, before: 3, after: 5);
  /// // Result: CFI('epubcfi(/6/4!/4/10,/2:7,/2:15)')
  /// ```
  static CFI expandAround(CFI pointCFI, {int before = 0, int after = 0}) {
    if (pointCFI.isRange) {
      throw ArgumentError('CFI must be a point CFI, not a range');
    }
    
    final basePath = pointCFI.structure.start;
    final lastPart = basePath.parts.last;
    final currentOffset = lastPart.offset ?? 0;
    
    final startOffset = (currentOffset - before).clamp(0, currentOffset);
    final endOffset = currentOffset + after;
    
    return fromTextOffsets(pointCFI, startOffset, endOffset);
  }

  /// Checks if a CFI falls within a range CFI.
  /// 
  /// Returns true if [pointCFI] is positioned within the boundaries
  /// of [rangeCFI] (inclusive of start and end).
  /// 
  /// ```dart
  /// final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
  /// final point = CFI('epubcfi(/6/4!/4/10/2:8)');
  /// final contains = CFIRange.contains(range, point);
  /// // Result: true
  /// ```
  static bool contains(CFI rangeCFI, CFI pointCFI) {
    if (!rangeCFI.isRange) {
      throw ArgumentError('First CFI must be a range CFI');
    }
    
    if (pointCFI.isRange) {
      throw ArgumentError('Second CFI must be a point CFI');
    }
    
    final rangeStart = rangeCFI.collapse();
    final rangeEnd = rangeCFI.collapse(toEnd: true);
    
    return pointCFI.compare(rangeStart) >= 0 && pointCFI.compare(rangeEnd) <= 0;
  }

  /// Gets the length of a range CFI in characters.
  /// 
  /// Returns the character count between start and end positions
  /// for ranges within the same text node. Returns null if the
  /// range spans multiple nodes or doesn't have character offsets.
  /// 
  /// ```dart
  /// final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
  /// final length = CFIRange.getLength(range);
  /// // Result: 10 (15 - 5 = 10 characters)
  /// ```
  static int? getLength(CFI rangeCFI) {
    if (!rangeCFI.isRange) {
      return null;
    }
    
    final structure = rangeCFI.structure;
    final startParts = structure.start.parts;
    final endParts = structure.end!.parts;
    
    // Only calculate length for same-node ranges with character offsets
    if (startParts.length != 1 || endParts.length != 1) {
      return null;
    }
    
    final startPart = startParts.first;
    final endPart = endParts.first;
    
    if (startPart.index != endPart.index || 
        startPart.offset == null || 
        endPart.offset == null) {
      return null;
    }
    
    return endPart.offset! - startPart.offset!;
  }

  /// Merges overlapping or adjacent range CFIs.
  /// 
  /// Takes a list of range CFIs and merges any that overlap or are
  /// immediately adjacent, returning a list of non-overlapping ranges.
  /// 
  /// ```dart
  /// final ranges = [
  ///   CFI('epubcfi(/6/4!/4/10,/2:5,/2:10)'),
  ///   CFI('epubcfi(/6/4!/4/10,/2:8,/2:15)'),
  ///   CFI('epubcfi(/6/4!/4/10,/2:20,/2:25)'),
  /// ];
  /// final merged = CFIRange.mergeRanges(ranges);
  /// // Result: [epubcfi(/6/4!/4/10,/2:5,/2:15), epubcfi(/6/4!/4/10,/2:20,/2:25)]
  /// ```
  static List<CFI> mergeRanges(List<CFI> ranges) {
    if (ranges.isEmpty) return [];
    
    // Ensure all CFIs are ranges
    for (final cfi in ranges) {
      if (!cfi.isRange) {
        throw ArgumentError('All CFIs must be range CFIs');
      }
    }
    
    // Sort ranges by start position
    final sortedRanges = List<CFI>.from(ranges);
    sortedRanges.sort((a, b) => a.collapse().compare(b.collapse()));
    
    final merged = <CFI>[];
    CFI? currentRange = sortedRanges.first;
    
    for (int i = 1; i < sortedRanges.length; i++) {
      final nextRange = sortedRanges[i];
      
      if (_rangesOverlapOrAdjacent(currentRange!, nextRange)) {
        // Merge the ranges
        currentRange = _mergeTwo(currentRange, nextRange);
      } else {
        // No overlap, add current and move to next
        merged.add(currentRange);
        currentRange = nextRange;
      }
    }
    
    // Add the last range
    if (currentRange != null) {
      merged.add(currentRange);
    }
    
    return merged;
  }

  /// Splits a range CFI at a specific point.
  /// 
  /// Splits [rangeCFI] at the position specified by [splitPoint],
  /// returning two ranges: before and after the split point.
  /// 
  /// Returns null if the split point is outside the range.
  /// 
  /// ```dart
  /// final range = CFI('epubcfi(/6/4!/4/10,/2:5,/2:15)');
  /// final splitPoint = CFI('epubcfi(/6/4!/4/10/2:10)');
  /// final parts = CFIRange.splitAt(range, splitPoint);
  /// // Result: [epubcfi(/6/4!/4/10,/2:5,/2:10), epubcfi(/6/4!/4/10,/2:10,/2:15)]
  /// ```
  static List<CFI>? splitAt(CFI rangeCFI, CFI splitPoint) {
    if (!rangeCFI.isRange || splitPoint.isRange) {
      throw ArgumentError('Range CFI must be a range and split point must be a point');
    }
    
    if (!contains(rangeCFI, splitPoint)) {
      return null; // Split point is outside the range
    }
    
    final rangeStart = rangeCFI.collapse();
    final rangeEnd = rangeCFI.collapse(toEnd: true);
    
    // Create two ranges
    final beforeRange = fromStartEnd(rangeStart, splitPoint);
    final afterRange = fromStartEnd(splitPoint, rangeEnd);
    
    return [beforeRange, afterRange];
  }

  /// Finds the common parent path between two CFI paths.
  static List<CFIPart> _findCommonParent(CFIPath path1, CFIPath path2) {
    final commonParts = <CFIPart>[];
    final minLength = path1.parts.length < path2.parts.length 
        ? path1.parts.length 
        : path2.parts.length;
    
    for (int i = 0; i < minLength - 1; i++) { // -1 to exclude the final positioning part
      final part1 = path1.parts[i];
      final part2 = path2.parts[i];
      
      if (part1.index == part2.index && part1.id == part2.id) {
        commonParts.add(part1);
      } else {
        break;
      }
    }
    
    return commonParts;
  }

  /// Gets the relative path from a full path by removing the common parent.
  static List<CFIPart> _getRelativePath(CFIPath fullPath, List<CFIPart> commonParent) {
    return fullPath.parts.skip(commonParent.length).toList();
  }

  /// Checks if two ranges overlap or are adjacent.
  static bool _rangesOverlapOrAdjacent(CFI range1, CFI range2) {
    final end1 = range1.collapse(toEnd: true);
    final start2 = range2.collapse();
    
    // Ranges overlap if end1 >= start2
    return end1.compare(start2) >= 0;
  }

  /// Merges two overlapping ranges into one.
  static CFI _mergeTwo(CFI range1, CFI range2) {
    final start1 = range1.collapse();
    final end1 = range1.collapse(toEnd: true);
    final start2 = range2.collapse();
    final end2 = range2.collapse(toEnd: true);
    
    // Find the earliest start and latest end
    final mergedStart = start1.compare(start2) <= 0 ? start1 : start2;
    final mergedEnd = end1.compare(end2) >= 0 ? end1 : end2;
    
    return fromStartEnd(mergedStart, mergedEnd);
  }
}