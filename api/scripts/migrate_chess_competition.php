<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(dirname(__DIR__));
$dotenv->safeLoad();

$host = $_ENV['DB_HOST'] ?? '127.0.0.1';
$db = $_ENV['DB_NAME'] ?? 'chess_academy';
$user = $_ENV['DB_USER'] ?? 'root';
$pass = $_ENV['DB_PASS'] ?? '';

$pdo = new PDO("mysql:host={$host};dbname={$db};charset=utf8mb4", $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

$sql = file_get_contents(dirname(__DIR__) . '/database/chess_competition_migration.sql');
$statements = preg_split('/;\s*\n/', $sql) ?: [];

foreach ($statements as $stmt) {
    $stmt = trim($stmt);
    if ($stmt === '' || str_starts_with($stmt, '--')) {
        continue;
    }
    if (preg_match('/^USE `/i', $stmt)) {
        continue;
    }
    $pdo->exec($stmt);
}

echo "Chess competition migration complete.\n";
