class ChessTournament {
  ChessTournament({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.timeControlMinutes,
    required this.status,
    this.description,
    this.entryCount,
  });

  final int id;
  final String title;
  final String? description;
  final String startsAt;
  final int timeControlMinutes;
  final String status;
  final int? entryCount;

  factory ChessTournament.fromJson(Map<String, dynamic> json) {
    return ChessTournament(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      startsAt: json['starts_at'] as String? ?? '',
      timeControlMinutes: json['time_control_minutes'] as int? ?? 10,
      status: json['status'] as String? ?? 'scheduled',
      entryCount: json['entry_count'] as int?,
    );
  }
}

class LiveMatchSummary {
  LiveMatchSummary({
    required this.id,
    required this.whiteName,
    required this.blackName,
    required this.status,
    required this.result,
    required this.timeControlMinutes,
    required this.currentFen,
    this.tournamentId,
    this.eventSeq,
  });

  final int id;
  final int? tournamentId;
  final String whiteName;
  final String blackName;
  final String status;
  final String result;
  final int timeControlMinutes;
  final String currentFen;
  final int? eventSeq;

  factory LiveMatchSummary.fromJson(Map<String, dynamic> json) {
    return LiveMatchSummary(
      id: json['id'] as int,
      tournamentId: json['tournament_id'] as int?,
      whiteName: json['white_name'] as String? ?? 'White',
      blackName: json['black_name'] as String? ?? 'Black',
      status: json['status'] as String? ?? 'waiting',
      result: json['result'] as String? ?? 'pending',
      timeControlMinutes: json['time_control_minutes'] as int? ?? 10,
      currentFen: json['current_fen'] as String? ?? '',
      eventSeq: json['event_seq'] as int?,
    );
  }
}

class LiveMatchMove {
  LiveMatchMove({
    required this.ply,
    required this.uci,
    required this.san,
    required this.color,
    required this.fenAfter,
  });

  final int ply;
  final String uci;
  final String san;
  final String color;
  final String fenAfter;

  factory LiveMatchMove.fromJson(Map<String, dynamic> json) {
    return LiveMatchMove(
      ply: json['ply'] as int,
      uci: json['uci'] as String? ?? '',
      san: json['san'] as String? ?? '',
      color: json['color'] as String? ?? 'w',
      fenAfter: json['fen_after'] as String? ?? '',
    );
  }
}

class LiveMatchRevision {
  LiveMatchRevision({
    required this.eventSeq,
    required this.status,
    required this.plyCount,
    required this.changed,
    this.state,
  });

  final int eventSeq;
  final String status;
  final int plyCount;
  final bool changed;
  final LiveMatchState? state;

  factory LiveMatchRevision.fromJson(Map<String, dynamic> json) {
    final stateJson = json['state'];
    return LiveMatchRevision(
      eventSeq: json['event_seq'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      plyCount: json['ply_count'] as int? ?? 0,
      changed: json['changed'] as bool? ?? false,
      state: stateJson is Map<String, dynamic>
          ? LiveMatchState.fromJson(stateJson)
          : null,
    );
  }
}

class LiveMatchState {
  LiveMatchState({
    required this.match,
    required this.moves,
    required this.yourColor,
    required this.isYourTurn,
    required this.whiteMsRemaining,
    required this.blackMsRemaining,
    this.eventSeq,
  });

  final LiveMatchSummary match;
  final List<LiveMatchMove> moves;
  final String yourColor;
  final bool isYourTurn;
  final int whiteMsRemaining;
  final int blackMsRemaining;
  final int? eventSeq;

  factory LiveMatchState.fromJson(Map<String, dynamic> json) {
    return LiveMatchState(
      match: LiveMatchSummary.fromJson(json['match'] as Map<String, dynamic>),
      moves: (json['moves'] as List<dynamic>? ?? [])
          .map((e) => LiveMatchMove.fromJson(e as Map<String, dynamic>))
          .toList(),
      yourColor: json['your_color'] as String? ?? 'white',
      isYourTurn: json['is_your_turn'] as bool? ?? false,
      whiteMsRemaining: json['white_ms_remaining'] as int? ?? 0,
      blackMsRemaining: json['black_ms_remaining'] as int? ?? 0,
      eventSeq: json['event_seq'] as int?,
    );
  }
}

class QueueJoinResult {
  QueueJoinResult({required this.status, this.matchId});

  final String status;
  final int? matchId;
}

class MyMatchesResult {
  MyMatchesResult({required this.matches, this.activeMatchId});

  final List<LiveMatchSummary> matches;
  final int? activeMatchId;
}
