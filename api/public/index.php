<?php

declare(strict_types=1);

use ChessAcademy\Middleware\CorsMiddleware;
use Slim\Factory\AppFactory;

require dirname(__DIR__) . '/vendor/autoload.php';

$settings = require dirname(__DIR__) . '/config/settings.php';
$container = (require dirname(__DIR__) . '/config/container.php')($settings);

AppFactory::setContainer($container);
$app = AppFactory::create();
$app->setBasePath('');

$app->addBodyParsingMiddleware();
$app->addRoutingMiddleware();
$app->add(new CorsMiddleware($settings['cors']['origin']));
$app->addErrorMiddleware($settings['app']['debug'], true, true, null);

$routes = require dirname(__DIR__) . '/config/routes.php';
$routes($app, $container);

$app->run();
