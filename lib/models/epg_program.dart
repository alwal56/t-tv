class EpgProgram {
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? category;

  EpgProgram({
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.category,
  });

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0;
    if (now.isAfter(end)) return 1;
    final total = end.difference(start).inSeconds;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }

  String get timeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(start)} - ${fmt(end)}';
  }
}
