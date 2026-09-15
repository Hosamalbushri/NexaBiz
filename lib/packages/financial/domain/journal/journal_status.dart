/// Status lifecycle of a JournalEntry.
enum JournalStatus {
  draft,
  posted,
  reversed;

  static JournalStatus fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'DRAFT':
        return JournalStatus.draft;
      case 'POSTED':
        return JournalStatus.posted;
      case 'REVERSED':
        return JournalStatus.reversed;
      default:
        throw ArgumentError('Unknown JournalStatus: $raw');
    }
  }

  String toDbValue() => name.toUpperCase();

  bool get isDraft => this == JournalStatus.draft;
  bool get isPosted => this == JournalStatus.posted;
  bool get isReversed => this == JournalStatus.reversed;
}
