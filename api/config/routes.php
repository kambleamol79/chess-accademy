<?php

declare(strict_types=1);

use ChessAcademy\Controllers\AuthController;
use ChessAcademy\Controllers\BillingController;
use ChessAcademy\Controllers\CoachController;
use ChessAcademy\Controllers\DashboardController;
use ChessAcademy\Controllers\EnrollmentController;
use ChessAcademy\Controllers\FormController;
use ChessAcademy\Controllers\LeadController;
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

    $app->get('/api/v1/health/db', function ($request, $response) use ($container) {
        try {
            $container->get(\PDO::class)->query('SELECT 1');
            $payload = ['success' => true, 'data' => ['database' => 'connected']];
            $status = 200;
        } catch (\Throwable $e) {
            $payload = [
                'success' => false,
                'message' => 'Database connection failed. Set DB_PASS in api/.env and restart the API server.',
            ];
            $status = 503;
        }
        $response->getBody()->write(json_encode($payload, JSON_THROW_ON_ERROR));

        return $response->withHeader('Content-Type', 'application/json')->withStatus($status);
    });

    $app->group('/api/v1/auth', function (RouteCollectorProxy $group) {
        $group->post('/login', [AuthController::class, 'login']);
        $group->post('/register', [AuthController::class, 'register']);
        $group->post('/refresh', [AuthController::class, 'refresh']);
        $group->post('/logout', [AuthController::class, 'logout']);
    });

    $app->group('/api/v1', function (RouteCollectorProxy $group) {
        $group->get('/auth/me', [AuthController::class, 'me']);

        $group->get('/dashboard/metrics', [DashboardController::class, 'metrics'])
            ->add(new RoleMiddleware(['admin', 'student', 'accountant']));
        $group->get('/dashboard/coach-schedule', [DashboardController::class, 'coachSchedule'])
            ->add(new RoleMiddleware(['coach']));

        $group->get('/students', [StudentController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->get('/students/{id}/payment-receipt', [LeadController::class, 'paymentReceipt'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->get('/students/{id}', [StudentController::class, 'show'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/students', [StudentController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/students/{id}', [StudentController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/students/{id}', [StudentController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/students/{id}', [StudentController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/coaches', [CoachController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->get('/coaches/me', [CoachController::class, 'me'])
            ->add(new RoleMiddleware(['coach']));
        $group->patch('/coaches/me', [CoachController::class, 'updateMe'])
            ->add(new RoleMiddleware(['coach']));
        $group->get('/coaches/{id}/schedule', [CoachController::class, 'schedule'])
            ->add(new RoleMiddleware(['admin']));
        $group->get('/coaches/{id}', [CoachController::class, 'show'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/coaches', [CoachController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/coaches/{id}', [CoachController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/coaches/{id}', [CoachController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/coaches/{id}', [CoachController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/leads', [LeadController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->get('/leads/{id}', [LeadController::class, 'show'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/leads', [LeadController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/leads/bulk', [LeadController::class, 'bulk'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/leads/{id}', [LeadController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/leads/{id}', [LeadController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/leads/{id}/mark-paid', [LeadController::class, 'markPaid'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/leads/{id}', [LeadController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/forms', [FormController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student', 'accountant']));
        $group->get('/forms/next-batch', [FormController::class, 'nextBatch'])
            ->add(new RoleMiddleware(['admin']));
        $group->get('/forms/{id}', [FormController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'student', 'accountant']));
        $group->post('/forms', [FormController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/forms/{id}', [FormController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/forms/{id}', [FormController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/forms/{id}', [FormController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/enrollments', [EnrollmentController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/enrollments', [EnrollmentController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/enrollments/bulk-assign', [EnrollmentController::class, 'bulkAssign'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/enrollments/{id}', [EnrollmentController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/billing/invoices', [BillingController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->get('/billing/invoices/{id}', [BillingController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
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

        $group->get('/puzzles', [PuzzleController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->get('/puzzles/{id}', [PuzzleController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->post('/puzzles', [PuzzleController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/puzzles/{id}/attempt', [PuzzleController::class, 'attempt'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->delete('/puzzles/{id}', [PuzzleController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/games', [GameController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->get('/games/{id}', [GameController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->post('/games', [GameController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->put('/games/{id}', [GameController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/games/{id}', [GameController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/games/{id}', [GameController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/materials', [MaterialController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->post('/materials', [MaterialController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/materials/{id}', [MaterialController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/settings', [SettingsController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/settings', [SettingsController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/settings', [SettingsController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
    })->add($jwt);
};
