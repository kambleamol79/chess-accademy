<?php

declare(strict_types=1);

/**
 * Reset clock ms that overflowed INT UNSIGNED (timezone skew added time instead of subtracting).
 */
require dirname(__DIR__) . '/vendor/autoload.php';

use ChessAcademy\Database\Connection;

$settings = require dirname(__DIR__) . '/config/settings.php';
$pdo = Connection::get($settings);

$capMs = 180 * 60 * 1000;
$sql = <<<SQL
UPDATE chess_live_matches
SET white_ms_remaining = time_control_minutes * 60 * 1000,
    black_ms_remaining = time_control_minutes * 60 * 1000,
    clock_since = NOW()
WHERE status = 'active'
  AND (
    white_ms_remaining > {$capMs}
    OR black_ms_remaining > {$capMs}
    OR white_ms_remaining > time_control_minutes * 60 * 1000
    OR black_ms_remaining > time_control_minutes * 60 * 1000
  )
SQL;

$count = $pdo->exec($sql);
echo 'Fixed clock values on ' . ($count === false ? 0 : $count) . " active match row(s).\n";
