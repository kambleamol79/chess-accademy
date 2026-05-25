<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class CoachRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(): array
    {
        $sql = 'SELECT c.*, u.email, u.first_name, u.last_name, u.phone, u.is_active
                FROM coaches c
                INNER JOIN users u ON u.id = c.user_id
                ORDER BY c.id ASC';
        return $this->pdo->query($sql)->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT c.*, u.email, u.first_name, u.last_name, u.phone, u.is_active
             FROM coaches c INNER JOIN users u ON u.id = c.user_id WHERE c.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        if ($this->findById($id) === null) {
            return null;
        }

        $fields = ['title', 'bio', 'rating'];
        $sets = [];
        $params = ['id' => $id];
        foreach ($fields as $f) {
            if (array_key_exists($f, $data)) {
                $sets[] = "{$f} = :{$f}";
                $params[$f] = $data[$f];
            }
        }
        if ($sets !== []) {
            $this->pdo->prepare('UPDATE coaches SET ' . implode(', ', $sets) . ' WHERE id = :id')->execute($params);
        }

        return $this->findById($id);
    }

    public function delete(int $id): bool
    {
        $coach = $this->findById($id);
        if ($coach === null) {
            return false;
        }
        $this->pdo->prepare('DELETE FROM users WHERE id = :id')->execute(['id' => $coach['user_id']]);

        return true;
    }
}
