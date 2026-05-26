<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use ChessAcademy\Repositories\LeadRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Repositories\UserRepository;
use PDO;

final class LeadConversionService
{
    public function __construct(
        private readonly PDO $pdo,
        private readonly LeadRepository $leads,
        private readonly UserRepository $users,
        private readonly StudentRepository $students,
    ) {}

    /**
     * @param array<string,mixed> $leadData Fields to persist on the lead before conversion
     * @return array{student: array<string,mixed>, temporary_password: string}
     */
    public function convert(int $leadId, array $leadData, string $receiptStoredName): array
    {
        $lead = $this->leads->findById($leadId);
        if ($lead === null) {
            throw new \InvalidArgumentException('Lead not found');
        }

        $updated = $this->leads->update($leadId, $leadData);
        if ($updated === null) {
            throw new \InvalidArgumentException('Lead not found');
        }

        $email = trim((string) ($updated['email'] ?? ''));
        if ($email === '') {
            $email = sprintf('lead.%d@students.local', $leadId);
        }

        if ($this->users->findByEmail($email) !== null) {
            throw new \InvalidArgumentException(
                'A user with this email already exists. Change the lead email before marking as paid.'
            );
        }

        $names = $this->splitChildName((string) ($updated['child_name'] ?? 'Student'));
        $password = bin2hex(random_bytes(8));

        $this->pdo->beginTransaction();
        try {
            $userId = $this->users->create([
                'email' => $email,
                'password_hash' => password_hash($password, PASSWORD_BCRYPT),
                'role' => 'student',
                'first_name' => $names['first_name'],
                'last_name' => $names['last_name'],
                'phone' => $updated['phone'] ?? null,
            ]);

            $this->users->createStudentProfile($userId, [
                'parent_name' => $updated['parents_name'] ?? null,
                'parent_phone' => $updated['phone'] ?? null,
                'date_of_birth' => null,
                'chess_rating' => 0,
            ]);

            $profile = $this->students->findByUserId($userId);
            if ($profile === null) {
                throw new \RuntimeException('Student profile was not created');
            }

            $student = $this->students->update((int) $profile['id'], [
                'city' => $updated['city'] ?? null,
                'level' => $updated['module'] ?? null,
                'payment_date' => date('Y-m-d'),
                'payment_received' => 'PAID',
                'w_app' => $updated['phone'] ?? null,
                'payment_receipt_path' => $receiptStoredName,
                'source_lead_id' => $leadId,
            ]);

            if ($student === null) {
                throw new \RuntimeException('Could not update student roster');
            }

            if (!$this->leads->delete($leadId)) {
                throw new \RuntimeException('Could not remove lead after conversion');
            }

            $this->pdo->commit();

            return [
                'student' => $student,
                'temporary_password' => $password,
            ];
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    /** @return array{first_name: string, last_name: string} */
    private function splitChildName(string $name): array
    {
        $trimmed = trim($name);
        if ($trimmed === '') {
            return ['first_name' => 'Student', 'last_name' => '—'];
        }

        $parts = preg_split('/\s+/', $trimmed, 2) ?: [];

        return [
            'first_name' => $parts[0] ?? 'Student',
            'last_name' => $parts[1] ?? '—',
        ];
    }
}
