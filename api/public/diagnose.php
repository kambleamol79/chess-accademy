<?php

declare(strict_types=1);

/**
 * Upload with the API, then open once in the browser:
 * https://alphasynctechnology.com/brainstorm/api/public/diagnose.php
 * Delete this file after the site works.
 */
header('Content-Type: application/json; charset=utf-8');

$root = dirname(__DIR__);
$result = [
    'ok' => true,
    'php_version' => PHP_VERSION,
    'api_root' => $root,
    'checks' => [],
];

$add = static function (string $name, bool $pass, string $detail = '') use (&$result): void {
    $result['checks'][$name] = ['ok' => $pass, 'detail' => $detail];
    if (!$pass) {
        $result['ok'] = false;
    }
};

$add('vendor_autoload', is_file($root . '/vendor/autoload.php'));
$add('env_file', is_file($root . '/.env'), is_file($root . '/.env') ? 'found' : 'missing — copy .env.example to .env');
$add('index_php', is_file(__DIR__ . '/index.php'), 'bytes=' . (is_file(__DIR__ . '/index.php') ? filesize(__DIR__ . '/index.php') : 0));

if (!is_file($root . '/vendor/autoload.php')) {
    echo json_encode($result, JSON_PRETTY_PRINT);
    exit;
}

try {
    require $root . '/vendor/autoload.php';
    $settings = require $root . '/config/settings.php';
    $add('settings', true, 'base_path=' . ($settings['app']['base_path'] ?? ''));

    $host = $settings['db']['host'];
    $port = $settings['db']['port'];
    $name = $settings['db']['name'];
    $user = $settings['db']['user'];
    $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4', $host, $port, $name);
    $pdo = new PDO($dsn, $user, $settings['db']['pass'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $pdo->query('SELECT 1');
    $add('database', true, $name);
} catch (Throwable $e) {
    $add('bootstrap', false, $e::class . ': ' . $e->getMessage());
}

try {
    $container = (require $root . '/config/container.php')($settings);
    $add('container', true, 'DI container built');
} catch (Throwable $e) {
    $add('container', false, $e::class . ': ' . $e->getMessage());
}

echo json_encode($result, JSON_PRETTY_PRINT | JSON_THROW_ON_ERROR);
