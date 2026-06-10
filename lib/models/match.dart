class Match {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
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
    required this.homeLogo,
    required this.awayLogo,
    this.homeScore,
    this.awayScore,
    required this.tournament,
    this.country = '',
    required this.status,
    required this.statusText,
    required this.startTime,
    this.matchMinute,
  });

  bool get isLive     => status == MatchStatus.live;
  bool get isFinished => status == MatchStatus.finished;
  bool get isUpcoming => status == MatchStatus.upcoming;

  // ─── ESPN factory ───────────────────────────────────────────────────────────

  factory Match.fromEspn(Map<String, dynamic> event, String leagueName) {
    final comps = (event['competitions'] as List<dynamic>?) ?? [];
    final comp  = comps.isNotEmpty
        ? comps.first as Map<String, dynamic>
        : <String, dynamic>{};

    final competitors = (comp['competitors'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? homeComp, awayComp;
    for (final c in competitors) {
      final m = c as Map<String, dynamic>;
      if (m['homeAway'] == 'home') homeComp = m;
      else                         awayComp = m;
    }

    final statusData = comp['status'] as Map<String, dynamic>?;
    final statusType = statusData?['type'] as Map<String, dynamic>?;
    final state      = statusType?['state'] as String? ?? '';

    MatchStatus matchStatus;
    if      (state == 'in')   matchStatus = MatchStatus.live;
    else if (state == 'post') matchStatus = MatchStatus.finished;
    else                      matchStatus = MatchStatus.upcoming;

    final homeTeamData = homeComp?['team'] as Map<String, dynamic>?;
    final awayTeamData = awayComp?['team'] as Map<String, dynamic>?;

    int? homeScore, awayScore;
    if (homeComp?['score'] != null) homeScore = int.tryParse(homeComp!['score'].toString());
    if (awayComp?['score'] != null) awayScore = int.tryParse(awayComp!['score'].toString());

    final dateStr   = event['date'] as String? ?? '';
    final startTime = DateTime.tryParse(dateStr) ?? DateTime.now();

    int? matchMinute;
    final detail = statusType?['detail'] as String? ?? '';
    if (detail.contains("'")) {
      matchMinute = int.tryParse(detail.replaceAll("'", '').trim());
    }

    return Match(
      id:          int.tryParse(event['id']?.toString() ?? '0') ?? 0,
      homeTeam:    homeTeamData?['displayName'] ?? homeTeamData?['name'] ?? '?',
      awayTeam:    awayTeamData?['displayName'] ?? awayTeamData?['name'] ?? '?',
      homeLogo:    _espnLogo(homeTeamData),
      awayLogo:    _espnLogo(awayTeamData),
      homeScore:   homeScore,
      awayScore:   awayScore,
      tournament:  leagueName,
      status:      matchStatus,
      statusText:  statusType?['shortDetail'] ?? statusType?['detail'] ?? '',
      startTime:   startTime,
      matchMinute: matchMinute,
    );
  }

  static String _espnLogo(Map<String, dynamic>? teamData) {
    if (teamData == null) return '';
    final logos = teamData['logos'] as List<dynamic>?;
    if (logos != null && logos.isNotEmpty) {
      return (logos.first as Map<String, dynamic>)['href'] as String? ?? '';
    }
    final id = teamData['id'] as String? ?? '';
    return id.isNotEmpty
        ? 'https://a.espncdn.com/i/teamlogos/soccer/500/$id.png'
        : '';
  }

  // ─── SofaScore factory (kept as fallback) ──────────────────────────────────

  factory Match.fromSofaScore(Map<String, dynamic> json) {
    final statusType = json['status']?['type'] ?? '';
    final statusDesc = json['status']?['description'] ?? '';

    MatchStatus matchStatus;
    if      (statusType == 'inprogress') matchStatus = MatchStatus.live;
    else if (statusType == 'finished')   matchStatus = MatchStatus.finished;
    else                                 matchStatus = MatchStatus.upcoming;

    final homeTeamId = json['homeTeam']?['id'] as int? ?? 0;
    final awayTeamId = json['awayTeam']?['id'] as int? ?? 0;
    final ts         = json['startTimestamp'] as int? ?? 0;

    int? minute;
    if (json['time']?['played'] != null) minute = json['time']['played'] as int?;

    return Match(
      id:          json['id'] as int? ?? 0,
      homeTeam:    json['homeTeam']?['name'] ?? '?',
      awayTeam:    json['awayTeam']?['name'] ?? '?',
      homeLogo:    'https://api.sofascore.com/api/v1/team/$homeTeamId/image',
      awayLogo:    'https://api.sofascore.com/api/v1/team/$awayTeamId/image',
      homeScore:   json['homeScore']?['current'] as int?,
      awayScore:   json['awayScore']?['current'] as int?,
      tournament:  json['tournament']?['name'] ?? '',
      country:     json['tournament']?['category']?['country']?['name'] ?? '',
      status:      matchStatus,
      statusText:  statusDesc,
      startTime:   DateTime.fromMillisecondsSinceEpoch(ts * 1000),
      matchMinute: minute,
    );
  }
}

enum MatchStatus { live, finished, upcoming }
