import 'chess_game.dart';

class PracticeGameMoveRecord {
  PracticeGameMoveRecord({
    required this.ply,
    required this.san,
    required this.uci,
    required this.color,
    required this.player,
    required this.fenAfter,
  });

  final int ply;
  final String san;
  final String uci;
  final String color;
  final String player;
  final String fenAfter;

  factory PracticeGameMoveRecord.fromJson(Map<String, dynamic> json) {
    return PracticeGameMoveRecord(
      ply: json['ply'] as int,
      san: json['san'] as String,
      uci: json['uci'] as String,
      color: json['color'] as String,
      player: json['player'] as String,
      fenAfter: (json['fen_after'] ?? json['fenAfter']) as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'ply': ply,
        'san': san,
        'uci': uci,
        'color': color,
        'player': player,
        'fen_after': fenAfter,
      };
}

class PracticeSessionSummary {
  PracticeSessionSummary({
    required this.id,
    required this.mode,
    required this.level,
    required this.playerColor,
    required this.timeControlMinutes,
    required this.startFen,
    required this.result,
    required this.createdAt,
    this.endedAt,
    this.moveCount,
  });

  final int id;
  final PracticeMode mode;
  final String? level;
  final PlayerColor playerColor;
  final int timeControlMinutes;
  final String startFen;
  final String result;
  final String? endedAt;
  final String createdAt;
  final int? moveCount;

  factory PracticeSessionSummary.fromJson(Map<String, dynamic> json) {
    final modeRaw = json['mode'] as String? ?? 'vs_computer';
    final mode = modeRaw == 'freePlay' || modeRaw == 'free_play'
        ? PracticeMode.freePlay
        : PracticeMode.vsComputer;
    final colorRaw = json['player_color'] as String? ?? 'white';
    return PracticeSessionSummary(
      id: json['id'] as int,
      mode: mode,
      level: json['level'] as String?,
      playerColor: colorRaw == 'black' ? PlayerColor.black : PlayerColor.white,
      timeControlMinutes: json['time_control_minutes'] as int? ?? 10,
      startFen: json['start_fen'] as String,
      result: json['result'] as String? ?? 'ended',
      endedAt: json['ended_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      moveCount: json['move_count'] as int?,
    );
  }

  String get label {
    final date = DateTime.tryParse(createdAt);
    final dateStr = date != null
        ? '${_month(date.month)} ${date.day}, ${date.year}'
        : createdAt;
    final modeLabel = mode == PracticeMode.vsComputer ? 'Vs Stockfish' : 'Free play';
    final n = moveCount ?? 0;
    return '$dateStr · $modeLabel · $n move${n == 1 ? '' : 's'}';
  }

  static String _month(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }
}

class PracticeSessionDetail {
  PracticeSessionDetail({required this.session, required this.moves});

  final PracticeSessionSummary session;
  final List<PracticeGameMoveRecord> moves;

  factory PracticeSessionDetail.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['session'] as Map<String, dynamic>? ?? json;
    final movesJson = json['moves'] as List<dynamic>? ?? [];
    return PracticeSessionDetail(
      session: PracticeSessionSummary.fromJson(sessionJson),
      moves: movesJson
          .map((e) => PracticeGameMoveRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
