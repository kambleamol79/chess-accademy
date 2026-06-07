<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Repositories\EnrollmentRepository;
use ChessAcademy\Repositories\FormRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Repositories\SupportTicketRepository;

final class MessagingService
{
    public function __construct(
        private readonly SupportTicketRepository $tickets,
        private readonly EnrollmentRepository $enrollments,
        private readonly CoachRepository $coaches,
        private readonly FormRepository $forms,
        private readonly StudentRepository $students,
    ) {}

    /** @param array<string,mixed> $authUser */
    public function canAccessTicket(array $authUser, int $ticketId): bool
    {
        $ticket = $this->tickets->findById($ticketId);
        if ($ticket === null) {
            return false;
        }

        $role = (string) ($authUser['role'] ?? '');
        if ($role === 'admin') {
            return true;
        }

        if ($role === 'student') {
            $student = $this->students->findByUserId((int) $authUser['id']);
            if ($student === null) {
                return false;
            }

            return (int) $ticket['student_id'] === (int) $student['id'];
        }

        return false;
    }

    /** @param array<string,mixed> $authUser */
    public function canAccessBatchMessages(array $authUser, int $formId): bool
    {
        if ($this->forms->findById($formId) === null) {
            return false;
        }

        $role = (string) ($authUser['role'] ?? '');
        if ($role === 'admin') {
            return true;
        }

        if ($role === 'coach') {
            $coach = $this->coaches->findByUserId((int) $authUser['id']);
            if ($coach === null) {
                return false;
            }

            return $this->coaches->isAssignedToForm((int) $coach['id'], $formId);
        }

        if ($role === 'student') {
            $student = $this->students->findByUserId((int) $authUser['id']);
            if ($student === null) {
                return false;
            }

            return $this->enrollments->hasActiveEnrollment((int) $student['id'], $formId);
        }

        return false;
    }

    /** @param array<string,mixed> $authUser */
    public function canSendBatchMessage(array $authUser, int $formId): bool
    {
        $role = (string) ($authUser['role'] ?? '');

        return $role === 'admin' && $this->canAccessBatchMessages($authUser, $formId);
    }
}
