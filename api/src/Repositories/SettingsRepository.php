<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class SettingsRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return array<string,mixed> */
    public function all(): array
    {
        $rows = $this->pdo->query('SELECT `key`, `value` FROM settings')->fetchAll();
        $out = [];
        foreach ($rows as $row) {
            $out[$row['key']] = json_decode((string) $row['value'], true);
        }

        return $out;
    }

    public function get(string $key, mixed $default = null): mixed
    {
        $stmt = $this->pdo->prepare('SELECT `value` FROM settings WHERE `key` = :key LIMIT 1');
        $stmt->execute(['key' => $key]);
        $row = $stmt->fetch();
        if ($row === false) {
            return $default;
        }

        return json_decode((string) $row['value'], true);
    }

    public function set(string $key, mixed $value): void
    {
        $json = json_encode($value, JSON_THROW_ON_ERROR);
        $stmt = $this->pdo->prepare(
            'INSERT INTO settings (`key`, `value`) VALUES (:key, :value)
             ON DUPLICATE KEY UPDATE `value` = :value2'
        );
        $stmt->execute(['key' => $key, 'value' => $json, 'value2' => $json]);
    }
}
