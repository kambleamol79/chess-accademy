<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class DeviceTokenRepository
{
    public function __construct(private readonly PDO $pdo) {}

    public function upsert(int $userId, string $token, string $platform): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO student_device_tokens (user_id, token, platform)
             VALUES (:user_id, :token, :platform)
             ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), platform = VALUES(platform), updated_at = CURRENT_TIMESTAMP'
        );
        $stmt->execute([
            'user_id' => $userId,
            'token' => $token,
            'platform' => $platform,
        ]);
    }

    public function deleteToken(string $token): void
    {
        $stmt = $this->pdo->prepare('DELETE FROM student_device_tokens WHERE token = :token');
        $stmt->execute(['token' => $token]);
    }

    /** @return list<string> */
    public function allTokens(): array
    {
        $stmt = $this->pdo->query('SELECT token FROM student_device_tokens ORDER BY updated_at DESC');
        $rows = $stmt->fetchAll();

        return array_values(array_unique(array_map(static fn (array $row): string => (string) $row['token'], $rows)));
    }
}
