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
