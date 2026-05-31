<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use ChessAcademy\Repositories\EnrollmentRepository;
use ChessAcademy\Repositories\InvoiceRepository;

final class StudentPortalService
{
    private const MONTH_FIELDS = [
        'jan' => 'month_jan',
        'feb' => 'month_feb',
        'mar' => 'month_mar',
        'apr' => 'month_apr',
        'may' => 'month_may',
        'jun' => 'month_jun',
        'jul' => 'month_jul',
        'aug' => 'month_aug',
        'sep' => 'month_sep',
    ];

    public function __construct(
        private readonly EnrollmentRepository $enrollments,
        private readonly InvoiceRepository $invoices,
    ) {}

    /** @return array<string,mixed>|null */
    public function activeBatch(int $studentId): ?array
    {
        return $this->enrollments->findActiveWithFormByStudent($studentId);
    }

    /** @return array<string,mixed> */
    public function paymentHistory(int $studentId, array $studentProfile): array
    {
        $invoices = $this->invoices->findByStudentId($studentId);
        $monthly = [];

        foreach (self::MONTH_FIELDS as $label => $field) {
            $value = trim((string) ($studentProfile[$field] ?? ''));
            if ($value !== '') {
                $monthly[] = [
                    'type' => 'monthly',
                    'period' => ucfirst($label),
                    'amount' => $value,
                    'status' => 'paid',
                ];
            }
        }

        $summary = [
            'total_pay' => $studentProfile['total_pay'] ?? null,
            'payment_received' => $studentProfile['payment_received'] ?? null,
            'payment_date' => $studentProfile['payment_date'] ?? null,
        ];

        return [
            'summary' => $summary,
            'invoices' => $invoices,
            'monthly' => $monthly,
        ];
    }

    /** @return list<array<string,mixed>> */
    public function reminders(int $studentId, array $studentProfile): array
    {
        $reminders = [];
        $batch = $this->enrollments->findActiveWithFormByStudent($studentId);

        if ($batch !== null) {
            $nextClass = $this->nextClassReminder($batch);
            if ($nextClass !== null) {
                $reminders[] = $nextClass;
            }
        }

        foreach ($this->invoices->findByStudentId($studentId) as $invoice) {
            if (($invoice['status'] ?? '') === 'pending' || ($invoice['status'] ?? '') === 'overdue') {
                $reminders[] = [
                    'id' => 'invoice-' . $invoice['id'],
                    'type' => 'payment',
                    'title' => 'Payment due',
                    'message' => sprintf(
                        'Invoice #%d of ₹%s is %s',
                        $invoice['id'],
                        $invoice['amount'],
                        $invoice['status']
                    ),
                    'due_at' => $invoice['due_date'] ?? null,
                    'priority' => ($invoice['status'] ?? '') === 'overdue' ? 'high' : 'medium',
                ];
            }
        }

        $reminders[] = [
            'id' => 'practice-daily',
            'type' => 'practice',
            'title' => 'Daily chess practice',
            'message' => 'Spend 15 minutes on the practice board today.',
            'due_at' => date('Y-m-d'),
            'priority' => 'low',
        ];

        if (($studentProfile['chess_rating'] ?? 0) === 0) {
            $reminders[] = [
                'id' => 'profile-rating',
                'type' => 'profile',
                'title' => 'Update your rating',
                'message' => 'Ask your coach to update your chess rating after your next class.',
                'due_at' => null,
                'priority' => 'low',
            ];
        }

        return $reminders;
    }

    /** @return list<array<string,mixed>> */
    public function notifications(int $studentId, array $studentProfile): array
    {
        $items = [];
        $batch = $this->enrollments->findActiveWithFormByStudent($studentId);

        if ($batch !== null) {
            $items[] = [
                'id' => 'batch-' . ($batch['form_id'] ?? $batch['id'] ?? 0),
                'type' => 'batch',
                'title' => 'Batch assigned',
                'message' => 'You are enrolled in batch ' . ($batch['batch'] ?? '') . '.',
                'created_at' => $batch['enrolled_at'] ?? null,
                'read' => false,
            ];
        }

        foreach ($this->invoices->findByStudentId($studentId) as $invoice) {
            $status = (string) ($invoice['status'] ?? '');
            if ($status === 'paid') {
                $items[] = [
                    'id' => 'paid-' . $invoice['id'],
                    'type' => 'payment',
                    'title' => 'Payment received',
                    'message' => sprintf('Your payment of ₹%s was recorded.', $invoice['amount']),
                    'created_at' => $invoice['paid_at'] ?? $invoice['created_at'] ?? null,
                    'read' => false,
                ];
            } elseif ($status === 'overdue') {
                $items[] = [
                    'id' => 'overdue-' . $invoice['id'],
                    'type' => 'alert',
                    'title' => 'Overdue payment',
                    'message' => sprintf('Invoice #%d is overdue. Please contact the academy.', $invoice['id']),
                    'created_at' => $invoice['due_date'] ?? $invoice['created_at'] ?? null,
                    'read' => false,
                ];
            }
        }

        if (!empty($studentProfile['payment_received'])) {
            $items[] = [
                'id' => 'welcome',
                'type' => 'info',
                'title' => 'Welcome to Brainstorm Chess Academy',
                'message' => 'Learn and play chess — check your batch schedule and practice daily.',
                'created_at' => $studentProfile['created_at'] ?? null,
                'read' => true,
            ];
        }

        usort($items, static function (array $a, array $b): int {
            return strcmp((string) ($b['created_at'] ?? ''), (string) ($a['created_at'] ?? ''));
        });

        return $items;
    }

    /** @param array<string,mixed> $batch */
    private function nextClassReminder(array $batch): ?array
    {
        $days = array_filter([$batch['day_1'] ?? null, $batch['day_2'] ?? null]);
        if ($days === []) {
            return null;
        }

        $dayMap = [
            'MON' => 1, 'TUE' => 2, 'WED' => 3, 'THUR' => 4, 'THU' => 4,
            'FRI' => 5, 'SAT' => 6, 'SUN' => 0,
        ];

        $today = (int) date('w');
        $nextDay = null;
        $nextOffset = 8;

        foreach ($days as $day) {
            $target = $dayMap[strtoupper(trim((string) $day))] ?? null;
            if ($target === null) {
                continue;
            }
            $offset = ($target - $today + 7) % 7;
            if ($offset === 0) {
                $offset = 0;
            }
            if ($offset < $nextOffset) {
                $nextOffset = $offset;
                $nextDay = strtoupper(trim((string) $day));
            }
        }

        if ($nextDay === null) {
            return null;
        }

        $date = date('Y-m-d', strtotime("+{$nextOffset} days"));

        return [
            'id' => 'class-' . ($batch['form_id'] ?? 0) . '-' . $date,
            'type' => 'class',
            'title' => 'Upcoming class',
            'message' => sprintf(
                'Batch %s on %s at %s with %s.',
                $batch['batch'] ?? '',
                $nextDay,
                $batch['time'] ?? '',
                trim(($batch['coach_1'] ?? '') . ' / ' . ($batch['coach_2'] ?? ''), ' /')
            ),
            'due_at' => $date,
            'priority' => $nextOffset <= 1 ? 'high' : 'medium',
        ];
    }
}
