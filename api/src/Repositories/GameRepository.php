<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class GameRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(?int $studentId = null): array
    {
        $sql = 'SELECT g.*, u.first_name, u.last_name
                FROM games g
                INNER JOIN students s ON s.id = g.student_id
                INNER JOIN users u ON u.id = s.user_id
                WHERE 1=1';
        $params = [];
        if ($studentId !== null) {
            $sql .= ' AND g.student_id = :student_id';
            $params['student_id'] = $studentId;
        }
        $sql .= ' ORDER BY g.id DESC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM games WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO games (student_id, coach_id, title, pgn, notes)
             VALUES (:student_id, :coach_id, :title, :pgn, :notes)'
        );
        $stmt->execute([
            'student_id' => $data['student_id'],
            'coach_id' => $data['coach_id'] ?? null,
            'title' => $data['title'] ?? null,
            'pgn' => $data['pgn'],
            'notes' => $data['notes'] ?? null,
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        if ($this->findById($id) === null) {
            return null;
        }
        $fields = ['coach_id', 'title', 'pgn', 'notes', 'reviewed_at'];
        $sets = [];
        $params = ['id' => $id];
        foreach ($fields as $f) {
            if (array_key_exists($f, $data)) {
                $sets[] = "{$f} = :{$f}";
                $params[$f] = $data[$f];
            }
        }
        if ($sets !== []) {
            $this->pdo->prepare('UPDATE games SET ' . implode(', ', $sets) . ' WHERE id = :id')->execute($params);
        }

        return $this->findById($id);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM games WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }
}
