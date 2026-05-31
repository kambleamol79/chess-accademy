<?php

declare(strict_types=1);

require dirname(__DIR__) . '/vendor/autoload.php';

use ChessAcademy\Database\Connection;

$settings = require dirname(__DIR__) . '/config/settings.php';
$pdo = Connection::get($settings);

$sql = file_get_contents(dirname(__DIR__) . '/database/live_match_events_migration.sql');
if ($sql === false) {
    fwrite(STDERR, "Could not read migration SQL\n");
    exit(1);
}

try {
    $pdo->exec($sql);
    echo "Live match events migration complete.\n";
} catch (PDOException $e) {
    if (str_contains($e->getMessage(), 'Duplicate column')) {
        echo "Column event_seq already exists — skipped.\n";
        exit(0);
    }
    throw $e;
}
