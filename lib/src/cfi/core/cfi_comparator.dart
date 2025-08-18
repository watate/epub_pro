import 'cfi.dart';

/// Utilities for comparing and sorting CFI objects.
class CFIComparator {
  /// Sorts a list of CFIs in reading order.
  ///
  /// Returns a new list with CFIs arranged from earliest to latest
  /// in the reading sequence. Range CFIs are sorted by their start positions.
  ///
  /// ```dart
  /// final cfis = [
  ///   CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   CFI('epubcfi(/6/2!/4/2/1:1)'),
  ///   CFI('epubcfi(/6/4!/4/10/2:3)'),
  /// ];
  /// final sorted = CFIComparator.sortByReadingOrder(cfis);
  /// // Result: [/6/2!/4/2/1:1, /6/4!/4/10/2:3, /6/4!/4/10/2:5]
  /// ```
  static List<CFI> sortByReadingOrder(List<CFI> cfis) {
    final sorted = List<CFI>.from(cfis);
    sorted.sort((a, b) => a.compare(b));
    return sorted;
  }

  /// Finds the earliest CFI in a list.
  ///
  /// Returns the CFI that appears first in reading order.
  /// Returns null if the list is empty.
  ///
  /// ```dart
  /// final cfis = [
  ///   CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   CFI('epubcfi(/6/2!/4/2/1:1)'),
  /// ];
  /// final earliest = CFIComparator.findEarliest(cfis);
  /// // Result: CFI('epubcfi(/6/2!/4/2/1:1)')
  /// ```
  static CFI? findEarliest(List<CFI> cfis) {
    if (cfis.isEmpty) return null;

    return cfis.reduce((a, b) => a.compare(b) <= 0 ? a : b);
  }

  /// Finds the latest CFI in a list.
  ///
  /// Returns the CFI that appears last in reading order.
  /// Returns null if the list is empty.
  ///
  /// ```dart
  /// final cfis = [
  ///   CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   CFI('epubcfi(/6/2!/4/2/1:1)'),
  /// ];
  /// final latest = CFIComparator.findLatest(cfis);
  /// // Result: CFI('epubcfi(/6/4!/4/10/2:5)')
  /// ```
  static CFI? findLatest(List<CFI> cfis) {
    if (cfis.isEmpty) return null;

    return cfis.reduce((a, b) => a.compare(b) >= 0 ? a : b);
  }

  /// Checks if a CFI falls within a range defined by two other CFIs.
  ///
  /// Returns true if [target] is positioned between [start] and [end]
  /// in reading order (inclusive of boundaries).
  ///
  /// ```dart
  /// final start = CFI('epubcfi(/6/4!/4/10/2:3)');
  /// final end = CFI('epubcfi(/6/4!/4/10/2:10)');
  /// final target = CFI('epubcfi(/6/4!/4/10/2:5)');
  ///
  /// final isInRange = CFIComparator.isInRange(target, start, end);
  /// // Result: true
  /// ```
  static bool isInRange(CFI target, CFI start, CFI end) {
    return target.compare(start) >= 0 && target.compare(end) <= 0;
  }

  /// Filters CFIs that fall within a specified range.
  ///
  /// Returns a list of CFIs that are positioned between [start] and [end]
  /// in reading order (inclusive of boundaries).
  ///
  /// ```dart
  /// final cfis = [
  ///   CFI('epubcfi(/6/4!/4/10/2:1)'),
  ///   CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   CFI('epubcfi(/6/4!/4/10/2:8)'),
  ///   CFI('epubcfi(/6/4!/4/10/2:12)'),
  /// ];
  /// final start = CFI('epubcfi(/6/4!/4/10/2:3)');
  /// final end = CFI('epubcfi(/6/4!/4/10/2:10)');
  ///
  /// final inRange = CFIComparator.filterInRange(cfis, start, end);
  /// // Result: [/6/4!/4/10/2:5, /6/4!/4/10/2:8]
  /// ```
  static List<CFI> filterInRange(List<CFI> cfis, CFI start, CFI end) {
    return cfis.where((cfi) => isInRange(cfi, start, end)).toList();
  }

  /// Groups CFIs by their spine position (chapter).
  ///
  /// Returns a map where keys are spine indices and values are lists
  /// of CFIs belonging to that spine item, sorted in reading order.
  ///
  /// ```dart
  /// final cfis = [
  ///   CFI('epubcfi(/6/2!/4/10/2:1)'), // Spine 1
  ///   CFI('epubcfi(/6/4!/4/10/2:5)'), // Spine 2
  ///   CFI('epubcfi(/6/2!/4/10/2:8)'), // Spine 1
  /// ];
  ///
  /// final grouped = CFIComparator.groupBySpine(cfis);
  /// // Result: {1: [/6/2!/4/10/2:1, /6/2!/4/10/2:8], 2: [/6/4!/4/10/2:5]}
  /// ```
  static Map<int, List<CFI>> groupBySpine(List<CFI> cfis) {
    final groups = <int, List<CFI>>{};

    for (final cfi in cfis) {
      final spineIndex = extractSpineIndex(cfi);
      if (spineIndex != null) {
        groups.putIfAbsent(spineIndex, () => <CFI>[]).add(cfi);
      }
    }

    // Sort each group by reading order
    for (final group in groups.values) {
      group.sort((a, b) => a.compare(b));
    }

    return groups;
  }

  /// Extracts the spine index from a CFI.
  ///
  /// Returns the spine position (0-based) that this CFI refers to,
  /// or null if the CFI doesn't contain spine information.
  ///
  /// ```dart
  /// final cfi = CFI('epubcfi(/6/4!/4/10/2:5)');
  /// final spineIndex = CFIComparator.extractSpineIndex(cfi);
  /// // Result: 1 (4/2 - 1 = 1, since spine uses 1-based even indexing)
  /// ```
  static int? extractSpineIndex(CFI cfi) {
    final structure = cfi.structure;
    final firstPart =
        structure.parent?.parts.first ?? structure.start.parts.first;

    // For the test case /6/4, we want:
    // /6 is the spine container (index 6)
    // /4 is the spine item (index 4)
    // The spine index should be (4 / 2) - 1 = 1

    // Look for the second part which represents the actual spine item
    final parts = structure.parent?.parts ?? structure.start.parts;
    if (parts.length >= 2) {
      final spineItemPart = parts[1]; // Second part is the spine item
      if (spineItemPart.index >= 2 && spineItemPart.index.isEven) {
        return (spineItemPart.index ~/ 2) - 1;
      }
    }

    // Fallback to first part if only one part
    if (firstPart.index >= 2 && firstPart.index.isEven) {
      return (firstPart.index ~/ 2) - 1;
    }

    return null;
  }

  /// Calculates the distance between two CFIs.
  ///
  /// Returns a rough estimate of the "distance" between two CFIs
  /// based on their positions. This is useful for determining
  /// relative proximity of annotations or bookmarks.
  ///
  /// The distance is calculated as the sum of differences in:
  /// - Spine position (weighted heavily)
  /// - Path depth differences
  /// - Character offset differences
  ///
  /// ```dart
  /// final cfi1 = CFI('epubcfi(/6/4!/4/10/2:3)');
  /// final cfi2 = CFI('epubcfi(/6/4!/4/10/2:8)');
  /// final distance = CFIComparator.calculateDistance(cfi1, cfi2);
  /// // Result: 5 (same spine/path, 5 character difference)
  /// ```
  static double calculateDistance(CFI cfi1, CFI cfi2) {
    final spine1 = extractSpineIndex(cfi1) ?? 0;
    final spine2 = extractSpineIndex(cfi2) ?? 0;

    // Heavy weight for spine differences (different chapters)
    final spineDifference = (spine1 - spine2).abs() * 10000.0;

    if (spineDifference > 0) {
      return spineDifference; // Different chapters
    }

    // Same chapter - compare paths and offsets
    final path1 = cfi1.structure.start;
    final path2 = cfi2.structure.start;

    double pathDifference = 0.0;
    final minLength = path1.parts.length < path2.parts.length
        ? path1.parts.length
        : path2.parts.length;

    for (int i = 0; i < minLength; i++) {
      final part1 = path1.parts[i];
      final part2 = path2.parts[i];

      // Index difference
      pathDifference += (part1.index - part2.index).abs() * 100.0;

      // Offset difference (most precise)
      final offset1 = part1.offset ?? 0;
      final offset2 = part2.offset ?? 0;
      pathDifference += (offset1 - offset2).abs().toDouble();
    }

    // Path length difference
    pathDifference += (path1.parts.length - path2.parts.length).abs() * 50.0;

    return pathDifference;
  }

  /// Finds the closest CFI to a target CFI from a list of candidates.
  ///
  /// Returns the CFI from [candidates] that has the smallest distance
  /// to [target], or null if the candidates list is empty.
  ///
  /// ```dart
  /// final target = CFI('epubcfi(/6/4!/4/10/2:5)');
  /// final candidates = [
  ///   CFI('epubcfi(/6/4!/4/10/2:1)'),
  ///   CFI('epubcfi(/6/4!/4/10/2:8)'),
  ///   CFI('epubcfi(/6/6!/4/10/2:5)'),
  /// ];
  ///
  /// final closest = CFIComparator.findClosest(target, candidates);
  /// // Result: CFI('epubcfi(/6/4!/4/10/2:8)') - closest in distance
  /// ```
  static CFI? findClosest(CFI target, List<CFI> candidates) {
    if (candidates.isEmpty) return null;

    CFI? closest;
    double minDistance = double.infinity;

    for (final candidate in candidates) {
      final distance = calculateDistance(target, candidate);
      if (distance < minDistance) {
        minDistance = distance;
        closest = candidate;
      }
    }

    return closest;
  }
}
