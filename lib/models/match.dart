class Match {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final int homeTeamId;
  final int awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final String tournament;
  final String country;
  final MatchStatus status;
  final String statusText;
  final DateTime startTime;
  final int? matchMinute;

  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    required this.tournament,
    this.country = '',
    required this.status,
    required this.statusText,
    required this.startTime,
    this.matchMinute,
  });

  String get homeLogo =>
      'https://api.sofascore.com/api/v1/team/$homeTeamId/image';
  String get awayLogo =>
      'https://api.sofascore.com/api/v1/team/$awayTeamId/image';

  bool get isLive => status == MatchStatus.live;
  bool get isFinished => status == MatchStatus.finished;
  bool get isUpcoming => status == MatchStatus.upcoming;

  factory Match.fromSofaScore(Map<String, dynamic> json) {
    final statusCode = json['status']?['code'] ?? 0;
    final statusType = json['status']?['type'] ?? '';
    final statusDesc = json['status']?['description'] ?? '';

    MatchStatus matchStatus;
    if (statusType == 'inprogress') {
      matchStatus = MatchStatus.live;
    } else if (statusType == 'finished') {
      matchStatus = MatchStatus.finished;
    } else {
      matchStatus = MatchStatus.upcoming;
    }

    // Match minute from status description (e.g. "32'")
    int? minute;
    if (json['time']?['played'] != null) {
      minute = json['time']['played'] as int?;
    }

    final ts = json['startTimestamp'] as int? ?? 0;

    return Match(
      id: json['id'] as int? ?? 0,
      homeTeam: json['homeTeam']?['name'] ?? '?',
      awayTeam: json['awayTeam']?['name'] ?? '?',
      homeTeamId: json['homeTeam']?['id'] as int? ?? 0,
      awayTeamId: json['awayTeam']?['id'] as int? ?? 0,
      homeScore: json['homeScore']?['current'] as int?,
      awayScore: json['awayScore']?['current'] as int?,
      tournament: json['tournament']?['name'] ?? '',
      country: json['tournament']?['category']?['country']?['name'] ?? '',
      status: matchStatus,
      statusText: statusDesc,
      startTime: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      matchMinute: minute,
    );
  }
}

enum MatchStatus { live, finished, upcoming }
