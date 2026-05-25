<?php

declare(strict_types=1);

use ChessAcademy\Http\CorsHeaders;
use ChessAcademy\Middleware\CorsMiddleware;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Log\LoggerInterface;
use Slim\Factory\AppFactory;

require dirname(__DIR__) . '/vendor/autoload.php';

$settings = require dirname(__DIR__) . '/config/settings.php';

$corsHeaders = new CorsHeaders(
    $settings['cors']['origins'],
    $settings['cors']['allow_local_dev'] ?? true
);

$container = (require dirname(__DIR__) . '/config/container.php')($settings);

AppFactory::setContainer($container);
$app = AppFactory::create();
$app->setBasePath('');

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
            $message = 'Database connection failed. Set DB_PASS in api/.env to your MySQL password, then restart the API server.';
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
