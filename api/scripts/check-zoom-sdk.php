#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Quick check: generates a Meeting SDK JWT using api/.env credentials.
 * Run: php api/scripts/check-zoom-sdk.php [meeting_number]
 */

$root = dirname(__DIR__);
require $root . '/vendor/autoload.php';

Dotenv\Dotenv::createImmutable($root)->safeLoad();

$clientId = $_ENV['ZOOM_SDK_CLIENT_ID'] ?? $_ENV['ZOOM_CLIENT_ID'] ?? '';
$clientSecret = $_ENV['ZOOM_SDK_CLIENT_SECRET'] ?? $_ENV['ZOOM_CLIENT_SECRET'] ?? '';
$meetingNumber = $argv[1] ?? '72752243277';

if ($clientId === '' || $clientSecret === '') {
    fwrite(STDERR, "Missing ZOOM_CLIENT_ID / ZOOM_CLIENT_SECRET in api/.env\n");
    exit(1);
}

$service = new ChessAcademy\Services\ZoomSdkService($clientId, $clientSecret);
$signature = $service->createSignature($meetingNumber, 0);

echo "Client ID: {$clientId}\n";
echo "Meeting:   {$meetingNumber}\n";
echo "Signature: {$signature}\n\n";
echo "If Join class still fails with error 3712, Zoom is rejecting these credentials.\n";
echo $service->setupHint() . "\n";
