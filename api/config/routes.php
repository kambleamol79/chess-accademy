<?php

declare(strict_types=1);

use ChessAcademy\Controllers\AuthController;
use ChessAcademy\Controllers\BillingController;
use ChessAcademy\Controllers\CoachController;
use ChessAcademy\Controllers\DashboardController;
use ChessAcademy\Controllers\EnrollmentController;
use ChessAcademy\Controllers\FormController;
use ChessAcademy\Controllers\GameController;
use ChessAcademy\Controllers\MaterialController;
use ChessAcademy\Controllers\PuzzleController;
use ChessAcademy\Controllers\SettingsController;
use ChessAcademy\Controllers\StudentController;
use ChessAcademy\Middleware\JwtAuthMiddleware;
use ChessAcademy\Middleware\RoleMiddleware;
use DI\Container;
use Slim\App;
use Slim\Routing\RouteCollectorProxy;

return function (App $app, Container $container): void {
    $jwt = $container->get(JwtAuthMiddleware::class);

    $app->get('/api/v1/health', function ($request, $response) {
        $response->getBody()->write(json_encode([
            'success' => true,
            'data' => ['status' => 'ok', 'service' => 'chess-academy-api'],
        ], JSON_THROW_ON_ERROR));

        return $response->withHeader('Content-Type', 'application/json');
    });

    $app->group('/api/v1/auth', function (RouteCollectorProxy $group) {
        $group->post('/login', [AuthController::class, 'login']);
        $group->post('/register', [AuthController::class, 'register']);
        $group->post('/refresh', [AuthController::class, 'refresh']);
        $group->post('/logout', [AuthController::class, 'logout']);
    });

    $app->group('/api/v1', function (RouteCollectorProxy $group) {
        $group->get('/auth/me', [AuthController::class, 'me']);

        $group->get('/dashboard/metrics', [DashboardController::class, 'metrics']);

        $group->get('/students', [StudentController::class, 'index']);
        $group->get('/students/{id}', [StudentController::class, 'show']);
        $group->post('/students', [StudentController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/students/{id}', [StudentController::class, 'update']);
        $group->patch('/students/{id}', [StudentController::class, 'update']);
        $group->delete('/students/{id}', [StudentController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/coaches', [CoachController::class, 'index']);
        $group->get('/coaches/{id}', [CoachController::class, 'show']);
        $group->post('/coaches', [CoachController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/coaches/{id}', [CoachController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/coaches/{id}', [CoachController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/coaches/{id}', [CoachController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/forms', [FormController::class, 'index']);
        $group->get('/forms/{id}', [FormController::class, 'show']);
        $group->post('/forms', [FormController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->put('/forms/{id}', [FormController::class, 'update'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->patch('/forms/{id}', [FormController::class, 'update'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->delete('/forms/{id}', [FormController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/enrollments', [EnrollmentController::class, 'index']);
        $group->post('/enrollments', [EnrollmentController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->delete('/enrollments/{id}', [EnrollmentController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin', 'coach']));

        $group->get('/billing/invoices', [BillingController::class, 'index']);
        $group->get('/billing/invoices/{id}', [BillingController::class, 'show']);
        $group->post('/billing/invoices', [BillingController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->put('/billing/invoices/{id}', [BillingController::class, 'update'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->patch('/billing/invoices/{id}', [BillingController::class, 'update'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->patch('/billing/invoices/{id}/pay', [BillingController::class, 'pay'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->delete('/billing/invoices/{id}', [BillingController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/puzzles', [PuzzleController::class, 'index']);
        $group->get('/puzzles/{id}', [PuzzleController::class, 'show']);
        $group->post('/puzzles', [PuzzleController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->post('/puzzles/{id}/attempt', [PuzzleController::class, 'attempt']);
        $group->delete('/puzzles/{id}', [PuzzleController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin', 'coach']));

        $group->get('/games', [GameController::class, 'index']);
        $group->get('/games/{id}', [GameController::class, 'show']);
        $group->post('/games', [GameController::class, 'store']);
        $group->put('/games/{id}', [GameController::class, 'update'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->patch('/games/{id}', [GameController::class, 'update'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->delete('/games/{id}', [GameController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin', 'coach']));

        $group->get('/materials', [MaterialController::class, 'index']);
        $group->post('/materials', [MaterialController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->delete('/materials/{id}', [MaterialController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin', 'coach']));

        $group->get('/settings', [SettingsController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/settings', [SettingsController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/settings', [SettingsController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
    })->add($jwt);
};
