<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use ChessAcademy\Services\ChessFenHelper;
use PDO;

final class ChessLiveMatchRepository
{
    private const START_FEN = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
    private const MAX_TIME_CONTROL_MINUTES = 180;
    /** INT UNSIGNED max; keep clock ms safely below this. */
    private const MAX_CLOCK_MS = 2_147_483_647;

    public function __construct(private readonly PDO $pdo) {}

    public static function clockMsForMinutes(int $minutes): int
    {
        $minutes = max(1, min(self::MAX_TIME_CONTROL_MINUTES, $minutes));

        return min(self::MAX_CLOCK_MS, $minutes * 60 * 1000);
    }

    private static function clampClockMs(int $ms, int $maxMs): int
    {
        return max(0, min($maxMs, $ms));
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT m.*,
                    wu.first_name AS white_first_name, wu.last_name AS white_last_name,
                    bu.first_name AS black_first_name, bu.last_name AS black_last_name
             FROM chess_live_matches m
             INNER JOIN students ws ON ws.id = m.white_student_id
             INNER JOIN users wu ON wu.id = ws.user_id
             INNER JOIN students bs ON bs.id = m.black_student_id
             INNER JOIN users bu ON bu.id = bs.user_id
             WHERE m.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @return list<array<string,mixed>> */
    public function moves(int $matchId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM chess_live_moves WHERE match_id = :id ORDER BY ply ASC'
        );
        $stmt->execute(['id' => $matchId]);

        return $stmt->fetchAll();
    }

    /** @return list<array<string,mixed>> */
    public function forStudent(int $studentId, int $limit = 20): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT m.*,
                    wu.first_name AS white_first_name, wu.last_name AS white_last_name,
                    bu.first_name AS black_first_name, bu.last_name AS black_last_name
             FROM chess_live_matches m
             INNER JOIN students ws ON ws.id = m.white_student_id
             INNER JOIN users wu ON wu.id = ws.user_id
             INNER JOIN students bs ON bs.id = m.black_student_id
             INNER JOIN users bu ON bu.id = bs.user_id
             WHERE m.white_student_id = :sid1 OR m.black_student_id = :sid2
             ORDER BY m.id DESC
             LIMIT ' . max(1, min(50, $limit))
        );
        $stmt->execute(['sid1' => $studentId, 'sid2' => $studentId]);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function activeForStudent(int $studentId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT id FROM chess_live_matches
             WHERE status = \'active\' AND (white_student_id = :sid1 OR black_student_id = :sid2)
             ORDER BY id DESC LIMIT 1'
        );
        $stmt->execute(['sid1' => $studentId, 'sid2' => $studentId]);
        $row = $stmt->fetch();
        if ($row === false) {
            return null;
        }

        return $this->findById((int) $row['id']);
    }

    /** @return array<string,mixed> */
    public function createPair(int $whiteStudentId, int $blackStudentId, ?int $tournamentId, int $timeControlMinutes): array
    {
        $timeControlMinutes = max(1, min(self::MAX_TIME_CONTROL_MINUTES, $timeControlMinutes));
        $ms = self::clockMsForMinutes($timeControlMinutes);
        $stmt = $this->pdo->prepare(
            'INSERT INTO chess_live_matches
             (tournament_id, white_student_id, black_student_id, status, time_control_minutes,
              white_ms_remaining, black_ms_remaining, current_fen, start_fen, started_at, clock_side, clock_since)
             VALUES (:tournament_id, :white, :black, \'active\', :tc, :wms, :bms, :fen_current, :fen_start, NOW(), \'w\', NOW())'
        );
        $fen = self::START_FEN;
        $stmt->execute([
            'tournament_id' => $tournamentId,
            'white' => $whiteStudentId,
            'black' => $blackStudentId,
            'tc' => $timeControlMinutes,
            'wms' => $ms,
            'bms' => $ms,
            'fen_current' => $fen,
            'fen_start' => $fen,
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    public function syncClock(int $matchId): void
    {
        $match = $this->findById($matchId);
        if ($match === null || $match['status'] !== 'active' || $match['clock_side'] === null || $match['clock_since'] === null) {
            return;
        }

        $since = strtotime((string) $match['clock_since']);
        if ($since === false) {
            return;
        }

        // Non-negative elapsed only (avoids adding time when clock_since is ahead of PHP time).
        $elapsed = max(0, (int) ((time() - $since) * 1000));
        $side = (string) $match['clock_side'];
        $maxMs = self::clockMsForMinutes((int) ($match['time_control_minutes'] ?? 10));
        $whiteMs = self::clampClockMs((int) $match['white_ms_remaining'], $maxMs);
        $blackMs = self::clampClockMs((int) $match['black_ms_remaining'], $maxMs);

        if ($side === 'w') {
            $whiteMs = self::clampClockMs($whiteMs - $elapsed, $maxMs);
        } else {
            $blackMs = self::clampClockMs($blackMs - $elapsed, $maxMs);
        }

        $stmt = $this->pdo->prepare(
            'UPDATE chess_live_matches
             SET white_ms_remaining = :w, black_ms_remaining = :b, clock_since = NOW()
             WHERE id = :id'
        );
        $stmt->execute(['w' => $whiteMs, 'b' => $blackMs, 'id' => $matchId]);

        if ($whiteMs <= 0 || $blackMs <= 0) {
            $winner = $whiteMs <= 0 ? 'black_win' : 'white_win';
            $this->finish($matchId, $winner);
        }
    }

    /** @param array<string,mixed> $move */
    public function addMove(int $matchId, array $move): void
    {
        $this->syncClock($matchId);

        $stmt = $this->pdo->prepare(
            'INSERT INTO chess_live_moves (match_id, ply, uci, san, color, student_id, fen_after)
             VALUES (:match_id, :ply, :uci, :san, :color, :student_id, :fen_after)'
        );
        $stmt->execute([
            'match_id' => $matchId,
            'ply' => $move['ply'],
            'uci' => $move['uci'],
            'san' => $move['san'],
            'color' => $move['color'],
            'student_id' => $move['student_id'],
            'fen_after' => $move['fen_after'],
        ]);

        $nextSide = ChessFenHelper::activeColor((string) $move['fen_after']);
        $stmt = $this->pdo->prepare(
            'UPDATE chess_live_matches
             SET current_fen = :fen, clock_side = :side, clock_since = NOW()
             WHERE id = :id AND status = \'active\''
        );
        $stmt->execute(['fen' => $move['fen_after'], 'side' => $nextSide, 'id' => $matchId]);
    }

    public function finish(int $matchId, string $result): ?array
    {
        $stmt = $this->pdo->prepare(
            'UPDATE chess_live_matches
             SET status = \'completed\', result = :result, ended_at = NOW(), clock_side = NULL, clock_since = NULL
             WHERE id = :id'
        );
        $stmt->execute(['result' => $result, 'id' => $matchId]);

        return $this->findById($matchId);
    }

    public function bumpEventSeq(int $matchId): int
    {
        $stmt = $this->pdo->prepare(
            'UPDATE chess_live_matches SET event_seq = event_seq + 1 WHERE id = :id'
        );
        $stmt->execute(['id' => $matchId]);

        return $this->eventSeq($matchId);
    }

    public function eventSeq(int $matchId): int
    {
        $stmt = $this->pdo->prepare('SELECT event_seq FROM chess_live_matches WHERE id = :id');
        $stmt->execute(['id' => $matchId]);
        $row = $stmt->fetch();

        return $row === false ? 0 : (int) $row['event_seq'];
    }

    /** @return array<string,mixed>|null */
    public function revision(int $matchId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT m.id, m.status, m.event_seq, m.white_student_id, m.black_student_id,
                    (SELECT COUNT(*) FROM chess_live_moves WHERE match_id = m.id) AS ply_count
             FROM chess_live_matches m
             WHERE m.id = :id'
        );
        $stmt->execute(['id' => $matchId]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    public function joinQueue(int $studentId, ?int $tournamentId): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO chess_matchmaking_queue (student_id, tournament_id) VALUES (:s, :t)
             ON DUPLICATE KEY UPDATE joined_at = CURRENT_TIMESTAMP'
        );
        $stmt->execute(['s' => $studentId, 't' => $tournamentId]);
    }

    public function leaveQueue(int $studentId, ?int $tournamentId): void
    {
        if ($tournamentId === null) {
            $stmt = $this->pdo->prepare('DELETE FROM chess_matchmaking_queue WHERE student_id = :s AND tournament_id IS NULL');
            $stmt->execute(['s' => $studentId]);
        } else {
            $stmt = $this->pdo->prepare(
                'DELETE FROM chess_matchmaking_queue WHERE student_id = :s AND tournament_id = :t'
            );
            $stmt->execute(['s' => $studentId, 't' => $tournamentId]);
        }
    }

    /** @return array<string,mixed>|null */
    public function findQueueOpponent(int $studentId, ?int $tournamentId): ?array
    {
        $sql = 'SELECT student_id FROM chess_matchmaking_queue
                WHERE student_id != :s';
        $params = ['s' => $studentId];
        if ($tournamentId === null) {
            $sql .= ' AND tournament_id IS NULL';
        } else {
            $sql .= ' AND tournament_id = :t';
            $params['t'] = $tournamentId;
        }
        $sql .= ' ORDER BY joined_at ASC LIMIT 1';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        $row = $stmt->fetch();
        if ($row === false) {
            return null;
        }

        return ['student_id' => (int) $row['student_id']];
    }

    public function clearQueuePair(int $studentA, int $studentB): void
    {
        $stmt = $this->pdo->prepare(
            'DELETE FROM chess_matchmaking_queue WHERE student_id = :a OR student_id = :b'
        );
        $stmt->execute(['a' => $studentA, 'b' => $studentB]);
    }

    /**
     * Active matches where the player to move has not played since
     * time_control_minutes + grace minutes (based on last move or match start).
     *
     * @return list<array<string,mixed>>
     */
    public function findInactiveActiveMatches(int $graceMinutes): array
    {
        $graceMinutes = max(0, $graceMinutes);
        $stmt = $this->pdo->prepare(
            'SELECT m.id, m.clock_side, m.current_fen, m.time_control_minutes,
                    COALESCE(lm.last_move_at, m.started_at, m.created_at) AS turn_started_at
             FROM chess_live_matches m
             LEFT JOIN (
                 SELECT match_id, MAX(created_at) AS last_move_at
                 FROM chess_live_moves
                 GROUP BY match_id
             ) lm ON lm.match_id = m.id
             WHERE m.status = \'active\'
               AND TIMESTAMPDIFF(
                   MINUTE,
                   COALESCE(lm.last_move_at, m.started_at, m.created_at),
                   NOW()
               ) >= m.time_control_minutes + :grace'
        );
        $stmt->execute(['grace' => $graceMinutes]);

        return $stmt->fetchAll();
    }

    /** Player on the clock loses — opponent wins. */
    public static function winResultForSideToMove(string $side): string
    {
        return $side === 'w' ? 'black_win' : 'white_win';
    }

    /** @return list<array<string,mixed>> */
    public function createRoundRobinPairings(int $tournamentId, int $timeControlMinutes): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT student_id FROM chess_tournament_entries WHERE tournament_id = :id ORDER BY student_id'
        );
        $stmt->execute(['id' => $tournamentId]);
        $ids = array_map(fn ($r) => (int) $r['student_id'], $stmt->fetchAll());

        $created = [];
        $n = count($ids);
        for ($i = 0; $i < $n; $i++) {
            for ($j = $i + 1; $j < $n; $j++) {
                $white = $ids[$i];
                $black = $ids[$j];
                if (($i + $j) % 2 === 1) {
                    [$white, $black] = [$black, $white];
                }
                $created[] = $this->createPair($white, $black, $tournamentId, $timeControlMinutes);
            }
        }

        return $created;
    }
}
