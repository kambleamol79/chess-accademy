<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class BatchMessageRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findByForm(int $formId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT m.*,
                    u.first_name AS sender_first_name,
                    u.last_name AS sender_last_name,
                    u.role AS sender_role
             FROM batch_messages m
             INNER JOIN users u ON u.id = m.sender_user_id
             WHERE m.form_id = :form_id
             ORDER BY m.created_at ASC, m.id ASC'
        );
        $stmt->execute(['form_id' => $formId]);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed> */
    public function create(int $formId, int $senderUserId, string $body): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO batch_messages (form_id, sender_user_id, body)
             VALUES (:form_id, :sender_user_id, :body)'
        );
        $stmt->execute([
            'form_id' => $formId,
            'sender_user_id' => $senderUserId,
            'body' => $body,
        ]);
        $id = (int) $this->pdo->lastInsertId();

        $stmt = $this->pdo->prepare(
            'SELECT m.*,
                    u.first_name AS sender_first_name,
                    u.last_name AS sender_last_name,
                    u.role AS sender_role
             FROM batch_messages m
             INNER JOIN users u ON u.id = m.sender_user_id
             WHERE m.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? [] : $row;
    }
}
