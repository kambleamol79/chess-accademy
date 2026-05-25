<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class LeadRepository
{
    private const COLUMNS = [
        'captured_at',
        'child_name',
        'parents_name',
        'phone',
        'email',
        'age',
        'std',
        'city',
        'q1',
        'q2',
        'q3',
        'time_slot',
        'attd_no',
        'module',
        'status_int',
        'not_interested',
        'paid',
        'dnp',
        'additional',
        'review',
        'updated_by',
    ];

    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(): array
    {
        $sql = 'SELECT l.*, u.first_name AS updater_first, u.last_name AS updater_last
                FROM leads l
                LEFT JOIN users u ON u.id = l.updated_by
                ORDER BY l.captured_at DESC, l.id DESC';

        return $this->pdo->query($sql)->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM leads WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $sql = 'INSERT INTO leads (
            captured_at, child_name, parents_name, phone, email, age, std, city,
            q1, q2, q3, time_slot, attd_no, module, status_int, not_interested, paid, dnp,
            additional, review, updated_by
        ) VALUES (
            :captured_at, :child_name, :parents_name, :phone, :email, :age, :std, :city,
            :q1, :q2, :q3, :time_slot, :attd_no, :module, :status_int, :not_interested, :paid, :dnp,
            :additional, :review, :updated_by
        )';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($this->bindParams($data));

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    /**
     * @param list<array<string,mixed>> $rows
     * @return array{created: int, skipped: int, errors: list<array{row: int, message: string}>}
     */
    public function createMany(array $rows, ?int $updatedBy = null): array
    {
        $created = 0;
        $errors = [];

        foreach ($rows as $index => $data) {
            $rowNum = $index + 2;
            if (empty(trim((string) ($data['child_name'] ?? '')))) {
                $errors[] = ['row' => $rowNum, 'message' => 'Child name is required'];
                continue;
            }

            if ($updatedBy !== null) {
                $data['updated_by'] = $updatedBy;
            }

            try {
                $this->create($data);
                $created++;
            } catch (\Throwable) {
                $errors[] = ['row' => $rowNum, 'message' => 'Could not save row'];
            }
        }

        return [
            'created' => $created,
            'skipped' => count($errors),
            'errors' => $errors,
        ];
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        if ($this->findById($id) === null) {
            return null;
        }

        $sets = [];
        $params = ['id' => $id];

        foreach (self::COLUMNS as $col) {
            if (!array_key_exists($col, $data)) {
                continue;
            }
            $sets[] = "{$col} = :{$col}";
            $params[$col] = $data[$col];
        }

        if ($sets === []) {
            return $this->findById($id);
        }

        $this->pdo->prepare('UPDATE leads SET ' . implode(', ', $sets) . ' WHERE id = :id')->execute($params);

        return $this->findById($id);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM leads WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }

    /** @param array<string,mixed> $data */
    private function bindParams(array $data): array
    {
        return [
            'captured_at' => $data['captured_at'] ?? date('Y-m-d H:i:s'),
            'child_name' => $data['child_name'] ?? '',
            'parents_name' => $data['parents_name'] ?? null,
            'phone' => $data['phone'] ?? null,
            'email' => $data['email'] ?? null,
            'age' => $data['age'] ?? null,
            'std' => $data['std'] ?? null,
            'city' => $data['city'] ?? null,
            'q1' => $data['q1'] ?? null,
            'q2' => $data['q2'] ?? null,
            'q3' => $data['q3'] ?? null,
            'time_slot' => $data['time_slot'] ?? null,
            'attd_no' => $data['attd_no'] ?? null,
            'module' => $data['module'] ?? null,
            'status_int' => $data['status_int'] ?? null,
            'not_interested' => $data['not_interested'] ?? null,
            'paid' => $data['paid'] ?? null,
            'dnp' => $data['dnp'] ?? null,
            'additional' => $data['additional'] ?? null,
            'review' => $data['review'] ?? null,
            'updated_by' => $data['updated_by'] ?? null,
        ];
    }
}
