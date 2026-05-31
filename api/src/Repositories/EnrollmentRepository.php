<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class EnrollmentRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(?int $formId = null, ?int $studentId = null): array
    {
        $sql = 'SELECT e.*, f.batch, s.user_id, u.first_name, u.last_name
                FROM form_enrollments e
                INNER JOIN forms f ON f.id = e.form_id
                INNER JOIN students s ON s.id = e.student_id
                INNER JOIN users u ON u.id = s.user_id
                WHERE 1=1';
        $params = [];
        if ($formId !== null) {
            $sql .= ' AND e.form_id = :form_id';
            $params['form_id'] = $formId;
        }
        if ($studentId !== null) {
            $sql .= ' AND e.student_id = :student_id';
            $params['student_id'] = $studentId;
        }
        $sql .= ' ORDER BY e.id ASC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO form_enrollments (form_id, student_id, enrolled_at, status)
             VALUES (:form_id, :student_id, :enrolled_at, :status)'
        );
        $stmt->execute([
            'form_id' => $data['form_id'],
            'student_id' => $data['student_id'],
            'enrolled_at' => $data['enrolled_at'] ?? date('Y-m-d'),
            'status' => $data['status'] ?? 'active',
        ]);
        $id = (int) $this->pdo->lastInsertId();

        return $this->findById($id) ?? [];
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT e.*, f.batch FROM form_enrollments e INNER JOIN forms f ON f.id = e.form_id WHERE e.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM form_enrollments WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }

    /** @return array<string,mixed>|null */
    public function findActiveByStudent(int $studentId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT e.*, f.batch, f.days_summary, f.time, f.module
             FROM form_enrollments e
             INNER JOIN forms f ON f.id = e.form_id
             WHERE e.student_id = :student_id AND e.status = \'active\'
             LIMIT 1'
        );
        $stmt->execute(['student_id' => $studentId]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @return array<string,mixed>|null */
    public function findActiveWithFormByStudent(int $studentId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT e.id AS enrollment_id, e.enrolled_at, e.status,
                    f.id AS form_id, f.highlight, f.batch, f.module, f.time, f.days_summary,
                    f.day_1, f.coach_1, f.day_2, f.coach_2, f.notes,
                    f.zoom_meeting_id, f.zoom_join_url
             FROM form_enrollments e
             INNER JOIN forms f ON f.id = e.form_id
             WHERE e.student_id = :student_id AND e.status = \'active\'
             LIMIT 1'
        );
        $stmt->execute(['student_id' => $studentId]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /**
     * @param list<int> $studentIds
     * @return array{created: int, skipped: list<array{student_id: int, reason: string}>}
     */
    public function assignBatch(int $formId, array $studentIds): array
    {
        $created = 0;
        $skipped = [];

        foreach ($studentIds as $studentId) {
            $studentId = (int) $studentId;
            if ($studentId <= 0) {
                continue;
            }

            $existing = $this->findActiveByStudent($studentId);
            if ($existing !== null) {
                if ((int) $existing['form_id'] === $formId) {
                    $skipped[] = [
                        'student_id' => $studentId,
                        'reason' => 'Already assigned to this batch',
                    ];
                } else {
                    $skipped[] = [
                        'student_id' => $studentId,
                        'reason' => 'Already in batch ' . ($existing['batch'] ?? ''),
                    ];
                }
                continue;
            }

            try {
                $this->create([
                    'form_id' => $formId,
                    'student_id' => $studentId,
                    'enrolled_at' => date('Y-m-d'),
                    'status' => 'active',
                ]);
                $created++;
            } catch (\PDOException) {
                $skipped[] = [
                    'student_id' => $studentId,
                    'reason' => 'Could not enroll student',
                ];
            }
        }

        return ['created' => $created, 'skipped' => $skipped];
    }
}
