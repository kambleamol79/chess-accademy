<?php

declare(strict_types=1);

use ChessAcademy\Http\CorsHeaders;
use ChessAcademy\Middleware\CorsMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Log\LoggerInterface;
use Slim\Exception\HttpNotFoundException;
use Slim\Factory\AppFactory;

/**
 * Subdirectory prefix Slim must strip (e.g. /brainstorm).
 * Routes are registered as /api/v1/... so the base path must NOT include /api
 * even when the entry script lives under .../api/public/index.php.
 */
function api_resolve_base_path(string $configured): string
{
    $configured = rtrim($configured, '/');
    if ($configured !== '') {
        return $configured;
    }

    $scriptName = str_replace('\\', '/', (string) ($_SERVER['SCRIPT_NAME'] ?? ''));
    $scriptDir = str_replace('\\', '/', dirname($scriptName));
    if ($scriptDir === '/' || $scriptDir === '.') {
        return '';
    }

    $basePath = rtrim($scriptDir, '/');
    if (str_ends_with($basePath, '/public')) {
        $basePath = substr($basePath, 0, -7);
    }
    if (str_ends_with($basePath, '/api')) {
        $basePath = substr($basePath, 0, -4);
    }

    return $basePath === '/' ? '' : $basePath;
}

/** @param array<string, mixed> $payload */
function api_fail(int $status, array $payload): void
{
    if (!headers_sent()) {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode(['success' => false] + $payload, JSON_THROW_ON_ERROR);
    exit;
}

try {
    $autoload = dirname(__DIR__) . '/vendor/autoload.php';
    if (!is_file($autoload)) {
        api_fail(500, [
            'message' => 'API not installed: run "composer install" in the api folder on the server.',
        ]);
    }

    require $autoload;

    ini_set('display_errors', '0');

    $settings = require dirname(__DIR__) . '/config/settings.php';
} catch (Throwable $e) {
    api_fail(500, [
        'message' => 'API bootstrap failed',
        'error' => $e->getMessage(),
    ]);
}

try {
    $corsHeaders = new CorsHeaders(
        $settings['cors']['origins'],
        $settings['cors']['allow_local_dev'] ?? true
    );

    $container = (require dirname(__DIR__) . '/config/container.php')($settings);

    AppFactory::setContainer($container);
    $app = AppFactory::create();
    $basePath = api_resolve_base_path((string) ($settings['app']['base_path'] ?? ''));
    if ($basePath !== '') {
        $app->setBasePath($basePath);
    }

    $errorMiddleware = $app->addErrorMiddleware($settings['app']['debug'], true, true, null);
    $errorMiddleware->setDefaultErrorHandler(
        function (
            ServerRequestInterface $request,
            \Throwable $exception,
            bool $displayErrorDetails,
            bool $logErrors,
            bool $logErrorDetails,
            ?LoggerInterface $logger = null
        ) use ($app, $corsHeaders): ResponseInterface {
            $response = $app->getResponseFactory()->createResponse(500);
            $message = 'Server error';

            $pdo = $exception instanceof \PDOException ? $exception : $exception->getPrevious();
            if ($pdo instanceof \PDOException) {
                $response = $response->withStatus(503);
                $message = $displayErrorDetails
                    ? 'Database error: ' . $pdo->getMessage()
                    : 'Database error. Check that MySQL is running and api/.env DB settings are correct, then restart the API server.';
            } elseif ($displayErrorDetails) {
                $message = $exception->getMessage();
            }

            $response->getBody()->write((string) json_encode([
                'success' => false,
                'message' => $message,
            ], JSON_THROW_ON_ERROR));

            $response = $response->withHeader('Content-Type', 'application/json');

            return $corsHeaders->apply($request, $response);
        }
    );

    $app->addBodyParsingMiddleware();
    $app->addRoutingMiddleware();
    $app->add(new CorsMiddleware($corsHeaders));

    $routes = require dirname(__DIR__) . '/config/routes.php';
    $routes($app, $container);

    $app->run();
} catch (HttpNotFoundException $e) {
    $debug = (bool) ($settings['app']['debug'] ?? false);
    api_fail(404, [
        'message' => 'Route not found. Expected URL like {base}/api/v1/... (set APP_BASE_PATH=/brainstorm in api/.env for Hostinger).',
        'error' => $debug ? $e->getMessage() : 'Not found.',
        'hint' => $debug ? [
            'request_uri' => $_SERVER['REQUEST_URI'] ?? '',
            'base_path' => api_resolve_base_path((string) ($settings['app']['base_path'] ?? '')),
            'app_base_path_env' => (string) ($settings['app']['base_path'] ?? ''),
        ] : null,
    ]);
} catch (Throwable $e) {
    $debug = (bool) ($settings['app']['debug'] ?? false);
    api_fail(500, [
        'message' => 'API error',
        'error' => $debug ? $e->getMessage() : $e->getMessage(),
    ]);
}
