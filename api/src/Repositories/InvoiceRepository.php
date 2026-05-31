<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class InvoiceRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(?string $status = null): array
    {
        $sql = 'SELECT i.*, u.first_name, u.last_name, u.email
                FROM invoices i
                INNER JOIN students s ON s.id = i.student_id
                INNER JOIN users u ON u.id = s.user_id
                WHERE 1=1';
        $params = [];
        if ($status !== null) {
            $sql .= ' AND i.status = :status';
            $params['status'] = $status;
        }
        $sql .= ' ORDER BY i.id DESC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @return list<array<string,mixed>> */
    public function findByStudentId(int $studentId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM invoices WHERE student_id = :student_id ORDER BY id DESC'
        );
        $stmt->execute(['student_id' => $studentId]);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM invoices WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO invoices (student_id, amount, description, due_date, status)
             VALUES (:student_id, :amount, :description, :due_date, :status)'
        );
        $stmt->execute([
            'student_id' => $data['student_id'],
            'amount' => $data['amount'],
            'description' => $data['description'] ?? null,
            'due_date' => $data['due_date'] ?? null,
            'status' => $data['status'] ?? 'pending',
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    public function markPaid(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            "UPDATE invoices SET status = 'paid', paid_at = NOW() WHERE id = :id"
        );
        $stmt->execute(['id' => $id]);

        return $this->findById($id);
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        if ($this->findById($id) === null) {
            return null;
        }
        $fields = ['amount', 'description', 'due_date', 'status'];
        $sets = [];
        $params = ['id' => $id];
        foreach ($fields as $f) {
            if (array_key_exists($f, $data)) {
                $sets[] = "{$f} = :{$f}";
                $params[$f] = $data[$f];
            }
        }
        if ($sets !== []) {
            $this->pdo->prepare('UPDATE invoices SET ' . implode(', ', $sets) . ' WHERE id = :id')->execute($params);
        }

        return $this->findById($id);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM invoices WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }
}
