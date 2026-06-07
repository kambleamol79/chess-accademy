<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class BroadcastMessageRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(int $limit = 100): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT b.*,
                    u.first_name AS sender_first_name,
                    u.last_name AS sender_last_name
             FROM broadcast_messages b
             INNER JOIN users u ON u.id = b.sender_user_id
             ORDER BY b.created_at DESC, b.id DESC
             LIMIT :limit'
        );
        $stmt->bindValue('limit', max(1, min($limit, 200)), PDO::PARAM_INT);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    /** @return list<array<string,mixed>> */
    public function findRecent(int $limit = 50): array
    {
        return $this->findAll($limit);
    }

    /** @return array<string,mixed> */
    public function create(int $senderUserId, string $title, string $body, bool $pushSent, ?string $pushDetail): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO broadcast_messages (sender_user_id, title, body, push_sent, push_detail)
             VALUES (:sender_user_id, :title, :body, :push_sent, :push_detail)'
        );
        $stmt->execute([
            'sender_user_id' => $senderUserId,
            'title' => $title,
            'body' => $body,
            'push_sent' => $pushSent ? 1 : 0,
            'push_detail' => $pushDetail,
        ]);
        $id = (int) $this->pdo->lastInsertId();

        $stmt = $this->pdo->prepare(
            'SELECT b.*,
                    u.first_name AS sender_first_name,
                    u.last_name AS sender_last_name
             FROM broadcast_messages b
             INNER JOIN users u ON u.id = b.sender_user_id
             WHERE b.id = :id'
        );
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? [] : $row;
    }
}
