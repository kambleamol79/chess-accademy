<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class PuzzleRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(): array
    {
        return $this->pdo->query('SELECT * FROM puzzles ORDER BY id DESC')->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM puzzles WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @return array<string,mixed>|null */
    public function findRandomByDifficulty(string $difficulty, ?int $excludeId = null): ?array
    {
        if ($excludeId !== null && $excludeId > 0) {
            $stmt = $this->pdo->prepare(
                'SELECT * FROM puzzles
                 WHERE difficulty = :difficulty AND id != :exclude_id
                 ORDER BY RAND() LIMIT 1'
            );
            $stmt->execute(['difficulty' => $difficulty, 'exclude_id' => $excludeId]);
            $row = $stmt->fetch();
            if ($row !== false) {
                return $row;
            }
        }

        $stmt = $this->pdo->prepare(
            'SELECT * FROM puzzles WHERE difficulty = :difficulty ORDER BY RAND() LIMIT 1'
        );
        $stmt->execute(['difficulty' => $difficulty]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /**
     * Pick a puzzle the student has not seen recently; falls back to random.
     *
     * @return array<string,mixed>|null
     */
    public function findNextForStudent(string $difficulty, ?int $studentId, ?int $excludeId = null): ?array
    {
        $excludeIds = [];
        if ($excludeId !== null && $excludeId > 0) {
            $excludeIds[] = $excludeId;
        }

        if ($studentId !== null) {
            $stmt = $this->pdo->prepare(
                'SELECT puzzle_id FROM puzzle_attempts
                 WHERE student_id = :student_id
                 GROUP BY puzzle_id
                 ORDER BY MAX(id) DESC
                 LIMIT 15'
            );
            $stmt->execute(['student_id' => $studentId]);
            while ($row = $stmt->fetch()) {
                $excludeIds[] = (int) $row['puzzle_id'];
            }
        }

        $excludeIds = array_values(array_unique(array_filter($excludeIds, fn (int $id): bool => $id > 0)));

        if ($excludeIds !== []) {
            $placeholders = implode(',', array_fill(0, count($excludeIds), '?'));
            $sql = "SELECT * FROM puzzles
                    WHERE difficulty = ? AND id NOT IN ($placeholders)
                    ORDER BY RAND() LIMIT 1";
            $stmt = $this->pdo->prepare($sql);
            $params = array_merge([$difficulty], $excludeIds);
            $stmt->execute($params);
            $row = $stmt->fetch();
            if ($row !== false) {
                return $row;
            }
        }

        return $this->findRandomByDifficulty($difficulty, $excludeId);
    }

    /** @return list<array<string,mixed>> */
    public function findByDifficulty(string $difficulty): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM puzzles WHERE difficulty = :difficulty ORDER BY id ASC'
        );
        $stmt->execute(['difficulty' => $difficulty]);

        return $stmt->fetchAll();
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO puzzles (title, fen, solution_moves, difficulty, created_by)
             VALUES (:title, :fen, :solution_moves, :difficulty, :created_by)'
        );
        $stmt->execute([
            'title' => $data['title'] ?? null,
            'fen' => $data['fen'],
            'solution_moves' => $data['solution_moves'],
            'difficulty' => $data['difficulty'] ?? 'medium',
            'created_by' => $data['created_by'] ?? null,
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    public function recordAttempt(int $puzzleId, int $studentId, bool $isCorrect): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO puzzle_attempts (puzzle_id, student_id, is_correct) VALUES (:puzzle_id, :student_id, :is_correct)'
        );
        $stmt->execute([
            'puzzle_id' => $puzzleId,
            'student_id' => $studentId,
            'is_correct' => $isCorrect ? 1 : 0,
        ]);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM puzzles WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }
}
