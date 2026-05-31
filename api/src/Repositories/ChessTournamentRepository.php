<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class ChessTournamentRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function list(?string $status = null): array
    {
        $sql = 'SELECT t.*, u.first_name AS creator_first_name, u.last_name AS creator_last_name,
                       (SELECT COUNT(*) FROM chess_tournament_entries e WHERE e.tournament_id = t.id) AS entry_count
                FROM chess_tournaments t
                LEFT JOIN users u ON u.id = t.created_by
                WHERE 1=1';
        $params = [];
        if ($status !== null) {
            $sql .= ' AND t.status = :status';
            $params['status'] = $status;
        }
        $sql .= ' ORDER BY t.starts_at DESC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT t.*, u.first_name AS creator_first_name, u.last_name AS creator_last_name
             FROM chess_tournaments t
             LEFT JOIN users u ON u.id = t.created_by
             WHERE t.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO chess_tournaments (title, description, starts_at, time_control_minutes, status, created_by)
             VALUES (:title, :description, :starts_at, :time_control, :status, :created_by)'
        );
        $stmt->execute([
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'starts_at' => $data['starts_at'],
            'time_control' => $data['time_control_minutes'],
            'status' => $data['status'] ?? 'registration',
            'created_by' => $data['created_by'] ?? null,
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    public function updateStatus(int $id, string $status): ?array
    {
        $stmt = $this->pdo->prepare('UPDATE chess_tournaments SET status = :status WHERE id = :id');
        $stmt->execute(['status' => $status, 'id' => $id]);

        return $this->findById($id);
    }

    public function addEntry(int $tournamentId, int $studentId): bool
    {
        $stmt = $this->pdo->prepare(
            'INSERT IGNORE INTO chess_tournament_entries (tournament_id, student_id) VALUES (:tournament_id, :student_id)'
        );
        $stmt->execute(['tournament_id' => $tournamentId, 'student_id' => $studentId]);

        return $stmt->rowCount() > 0;
    }

    /** @return list<array<string,mixed>> */
    public function entries(int $tournamentId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT e.*, u.first_name, u.last_name, u.email
             FROM chess_tournament_entries e
             INNER JOIN students s ON s.id = e.student_id
             INNER JOIN users u ON u.id = s.user_id
             WHERE e.tournament_id = :id
             ORDER BY e.joined_at ASC'
        );
        $stmt->execute(['id' => $tournamentId]);

        return $stmt->fetchAll();
    }

    public function isEntered(int $tournamentId, int $studentId): bool
    {
        $stmt = $this->pdo->prepare(
            'SELECT 1 FROM chess_tournament_entries WHERE tournament_id = :t AND student_id = :s LIMIT 1'
        );
        $stmt->execute(['t' => $tournamentId, 's' => $studentId]);

        return $stmt->fetch() !== false;
    }
}
