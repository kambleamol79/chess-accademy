<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class DashboardRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return array<string,mixed> */
    public function metrics(): array
    {
        $students = (int) $this->pdo->query('SELECT COUNT(*) FROM students')->fetchColumn();
        $coaches = (int) $this->pdo->query('SELECT COUNT(*) FROM coaches')->fetchColumn();
        $batches = (int) $this->pdo->query('SELECT COUNT(*) FROM forms')->fetchColumn();
        $activeEnrollments = (int) $this->pdo->query(
            "SELECT COUNT(*) FROM form_enrollments WHERE status = 'active'"
        )->fetchColumn();

        $revenue = $this->pdo->query(
            "SELECT COALESCE(SUM(amount), 0) FROM invoices
             WHERE status = 'paid' AND MONTH(paid_at) = MONTH(CURRENT_DATE())
             AND YEAR(paid_at) = YEAR(CURRENT_DATE())"
        )->fetchColumn();

        $pendingInvoices = (int) $this->pdo->query(
            "SELECT COUNT(*) FROM invoices WHERE status IN ('pending','overdue')"
        )->fetchColumn();

        $puzzlesWeek = (int) $this->pdo->query(
            'SELECT COUNT(*) FROM puzzle_attempts WHERE attempted_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)'
        )->fetchColumn();

        $upcoming = $this->pdo->query(
            'SELECT batch AS batch_name, `time` AS time_slot, days_summary, coach_1, coach_2
             FROM forms ORDER BY id ASC LIMIT 5'
        )->fetchAll();

        $enrollmentByBatch = $this->pdo->query(
            'SELECT f.batch, COUNT(e.id) AS enrolled
             FROM forms f
             LEFT JOIN form_enrollments e ON e.form_id = f.id AND e.status = \'active\'
             GROUP BY f.id, f.batch
             ORDER BY f.id ASC'
        )->fetchAll();

        return [
            'total_students' => $students,
            'coaches_count' => $coaches,
            'active_batches' => $batches,
            'active_enrollments' => $activeEnrollments,
            'revenue_this_month' => (float) $revenue,
            'pending_invoices' => $pendingInvoices,
            'puzzles_solved_week' => $puzzlesWeek,
            'upcoming_batches' => $upcoming,
            'enrollment_by_batch' => $enrollmentByBatch,
        ];
    }
}
