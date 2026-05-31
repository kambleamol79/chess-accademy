#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Auto-resign active live matches when the player to move has been idle for
 * time_control_minutes + grace (default +10 minutes).
 *
 * Run manually: php api/scripts/auto_resign_inactive_matches.php
 * Cron: see api/cron/live_match_auto_resign.cron
 */

require dirname(__DIR__) . '/vendor/autoload.php';

use ChessAcademy\Database\Connection;
use ChessAcademy\Repositories\ChessLiveMatchRepository;
use ChessAcademy\Services\ChessFenHelper;
use ChessAcademy\Services\LiveMatchBroadcaster;

Dotenv\Dotenv::createImmutable(dirname(__DIR__))->safeLoad();

$settings = require dirname(__DIR__) . '/config/settings.php';
$live = $settings['live'] ?? [];
$graceMinutes = (int) ($live['idle_grace_minutes'] ?? 10);

$pdo = Connection::get($settings);
$matches = new ChessLiveMatchRepository($pdo);
$broadcaster = new LiveMatchBroadcaster(
    $matches,
    (string) ($live['var_dir'] ?? dirname(__DIR__) . '/var'),
    (bool) ($live['ws_enabled'] ?? false),
    (string) ($live['ws_broadcast_url'] ?? ''),
    (string) ($live['ws_internal_secret'] ?? ''),
);

$stale = $matches->findInactiveActiveMatches($graceMinutes);
$count = 0;

foreach ($stale as $row) {
    $matchId = (int) $row['id'];
    $matches->syncClock($matchId);

    $refreshed = $matches->findById($matchId);
    if ($refreshed === null || ($refreshed['status'] ?? '') !== 'active') {
        continue;
    }

    $side = (string) ($refreshed['clock_side'] ?? '');
    if ($side !== 'w' && $side !== 'b') {
        $side = ChessFenHelper::activeColor((string) $refreshed['current_fen']);
    }

    $result = ChessLiveMatchRepository::winResultForSideToMove($side);
    $finished = $matches->finish($matchId, $result);
    if ($finished === null) {
        fwrite(STDERR, "Match {$matchId}: could not finish\n");
        continue;
    }

    $broadcaster->publish($matchId, 'timeout');
    $count++;
    $tc = (int) ($row['time_control_minutes'] ?? 0);
    $limit = $tc + $graceMinutes;
    echo "Match {$matchId}: auto-resigned (idle > {$limit} min, result={$result})\n";
}

echo $count === 0
    ? "No inactive matches (grace +{$graceMinutes} min).\n"
    : "Auto-resigned {$count} match(es).\n";
