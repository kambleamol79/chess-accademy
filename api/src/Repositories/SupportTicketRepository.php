<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class SupportTicketRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(?string $status = null): array
    {
        $sql = 'SELECT t.*,
                       s.user_id AS student_user_id,
                       su.first_name AS student_first_name,
                       su.last_name AS student_last_name,
                       su.email AS student_email,
                       au.first_name AS assignee_first_name,
                       au.last_name AS assignee_last_name
                FROM support_tickets t
                INNER JOIN students s ON s.id = t.student_id
                INNER JOIN users su ON su.id = s.user_id
                LEFT JOIN users au ON au.id = t.assigned_to_user_id
                WHERE 1=1';
        $params = [];
        if ($status !== null && $status !== '') {
            $sql .= ' AND t.status = :status';
            $params['status'] = $status;
        }
        $sql .= ' ORDER BY t.updated_at DESC, t.id DESC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @return list<array<string,mixed>> */
    public function findByStudent(int $studentId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT t.*,
                    au.first_name AS assignee_first_name,
                    au.last_name AS assignee_last_name
             FROM support_tickets t
             LEFT JOIN users au ON au.id = t.assigned_to_user_id
             WHERE t.student_id = :student_id
             ORDER BY t.updated_at DESC, t.id DESC'
        );
        $stmt->execute(['student_id' => $studentId]);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT t.*,
                    s.user_id AS student_user_id,
                    su.first_name AS student_first_name,
                    su.last_name AS student_last_name,
                    su.email AS student_email,
                    au.first_name AS assignee_first_name,
                    au.last_name AS assignee_last_name
             FROM support_tickets t
             INNER JOIN students s ON s.id = t.student_id
             INNER JOIN users su ON su.id = s.user_id
             LEFT JOIN users au ON au.id = t.assigned_to_user_id
             WHERE t.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO support_tickets (student_id, subject, status)
             VALUES (:student_id, :subject, :status)'
        );
        $stmt->execute([
            'student_id' => $data['student_id'],
            'subject' => $data['subject'],
            'status' => $data['status'] ?? 'open',
        ]);
        $id = (int) $this->pdo->lastInsertId();

        return $this->findById($id) ?? [];
    }

    /** @param array<string,mixed> $data */
    public function update(int $id, array $data): ?array
    {
        $fields = [];
        $params = ['id' => $id];
        foreach (['status', 'assigned_to_user_id', 'resolution_comment'] as $key) {
            if (array_key_exists($key, $data)) {
                $fields[] = "{$key} = :{$key}";
                $params[$key] = $data[$key];
            }
        }
        if ($fields === []) {
            return $this->findById($id);
        }
        $sql = 'UPDATE support_tickets SET ' . implode(', ', $fields) . ' WHERE id = :id';
        $this->pdo->prepare($sql)->execute($params);

        return $this->findById($id);
    }

    public function touch(int $id): void
    {
        $this->pdo->prepare('UPDATE support_tickets SET updated_at = CURRENT_TIMESTAMP WHERE id = :id')
            ->execute(['id' => $id]);
    }

    /** @return list<array<string,mixed>> */
    public function messagesForTicket(int $ticketId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT m.*,
                    u.first_name AS sender_first_name,
                    u.last_name AS sender_last_name,
                    u.role AS sender_role
             FROM support_ticket_messages m
             INNER JOIN users u ON u.id = m.sender_user_id
             WHERE m.ticket_id = :ticket_id
             ORDER BY m.created_at ASC, m.id ASC'
        );
        $stmt->execute(['ticket_id' => $ticketId]);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed> */
    public function addMessage(int $ticketId, int $senderUserId, string $body): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO support_ticket_messages (ticket_id, sender_user_id, body)
             VALUES (:ticket_id, :sender_user_id, :body)'
        );
        $stmt->execute([
            'ticket_id' => $ticketId,
            'sender_user_id' => $senderUserId,
            'body' => $body,
        ]);
        $this->touch($ticketId);
        $id = (int) $this->pdo->lastInsertId();

        $stmt = $this->pdo->prepare(
            'SELECT m.*,
                    u.first_name AS sender_first_name,
                    u.last_name AS sender_last_name,
                    u.role AS sender_role
             FROM support_ticket_messages m
             INNER JOIN users u ON u.id = m.sender_user_id
             WHERE m.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? [] : $row;
    }
}
