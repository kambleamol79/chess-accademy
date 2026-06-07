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

    /** @return array<string,mixed>|null */
    public function findByUserId(int $userId): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT c.*, u.email, u.first_name, u.last_name, u.phone, u.is_active
             FROM coaches c INNER JOIN users u ON u.id = c.user_id WHERE c.user_id = :user_id LIMIT 1'
        );
        $stmt->execute(['user_id' => $userId]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        $coach = $this->findById($id);
        if ($coach === null) {
            return null;
        }

        $userFields = ['first_name', 'last_name', 'email', 'phone'];
        $userSets = [];
        $userParams = ['id' => $coach['user_id']];
        foreach ($userFields as $f) {
            if (array_key_exists($f, $data)) {
                $userSets[] = "{$f} = :{$f}";
                $userParams[$f] = $data[$f];
            }
        }
        if ($userSets !== []) {
            $this->pdo->prepare('UPDATE users SET ' . implode(', ', $userSets) . ' WHERE id = :id')->execute($userParams);
        }

        if (array_key_exists('password', $data)) {
            $pwd = is_string($data['password']) ? trim($data['password']) : '';
            if ($pwd !== '') {
                $this->pdo->prepare('UPDATE users SET password_hash = :password_hash WHERE id = :id')
                    ->execute([
                        'password_hash' => password_hash($pwd, PASSWORD_BCRYPT),
                        'id' => (int) $coach['user_id'],
                    ]);
            }
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

    /**
     * Full batch (form) rows where coach_1 or coach_2 matches this coach.
     *
     * @return list<array<string, mixed>>
     */
    public function findAssignedForms(int $id): array
    {
        $coach = $this->findById($id);
        if ($coach === null) {
            return [];
        }

        $forms = $this->pdo->query(
            'SELECT id, highlight, batch, module, `time`, days_summary, day_1, coach_1, day_2, coach_2, notes,
                    zoom_join_url, zoom_username, zoom_password, created_at, updated_at
             FROM forms
             ORDER BY `time` ASC, id ASC'
        )->fetchAll();

        $assigned = [];
        foreach ($forms as $form) {
            if ($this->formAssignedToCoach($form, $coach)) {
                $assigned[] = $form;
            }
        }

        return $assigned;
    }

    public function isAssignedToForm(int $coachId, int $formId): bool
    {
        $coach = $this->findById($coachId);
        if ($coach === null) {
            return false;
        }

        $stmt = $this->pdo->prepare(
            'SELECT coach_1, coach_2 FROM forms WHERE id = :id LIMIT 1'
        );
        $stmt->execute(['id' => $formId]);
        $form = $stmt->fetch();

        return $form !== false && $this->formAssignedToCoach($form, $coach);
    }

    /**
     * Schedule cells where coach_1 or coach_2 matches this coach (flexible name match).
     *
     * @return list<array<string, mixed>>
     */
    public function findAssignedBatches(int $id): array
    {
        $coach = $this->findById($id);
        if ($coach === null) {
            return [];
        }

        $assignments = [];
        foreach ($this->findAssignedForms($id) as $form) {
            if ($this->coachNameMatches((string) ($form['coach_1'] ?? ''), $coach)) {
                $assignments[] = $this->assignmentRow($form, 'day_1', 'coach_1');
            }
            if ($this->coachNameMatches((string) ($form['coach_2'] ?? ''), $coach)) {
                $assignments[] = $this->assignmentRow($form, 'day_2', 'coach_2');
            }
        }

        return $assignments;
    }

    /**
     * @param array<string, mixed> $form
     * @param array<string, mixed> $coach
     */
    private function formAssignedToCoach(array $form, array $coach): bool
    {
        return $this->coachNameMatches((string) ($form['coach_1'] ?? ''), $coach)
            || $this->coachNameMatches((string) ($form['coach_2'] ?? ''), $coach);
    }

    /** @param array<string, mixed> $form */
    private function assignmentRow(array $form, string $dayField, string $coachField): array
    {
        $notes = trim((string) ($form['notes'] ?? ''));
        $isPractice = $notes !== '' && stripos($notes, 'practice') !== false;
        $label = $isPractice ? $notes : (string) $form['batch'];

        return [
            'form_id' => (int) $form['id'],
            'batch' => $form['batch'],
            'module' => $form['module'],
            'time' => $form['time'],
            'day' => $this->normalizeDay((string) $form[$dayField]),
            'highlight' => $form['highlight'],
            'label' => $label,
            'is_practice' => $isPractice,
            'slot' => $coachField,
            'days_summary' => $form['days_summary'],
        ];
    }

    /** @param array<string, mixed> $coach */
    private function coachNameMatches(string $stored, array $coach): bool
    {
        $stored = $this->normalizeCoachKey($stored);
        if ($stored === '') {
            return false;
        }

        $first = (string) $coach['first_name'];
        $last = (string) $coach['last_name'];
        $full = $this->normalizeCoachKey(trim("{$first} {$last}"));
        $firstKey = $this->normalizeCoachKey($first);

        return $stored === $full
            || $stored === $firstKey
            || ($full !== '' && str_starts_with($full, $stored))
            || ($firstKey !== '' && str_starts_with($firstKey, $stored))
            || str_starts_with($stored, $firstKey);
    }

    private function normalizeCoachKey(string $name): string
    {
        return strtoupper(preg_replace('/\s+/', '', trim($name)) ?? '');
    }

    private function normalizeDay(string $day): string
    {
        $day = strtoupper(trim($day));
        if ($day === 'THU' || $day === 'THURS' || $day === 'THURSDAY') {
            return 'THUR';
        }
        if ($day === 'TUESDAY') {
            return 'TUE';
        }
        if ($day === 'MONDAY') {
            return 'MON';
        }
        if ($day === 'WEDNESDAY') {
            return 'WED';
        }
        if ($day === 'FRIDAY') {
            return 'FRI';
        }
        if ($day === 'SATURDAY') {
            return 'SAT';
        }

        return $day;
    }
}
