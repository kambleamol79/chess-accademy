<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use ChessAcademy\Repositories\ChessLiveMatchRepository;

final class ChessLiveMatchService
{
    public function __construct(
        private readonly ChessLiveMatchRepository $matches,
        private readonly ChessRulesService $rules,
        private readonly LiveMatchBroadcaster $broadcaster,
    ) {}

    /**
     * @param array<string,mixed> $match
     * @return array<string,mixed>
     */
    public function stateForStudent(array $match, int $studentId): array
    {
        $beforeStatus = (string) ($match['status'] ?? '');
        $this->matches->syncClock((int) $match['id']);
        $match = $this->matches->findById((int) $match['id']) ?? $match;
        if ($beforeStatus === 'active' && ($match['status'] ?? '') === 'completed') {
            $this->broadcaster->publish((int) $match['id'], 'timeout');
        }
        $moves = $this->matches->moves((int) $match['id']);

        $isWhite = (int) $match['white_student_id'] === $studentId;
        $yourColor = $isWhite ? 'w' : 'b';
        $active = ChessFenHelper::activeColor((string) $match['current_fen']);
        $isYourTurn = $match['status'] === 'active' && $active === $yourColor;

        return [
            'match' => $this->formatMatch($match),
            'moves' => array_map(fn (array $m): array => $this->formatMove($m), $moves),
            'your_color' => $isWhite ? 'white' : 'black',
            'is_your_turn' => $isYourTurn,
            'white_ms_remaining' => (int) $match['white_ms_remaining'],
            'black_ms_remaining' => (int) $match['black_ms_remaining'],
            'event_seq' => (int) ($match['event_seq'] ?? 0),
        ];
    }

    /**
     * @param array<string,mixed> $match
     * @param array<string,mixed> $body
     * @return array<string,mixed>
     */
    public function applyMove(array $match, int $studentId, array $body): array
    {
        if ($match['status'] !== 'active') {
            throw new \InvalidArgumentException('Match is not active');
        }

        $isWhite = (int) $match['white_student_id'] === $studentId;
        $isBlack = (int) $match['black_student_id'] === $studentId;
        if (!$isWhite && !$isBlack) {
            throw new \InvalidArgumentException('You are not in this match');
        }

        $expectedColor = ChessFenHelper::activeColor((string) $match['current_fen']);
        $yourColor = $isWhite ? 'w' : 'b';
        if ($expectedColor !== $yourColor) {
            throw new \InvalidArgumentException('Not your turn');
        }

        $uci = trim((string) ($body['uci'] ?? ''));
        $clientFen = trim((string) ($body['fen_after'] ?? $body['fenAfter'] ?? ''));
        if ($uci === '') {
            throw new \InvalidArgumentException('uci is required');
        }

        $applied = $this->rules->applyUci((string) $match['current_fen'], $uci);
        if ($clientFen !== '' && !$this->rules->fenEquivalent($applied['fen_after'], $clientFen)) {
            throw new \InvalidArgumentException('Position does not match server rules');
        }

        $moves = $this->matches->moves((int) $match['id']);
        $ply = count($moves) + 1;

        $this->matches->addMove((int) $match['id'], [
            'ply' => $ply,
            'uci' => $uci,
            'san' => $applied['san'],
            'color' => $yourColor,
            'student_id' => $studentId,
            'fen_after' => $applied['fen_after'],
        ]);

        $matchId = (int) $match['id'];
        if ($applied['game_over'] && $applied['result'] !== null) {
            $this->matches->finish($matchId, $applied['result']);
        }
        $this->broadcaster->publish($matchId, $applied['game_over'] ? 'finished' : 'move');

        $updated = $this->matches->findById($matchId);
        if ($updated === null) {
            throw new \RuntimeException('Match not found after move');
        }

        return $this->stateForStudent($updated, $studentId);
    }

    /** @param array<string,mixed> $match */
    public function formatMatch(array $match): array
    {
        return [
            'id' => (int) $match['id'],
            'tournament_id' => $match['tournament_id'] !== null ? (int) $match['tournament_id'] : null,
            'white_student_id' => (int) $match['white_student_id'],
            'black_student_id' => (int) $match['black_student_id'],
            'white_name' => trim(($match['white_first_name'] ?? '') . ' ' . ($match['white_last_name'] ?? '')),
            'black_name' => trim(($match['black_first_name'] ?? '') . ' ' . ($match['black_last_name'] ?? '')),
            'status' => $match['status'],
            'result' => $match['result'],
            'time_control_minutes' => (int) $match['time_control_minutes'],
            'current_fen' => $match['current_fen'],
            'started_at' => $match['started_at'],
            'ended_at' => $match['ended_at'],
            'event_seq' => (int) ($match['event_seq'] ?? 0),
        ];
    }

    /** @param array<string,mixed> $move */
    public function formatMove(array $move): array
    {
        return [
            'ply' => (int) $move['ply'],
            'uci' => $move['uci'],
            'san' => $move['san'],
            'color' => $move['color'],
            'student_id' => (int) $move['student_id'],
            'fen_after' => $move['fen_after'],
        ];
    }
}
