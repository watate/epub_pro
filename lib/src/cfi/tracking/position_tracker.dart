import '../core/cfi.dart';
import '../epub/epub_cfi_manager.dart';
import '../../ref_entities/epub_book_ref.dart';

/// Tracks reading positions and progress using CFI for precise positioning.
/// 
/// The position tracker provides functionality to save and restore reading
/// positions, calculate reading progress, and sync positions across devices.
class CFIPositionTracker {
  final String _bookId;
  final EpubCFIManager _cfiManager;
  final PositionStorage _storage;

  /// Creates a position tracker for the given book.
  CFIPositionTracker({
    required String bookId,
    required EpubBookRef bookRef,
    required PositionStorage storage,
  })  : _bookId = bookId,
        _cfiManager = EpubCFIManager(bookRef),
        _storage = storage;

  /// Saves the current reading position.
  /// 
  /// Records a CFI-based position that can be restored later.
  /// The position includes the CFI, spine information, and progress data.
  /// 
  /// ```dart
  /// final tracker = CFIPositionTracker(
  ///   bookId: 'book123',
  ///   bookRef: bookRef,
  ///   storage: storage,
  /// );
  /// 
  /// await tracker.savePosition(
  ///   cfi: CFI('epubcfi(/6/4!/4/10/2:5)'),
  ///   fractionInChapter: 0.3,
  /// );
  /// ```
  Future<void> savePosition({
    required CFI cfi,
    double? fractionInChapter,
    Map<String, dynamic>? metadata,
  }) async {
    final spineIndex = _cfiManager.extractSpineIndex(cfi);
    if (spineIndex == null) {
      throw ArgumentError('CFI does not contain valid spine information');
    }

    final totalSpineItems = _cfiManager.spineItemCount;
    final overallProgress = (spineIndex + (fractionInChapter ?? 0.0)) / totalSpineItems;

    final position = ReadingPosition(
      bookId: _bookId,
      cfi: cfi,
      spineIndex: spineIndex,
      totalSpineItems: totalSpineItems,
      fractionInChapter: fractionInChapter ?? 0.0,
      overallProgress: overallProgress.clamp(0.0, 1.0),
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    await _storage.savePosition(position);
  }

  /// Restores the last saved reading position.
  /// 
  /// Returns the saved position or null if no position has been saved.
  /// 
  /// ```dart
  /// final position = await tracker.restorePosition();
  /// if (position != null) {
  ///   print('Last read at: ${position.cfi}');
  ///   print('Progress: ${(position.overallProgress * 100).toStringAsFixed(1)}%');
  /// }
  /// ```
  Future<ReadingPosition?> restorePosition() async {
    return await _storage.getPosition(_bookId);
  }

  /// Navigates to the saved reading position.
  /// 
  /// Convenience method that restores the position and navigates to it.
  /// Returns null if no position is saved or navigation fails.
  /// 
  /// ```dart
  /// final location = await tracker.navigateToSavedPosition();
  /// if (location != null) {
  ///   final content = await location.chapterRef.readHtmlContent();
  ///   // Display content at the saved position
  /// }
  /// ```
  Future<CFILocation?> navigateToSavedPosition() async {
    final position = await restorePosition();
    if (position == null) return null;

    return await _cfiManager.navigateToCFI(position.cfi);
  }

  /// Calculates detailed reading progress.
  /// 
  /// Returns comprehensive progress information including current position,
  /// overall progress, and estimated reading time.
  /// 
  /// ```dart
  /// final progress = await tracker.calculateProgress();
  /// print('Current chapter: ${progress.currentChapterIndex + 1}/${progress.totalChapters}');
  /// print('Overall progress: ${(progress.overallProgress * 100).toStringAsFixed(1)}%');
  /// ```
  Future<ReadingProgress> calculateProgress() async {
    final position = await restorePosition();
    if (position == null) {
      return ReadingProgress.empty(_bookId);
    }

    final spineMap = _cfiManager.getSpineChapterMap();
    final currentChapter = spineMap[position.spineIndex];

    return ReadingProgress(
      bookId: _bookId,
      currentCFI: position.cfi,
      currentChapterIndex: position.spineIndex,
      totalChapters: _cfiManager.spineItemCount,
      fractionInChapter: position.fractionInChapter,
      overallProgress: position.overallProgress,
      currentChapterTitle: currentChapter?.title,
      lastReadTime: position.timestamp,
      readingVelocity: await _calculateReadingVelocity(),
      estimatedTimeRemaining: await _estimateTimeRemaining(position.overallProgress),
    );
  }

  /// Records a reading session milestone.
  /// 
  /// Saves intermediate positions during reading to track velocity
  /// and provide better progress estimates.
  /// 
  /// ```dart
  /// await tracker.recordMilestone(
  ///   cfi: currentCFI,
  ///   fractionInChapter: 0.5,
  ///   sessionData: {'wordsRead': 1200, 'timeSpent': 300}, // 5 minutes
  /// );
  /// ```
  Future<void> recordMilestone({
    required CFI cfi,
    double? fractionInChapter,
    Map<String, dynamic>? sessionData,
  }) async {
    final spineIndex = _cfiManager.extractSpineIndex(cfi);
    if (spineIndex == null) return;

    final milestone = ReadingMilestone(
      bookId: _bookId,
      cfi: cfi,
      spineIndex: spineIndex,
      fractionInChapter: fractionInChapter ?? 0.0,
      timestamp: DateTime.now(),
      sessionData: sessionData ?? {},
    );

    await _storage.saveMilestone(milestone);
  }

  /// Gets reading statistics for this book.
  /// 
  /// Returns comprehensive reading statistics including total time spent,
  /// reading velocity, and progress over time.
  /// 
  /// ```dart
  /// final stats = await tracker.getReadingStatistics();
  /// print('Total reading time: ${stats.totalReadingTime}');
  /// print('Average reading speed: ${stats.averageWordsPerMinute} wpm');
  /// ```
  Future<ReadingStatistics> getReadingStatistics() async {
    final milestones = await _storage.getMilestones(_bookId);
    final position = await restorePosition();

    if (milestones.isEmpty && position == null) {
      return ReadingStatistics.empty(_bookId);
    }

    final sessions = _groupMilestonesIntoSessions(milestones);
    final totalReadingTime = _calculateTotalReadingTime(sessions);
    final averageVelocity = await _calculateReadingVelocity();

    return ReadingStatistics(
      bookId: _bookId,
      totalReadingTime: totalReadingTime,
      averageWordsPerMinute: averageVelocity,
      sessionsCount: sessions.length,
      totalProgress: position?.overallProgress ?? 0.0,
      firstStarted: milestones.isNotEmpty ? milestones.first.timestamp : position?.timestamp,
      lastRead: position?.timestamp ?? DateTime.now(),
      milestoneCount: milestones.length,
    );
  }

  /// Synchronizes positions with another tracker (for cross-device sync).
  /// 
  /// Merges reading positions and milestones with another device's data,
  /// resolving conflicts by timestamp.
  /// 
  /// ```dart
  /// final otherDeviceData = await fetchFromCloud();
  /// await tracker.syncWith(otherDeviceData);
  /// ```
  Future<void> syncWith(SyncData syncData) async {
    // Compare local and remote positions
    final localPosition = await restorePosition();
    final remotePosition = syncData.position;

    // Use the most recent position
    if (localPosition == null || 
        (remotePosition != null && remotePosition.timestamp.isAfter(localPosition.timestamp))) {
      await _storage.savePosition(remotePosition!);
    }

    // Merge milestones (keep all unique ones)
    final localMilestones = await _storage.getMilestones(_bookId);
    final remoteMilestones = syncData.milestones;

    final allMilestones = <ReadingMilestone>{};
    allMilestones.addAll(localMilestones);
    allMilestones.addAll(remoteMilestones);

    for (final milestone in allMilestones) {
      await _storage.saveMilestone(milestone);
    }
  }

  /// Exports position data for backup or transfer.
  /// 
  /// Returns all position and milestone data for this book
  /// in a serializable format.
  /// 
  /// ```dart
  /// final exportData = await tracker.exportData();
  /// await saveToFile(exportData.toJson());
  /// ```
  Future<SyncData> exportData() async {
    final position = await restorePosition();
    final milestones = await _storage.getMilestones(_bookId);

    return SyncData(
      bookId: _bookId,
      position: position,
      milestones: milestones,
      exportTimestamp: DateTime.now(),
    );
  }

  /// Calculates reading velocity based on recent milestones.
  Future<double> _calculateReadingVelocity() async {
    final milestones = await _storage.getMilestones(_bookId);
    if (milestones.length < 2) return 0.0;

    // Use last few milestones for recent velocity
    final recentMilestones = milestones.take(10).toList();
    double totalWords = 0.0;
    Duration totalTime = Duration.zero;

    for (int i = 1; i < recentMilestones.length; i++) {
      final prev = recentMilestones[i - 1];
      final curr = recentMilestones[i];

      final timeDiff = curr.timestamp.difference(prev.timestamp);
      final wordsRead = curr.sessionData['wordsRead'] as int? ?? 0;

      totalWords += wordsRead;
      totalTime += timeDiff;
    }

    if (totalTime.inMinutes == 0) return 0.0;
    return totalWords / totalTime.inMinutes;
  }

  /// Estimates remaining reading time based on progress and velocity.
  Future<Duration> _estimateTimeRemaining(double progress) async {
    final velocity = await _calculateReadingVelocity();
    if (velocity <= 0) return Duration.zero;

    // Rough estimate: assume average book has 70,000 words
    const averageBookWords = 70000;
    final remainingProgress = 1.0 - progress;
    final remainingWords = averageBookWords * remainingProgress;

    final remainingMinutes = remainingWords / velocity;
    return Duration(minutes: remainingMinutes.round());
  }

  /// Groups milestones into reading sessions.
  List<ReadingSession> _groupMilestonesIntoSessions(List<ReadingMilestone> milestones) {
    if (milestones.isEmpty) return [];

    final sessions = <ReadingSession>[];
    const sessionGap = Duration(minutes: 30); // 30 minutes gap = new session

    List<ReadingMilestone> currentSession = [milestones.first];

    for (int i = 1; i < milestones.length; i++) {
      final prev = milestones[i - 1];
      final curr = milestones[i];

      if (curr.timestamp.difference(prev.timestamp) > sessionGap) {
        // Start new session
        sessions.add(ReadingSession(
          milestones: List.from(currentSession),
          startTime: currentSession.first.timestamp,
          endTime: currentSession.last.timestamp,
        ));
        currentSession = [curr];
      } else {
        currentSession.add(curr);
      }
    }

    // Add final session
    if (currentSession.isNotEmpty) {
      sessions.add(ReadingSession(
        milestones: currentSession,
        startTime: currentSession.first.timestamp,
        endTime: currentSession.last.timestamp,
      ));
    }

    return sessions;
  }

  /// Calculates total reading time from sessions.
  Duration _calculateTotalReadingTime(List<ReadingSession> sessions) {
    return sessions.fold(
      Duration.zero,
      (total, session) => total + session.duration,
    );
  }
}

/// Represents a saved reading position.
class ReadingPosition {
  final String bookId;
  final CFI cfi;
  final int spineIndex;
  final int totalSpineItems;
  final double fractionInChapter;
  final double overallProgress;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ReadingPosition({
    required this.bookId,
    required this.cfi,
    required this.spineIndex,
    required this.totalSpineItems,
    required this.fractionInChapter,
    required this.overallProgress,
    required this.timestamp,
    required this.metadata,
  });

  /// Creates an empty reading position.
  factory ReadingPosition.empty(String bookId) {
    return ReadingPosition(
      bookId: bookId,
      cfi: CFI('epubcfi(/6/2)'),
      spineIndex: 0,
      totalSpineItems: 1,
      fractionInChapter: 0.0,
      overallProgress: 0.0,
      timestamp: DateTime.now(),
      metadata: {},
    );
  }

  /// Converts to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'cfi': cfi.toString(),
      'spineIndex': spineIndex,
      'totalSpineItems': totalSpineItems,
      'fractionInChapter': fractionInChapter,
      'overallProgress': overallProgress,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Creates from JSON.
  factory ReadingPosition.fromJson(Map<String, dynamic> json) {
    return ReadingPosition(
      bookId: json['bookId'],
      cfi: CFI(json['cfi']),
      spineIndex: json['spineIndex'],
      totalSpineItems: json['totalSpineItems'],
      fractionInChapter: json['fractionInChapter'],
      overallProgress: json['overallProgress'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }

  @override
  String toString() {
    return 'ReadingPosition(${(overallProgress * 100).toStringAsFixed(1)}% at $cfi)';
  }
}

/// Represents a reading milestone during a session.
class ReadingMilestone {
  final String bookId;
  final CFI cfi;
  final int spineIndex;
  final double fractionInChapter;
  final DateTime timestamp;
  final Map<String, dynamic> sessionData;

  const ReadingMilestone({
    required this.bookId,
    required this.cfi,
    required this.spineIndex,
    required this.fractionInChapter,
    required this.timestamp,
    required this.sessionData,
  });

  /// Converts to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'cfi': cfi.toString(),
      'spineIndex': spineIndex,
      'fractionInChapter': fractionInChapter,
      'timestamp': timestamp.toIso8601String(),
      'sessionData': sessionData,
    };
  }

  /// Creates from JSON.
  factory ReadingMilestone.fromJson(Map<String, dynamic> json) {
    return ReadingMilestone(
      bookId: json['bookId'],
      cfi: CFI(json['cfi']),
      spineIndex: json['spineIndex'],
      fractionInChapter: json['fractionInChapter'],
      timestamp: DateTime.parse(json['timestamp']),
      sessionData: Map<String, dynamic>.from(json['sessionData']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingMilestone &&
        bookId == other.bookId &&
        cfi == other.cfi &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode => Object.hash(bookId, cfi, timestamp);
}

/// Represents comprehensive reading progress information.
class ReadingProgress {
  final String bookId;
  final CFI? currentCFI;
  final int currentChapterIndex;
  final int totalChapters;
  final double fractionInChapter;
  final double overallProgress;
  final String? currentChapterTitle;
  final DateTime? lastReadTime;
  final double readingVelocity;
  final Duration estimatedTimeRemaining;

  const ReadingProgress({
    required this.bookId,
    this.currentCFI,
    required this.currentChapterIndex,
    required this.totalChapters,
    required this.fractionInChapter,
    required this.overallProgress,
    this.currentChapterTitle,
    this.lastReadTime,
    required this.readingVelocity,
    required this.estimatedTimeRemaining,
  });

  /// Creates empty progress for a book.
  factory ReadingProgress.empty(String bookId) {
    return ReadingProgress(
      bookId: bookId,
      currentChapterIndex: 0,
      totalChapters: 1,
      fractionInChapter: 0.0,
      overallProgress: 0.0,
      readingVelocity: 0.0,
      estimatedTimeRemaining: Duration.zero,
    );
  }

  /// Gets a human-readable progress description.
  String get progressDescription {
    final percentage = (overallProgress * 100).toStringAsFixed(1);
    final chapterInfo = currentChapterTitle != null 
        ? 'in "$currentChapterTitle"'
        : 'in chapter ${currentChapterIndex + 1}';
    
    return '$percentage% complete $chapterInfo';
  }

  @override
  String toString() => progressDescription;
}

/// Represents reading statistics for a book.
class ReadingStatistics {
  final String bookId;
  final Duration totalReadingTime;
  final double averageWordsPerMinute;
  final int sessionsCount;
  final double totalProgress;
  final DateTime? firstStarted;
  final DateTime? lastRead;
  final int milestoneCount;

  const ReadingStatistics({
    required this.bookId,
    required this.totalReadingTime,
    required this.averageWordsPerMinute,
    required this.sessionsCount,
    required this.totalProgress,
    this.firstStarted,
    this.lastRead,
    required this.milestoneCount,
  });

  /// Creates empty statistics.
  factory ReadingStatistics.empty(String bookId) {
    return ReadingStatistics(
      bookId: bookId,
      totalReadingTime: Duration.zero,
      averageWordsPerMinute: 0.0,
      sessionsCount: 0,
      totalProgress: 0.0,
      milestoneCount: 0,
    );
  }
}

/// Represents a reading session (group of milestones).
class ReadingSession {
  final List<ReadingMilestone> milestones;
  final DateTime startTime;
  final DateTime endTime;

  const ReadingSession({
    required this.milestones,
    required this.startTime,
    required this.endTime,
  });

  /// Duration of this reading session.
  Duration get duration => endTime.difference(startTime);

  /// Number of words read in this session.
  int get wordsRead {
    return milestones.fold(0, (sum, milestone) {
      return sum + (milestone.sessionData['wordsRead'] as int? ?? 0);
    });
  }
}

/// Data structure for synchronizing reading data between devices.
class SyncData {
  final String bookId;
  final ReadingPosition? position;
  final List<ReadingMilestone> milestones;
  final DateTime exportTimestamp;

  const SyncData({
    required this.bookId,
    this.position,
    required this.milestones,
    required this.exportTimestamp,
  });

  /// Converts to JSON for serialization.
  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'position': position?.toJson(),
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'exportTimestamp': exportTimestamp.toIso8601String(),
    };
  }

  /// Creates from JSON.
  factory SyncData.fromJson(Map<String, dynamic> json) {
    return SyncData(
      bookId: json['bookId'],
      position: json['position'] != null 
          ? ReadingPosition.fromJson(json['position'])
          : null,
      milestones: (json['milestones'] as List)
          .map((m) => ReadingMilestone.fromJson(m))
          .toList(),
      exportTimestamp: DateTime.parse(json['exportTimestamp']),
    );
  }
}

/// Abstract interface for position storage implementations.
abstract class PositionStorage {
  /// Saves a reading position.
  Future<void> savePosition(ReadingPosition position);

  /// Gets the saved reading position for a book.
  Future<ReadingPosition?> getPosition(String bookId);

  /// Saves a reading milestone.
  Future<void> saveMilestone(ReadingMilestone milestone);

  /// Gets all milestones for a book, ordered by timestamp descending.
  Future<List<ReadingMilestone>> getMilestones(String bookId);

  /// Deletes all data for a book.
  Future<void> deleteBookData(String bookId);
}