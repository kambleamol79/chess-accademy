<?php

declare(strict_types=1);

use Dotenv\Dotenv;

$root = dirname(__DIR__);

if (file_exists($root . '/.env')) {
    Dotenv::createImmutable($root)->safeLoad();
}

return [
    'app' => [
        'env' => $_ENV['APP_ENV'] ?? 'development',
        'debug' => filter_var($_ENV['APP_DEBUG'] ?? 'true', FILTER_VALIDATE_BOOLEAN),
    ],
    'db' => [
        'host' => $_ENV['DB_HOST'] ?? '127.0.0.1',
        'port' => $_ENV['DB_PORT'] ?? '3306',
        'name' => $_ENV['DB_NAME'] ?? 'chess_academy',
        'user' => $_ENV['DB_USER'] ?? 'root',
        'pass' => $_ENV['DB_PASS'] ?? $_ENV['DB_PASSWORD'] ?? getenv('DB_PASS') ?: getenv('DB_PASSWORD') ?: '',
    ],
    'cors' => [
        'origins' => array_values(array_filter(array_map(
            'trim',
            explode(',', $_ENV['CORS_ORIGIN'] ?? 'http://localhost:4200,http://127.0.0.1:4200')
        ))),
        // Allow any localhost / 127.0.0.1 port (e.g. ng serve on 4201)
        'allow_local_dev' => filter_var($_ENV['CORS_ALLOW_LOCAL_DEV'] ?? 'true', FILTER_VALIDATE_BOOLEAN),
    ],
    'jwt' => [
        'secret' => $_ENV['JWT_SECRET'] ?? 'change-me-in-production-use-long-random-string',
        'ttl' => (int) ($_ENV['JWT_TTL'] ?? 3600),
        'refresh_ttl_days' => (int) ($_ENV['JWT_REFRESH_TTL_DAYS'] ?? 30),
    ],
];
