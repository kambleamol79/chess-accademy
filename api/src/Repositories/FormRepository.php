<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class FormRepository
{
    private const COLUMNS = [
        'highlight',
        'batch',
        'module',
        'time',
        'days_summary',
        'day_1',
        'coach_1',
        'day_2',
        'coach_2',
        'notes',
    ];

    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string, mixed>> */
    public function findAll(): array
    {
        $stmt = $this->pdo->query(
            'SELECT id, highlight, batch, module, `time`, days_summary, day_1, coach_1, day_2, coach_2, notes,
                    zoom_meeting_id, zoom_join_url, zoom_start_url, zoom_password, created_at, updated_at
             FROM forms
             ORDER BY id ASC'
        );

        return $stmt->fetchAll();
    }

    /** @return array<string, mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT id, highlight, batch, module, `time`, days_summary, day_1, coach_1, day_2, coach_2, notes,
                    zoom_meeting_id, zoom_join_url, zoom_start_url, zoom_password, created_at, updated_at
             FROM forms WHERE id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string, mixed> $data */
    public function create(array $data): array
    {
        $sql = 'INSERT INTO forms (highlight, batch, module, `time`, days_summary, day_1, coach_1, day_2, coach_2, notes)
                VALUES (:highlight, :batch, :module, :time, :days_summary, :day_1, :coach_1, :day_2, :coach_2, :notes)';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($this->bindParams($data));
        $id = (int) $this->pdo->lastInsertId();

        return $this->findById($id) ?? [];
    }

    /** @param array<string, mixed> $data */
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
            $sets[] = $col === 'time' ? '`time` = :time' : "{$col} = :{$col}";
            $params[$col] = $data[$col];
        }

        if ($sets === []) {
            return $this->findById($id);
        }

        $sql = 'UPDATE forms SET ' . implode(', ', $sets) . ' WHERE id = :id';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $this->findById($id);
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM forms WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }

    /** @param array{zoom_meeting_id: string, zoom_join_url: ?string, zoom_start_url: ?string, zoom_password: ?string} $zoom */
    public function updateZoom(int $id, array $zoom): ?array
    {
        if ($this->findById($id) === null) {
            return null;
        }

        $stmt = $this->pdo->prepare(
            'UPDATE forms
             SET zoom_meeting_id = :zoom_meeting_id,
                 zoom_join_url = :zoom_join_url,
                 zoom_start_url = :zoom_start_url,
                 zoom_password = :zoom_password
             WHERE id = :id'
        );
        $stmt->execute([
            'id' => $id,
            'zoom_meeting_id' => $zoom['zoom_meeting_id'],
            'zoom_join_url' => $zoom['zoom_join_url'],
            'zoom_start_url' => $zoom['zoom_start_url'],
            'zoom_password' => $zoom['zoom_password'],
        ]);

        return $this->findById($id);
    }

    public function clearZoom(int $id): ?array
    {
        return $this->updateZoom($id, [
            'zoom_meeting_id' => '',
            'zoom_join_url' => null,
            'zoom_start_url' => null,
            'zoom_password' => null,
        ]);
    }

    public function nextBatchCode(): string
    {
        $stmt = $this->pdo->query('SELECT batch FROM forms ORDER BY id ASC');
        $batches = $stmt->fetchAll(\PDO::FETCH_COLUMN);

        $maxNum = 0;
        $prefix = 'IB - ';

        foreach ($batches as $batch) {
            $batch = trim((string) $batch);
            if (!preg_match('/^(.+?)\s*-\s*(\d+)$/u', $batch, $m)) {
                continue;
            }
            $num = (int) $m[2];
            if ($num >= $maxNum) {
                $maxNum = $num;
                $prefix = trim($m[1]) . ' - ';
            }
        }

        return $prefix . ($maxNum + 1);
    }

    /** @param array<string, mixed> $data */
    private function bindParams(array $data): array
    {
        return [
            'highlight' => $data['highlight'] ?? 'beige',
            'batch' => $data['batch'] ?? '',
            'module' => $data['module'] ?? null,
            'time' => $data['time'] ?? '',
            'days_summary' => $data['days_summary'] ?? '',
            'day_1' => $data['day_1'] ?? '',
            'coach_1' => $data['coach_1'] ?? null,
            'day_2' => $data['day_2'] ?? '',
            'coach_2' => $data['coach_2'] ?? null,
            'notes' => $data['notes'] ?? null,
        ];
    }
}
