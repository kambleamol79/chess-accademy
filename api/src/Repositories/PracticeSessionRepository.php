<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class PracticeSessionRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function listForUser(int $userId, int $limit = 30, int $offset = 0): array
    {
        $limit = max(1, min(100, $limit));
        $offset = max(0, $offset);

        $stmt = $this->pdo->prepare(
            'SELECT s.*, COUNT(m.id) AS move_count
             FROM practice_sessions s
             LEFT JOIN practice_moves m ON m.session_id = s.id
             WHERE s.user_id = :user_id
             GROUP BY s.id
             ORDER BY s.created_at DESC
             LIMIT ' . $limit . ' OFFSET ' . $offset
        );
        $stmt->execute(['user_id' => $userId]);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findByIdForUser(int $id, int $userId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM practice_sessions WHERE id = :id AND user_id = :user_id'
        );
        $stmt->execute(['id' => $id, 'user_id' => $userId]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @return list<array<string,mixed>> */
    public function movesForSession(int $sessionId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM practice_moves WHERE session_id = :session_id ORDER BY ply ASC'
        );
        $stmt->execute(['session_id' => $sessionId]);

        return $stmt->fetchAll();
    }

    /** @param array<string,mixed> $data */
    public function create(int $userId, array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO practice_sessions
             (user_id, mode, level, player_color, time_control_minutes, start_fen, result)
             VALUES
             (:user_id, :mode, :level, :player_color, :time_control_minutes, :start_fen, :result)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'mode' => $data['mode'],
            'level' => $data['level'] ?? null,
            'player_color' => $data['player_color'],
            'time_control_minutes' => $data['time_control_minutes'],
            'start_fen' => $data['start_fen'],
            'result' => 'ongoing',
        ]);

        $id = (int) $this->pdo->lastInsertId();

        return $this->findByIdForUser($id, $userId) ?? [];
    }

    /** @param array<string,mixed> $move */
    public function addMove(int $sessionId, int $userId, array $move): ?array
    {
        $session = $this->findByIdForUser($sessionId, $userId);
        if ($session === null) {
            return null;
        }

        $stmt = $this->pdo->prepare(
            'INSERT INTO practice_moves (session_id, ply, san, uci, color, player, fen_after)
             VALUES (:session_id, :ply, :san, :uci, :color, :player, :fen_after)'
        );
        $stmt->execute([
            'session_id' => $sessionId,
            'ply' => $move['ply'],
            'san' => $move['san'],
            'uci' => $move['uci'],
            'color' => $move['color'],
            'player' => $move['player'],
            'fen_after' => $move['fen_after'],
        ]);

        $this->touchSession($sessionId);

        $stmt = $this->pdo->prepare('SELECT * FROM practice_moves WHERE id = :id');
        $stmt->execute(['id' => (int) $this->pdo->lastInsertId()]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    public function deleteLastMove(int $sessionId, int $userId): bool
    {
        $session = $this->findByIdForUser($sessionId, $userId);
        if ($session === null) {
            return false;
        }

        $stmt = $this->pdo->prepare(
            'DELETE FROM practice_moves
             WHERE session_id = :session_id
             ORDER BY ply DESC
             LIMIT 1'
        );
        $stmt->execute(['session_id' => $sessionId]);
        $this->touchSession($sessionId);

        return $stmt->rowCount() > 0;
    }

    /** @param array<string,mixed> $data */
    public function finalize(int $sessionId, int $userId, array $data): ?array
    {
        $session = $this->findByIdForUser($sessionId, $userId);
        if ($session === null) {
            return null;
        }

        $stmt = $this->pdo->prepare(
            'UPDATE practice_sessions
             SET result = :result, ended_at = NOW()
             WHERE id = :id AND user_id = :user_id'
        );
        $stmt->execute([
            'result' => $data['result'],
            'id' => $sessionId,
            'user_id' => $userId,
        ]);

        return $this->findByIdForUser($sessionId, $userId);
    }

    private function touchSession(int $sessionId): void
    {
        $stmt = $this->pdo->prepare('UPDATE practice_sessions SET updated_at = NOW() WHERE id = :id');
        $stmt->execute(['id' => $sessionId]);
    }

    /** @return array<string,mixed> */
    public function formatSessionWithMoves(array $session): array
    {
        $moves = $this->movesForSession((int) $session['id']);

        return [
            'session' => $this->formatSession($session),
            'moves' => array_map(fn (array $m): array => $this->formatMove($m), $moves),
        ];
    }

    /** @param array<string,mixed> $session */
    public function formatSession(array $session): array
    {
        return [
            'id' => (int) $session['id'],
            'mode' => $session['mode'] === 'vs_computer' ? 'vsComputer' : 'freePlay',
            'level' => $session['level'],
            'player_color' => $session['player_color'],
            'time_control_minutes' => (int) $session['time_control_minutes'],
            'start_fen' => $session['start_fen'],
            'result' => $session['result'],
            'ended_at' => $session['ended_at'],
            'created_at' => $session['created_at'],
            'updated_at' => $session['updated_at'],
            'move_count' => isset($session['move_count']) ? (int) $session['move_count'] : null,
        ];
    }

    /** @param array<string,mixed> $move */
    public function formatMove(array $move): array
    {
        return [
            'id' => (int) $move['id'],
            'ply' => (int) $move['ply'],
            'san' => $move['san'],
            'uci' => $move['uci'],
            'color' => $move['color'],
            'player' => $move['player'],
            'fen_after' => $move['fen_after'],
        ];
    }
}
