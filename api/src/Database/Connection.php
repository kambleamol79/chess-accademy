<?php

declare(strict_types=1);

namespace ChessAcademy\Database;

use PDO;
use PDOException;

final class Connection
{
    private static ?PDO $pdo = null;

    /** @param array<string, mixed> $settings */
    public static function get(array $settings): PDO
    {
        if (self::$pdo instanceof PDO) {
            try {
                self::$pdo->query('SELECT 1');

                return self::$pdo;
            } catch (PDOException) {
                self::$pdo = null;
            }
        }

        self::$pdo = self::connect($settings);

        return self::$pdo;
    }

    /** @param array<string, mixed> $settings */
    private static function connect(array $settings): PDO
    {
        $host = $settings['db']['host'];
        $port = $settings['db']['port'];
        $name = $settings['db']['name'];
        $user = $settings['db']['user'];
        $pass = $settings['db']['pass'];

        $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $name);

        try {
            return new PDO($dsn, $user, $pass, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                // MySQL native prepares require each named placeholder to appear once; emulated allows :sid reuse.
                PDO::ATTR_EMULATE_PREPARES => true,
            ]);
        } catch (PDOException $e) {
            throw new PDOException('Database connection failed: ' . $e->getMessage(), (int) $e->getCode(), $e);
        }
    }
}
