<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class StudentRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(): array
    {
        $sql = 'SELECT s.*, u.email, u.first_name, u.last_name, u.phone, u.is_active
                FROM students s
                INNER JOIN users u ON u.id = s.user_id
                ORDER BY s.id ASC';
        return $this->pdo->query($sql)->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT s.*, u.email, u.first_name, u.last_name, u.phone, u.is_active
             FROM students s INNER JOIN users u ON u.id = s.user_id WHERE s.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @return array<string,mixed>|null */
    public function findByUserId(int $userId): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM students WHERE user_id = :user_id');
        $stmt->execute(['user_id' => $userId]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        $student = $this->findById($id);
        if ($student === null) {
            return null;
        }

        $userFields = ['first_name', 'last_name', 'email', 'phone'];
        $userSets = [];
        $userParams = ['id' => $student['user_id']];
        foreach ($userFields as $f) {
            if (array_key_exists($f, $data)) {
                $userSets[] = "{$f} = :{$f}";
                $userParams[$f] = $data[$f];
            }
        }
        if ($userSets !== []) {
            $this->pdo->prepare('UPDATE users SET ' . implode(', ', $userSets) . ' WHERE id = :id')->execute($userParams);
        }

        $fields = ['parent_name', 'parent_phone', 'date_of_birth', 'chess_rating'];
        $sets = [];
        $params = ['id' => $id];
        foreach ($fields as $f) {
            if (array_key_exists($f, $data)) {
                $sets[] = "{$f} = :{$f}";
                $params[$f] = $data[$f];
            }
        }
        if ($sets !== []) {
            $this->pdo->prepare('UPDATE students SET ' . implode(', ', $sets) . ' WHERE id = :id')->execute($params);
        }

        return $this->findById($id);
    }

    public function delete(int $id): bool
    {
        $student = $this->findById($id);
        if ($student === null) {
            return false;
        }
        $this->pdo->prepare('DELETE FROM users WHERE id = :id')->execute(['id' => $student['user_id']]);

        return true;
    }
}
