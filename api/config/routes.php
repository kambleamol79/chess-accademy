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
use ChessAcademy\Controllers\ChessLiveMatchController;
use ChessAcademy\Controllers\ChessTournamentController;
use ChessAcademy\Controllers\PracticeSessionController;
use ChessAcademy\Controllers\PuzzleController;
use ChessAcademy\Controllers\SettingsController;
use ChessAcademy\Controllers\StudentController;
use ChessAcademy\Controllers\StudentPortalController;
use ChessAcademy\Controllers\SupportTicketController;
use ChessAcademy\Controllers\BatchMessageController;
use ChessAcademy\Controllers\BroadcastMessageController;
use ChessAcademy\Controllers\DeviceTokenController;
use ChessAcademy\Controllers\UserController;
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
            $settings = $container->get('settings');
            $detail = ($settings['app']['debug'] ?? false)
                ? ' ' . $e->getMessage()
                : '';
            $payload = [
                'success' => false,
                'message' => 'Database connection failed. Check that MySQL is running and api/.env DB settings are correct.' . $detail,
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
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->get('/dashboard/coach-schedule', [DashboardController::class, 'coachSchedule'])
            ->add(new RoleMiddleware(['coach']));

        // Student portal routes must be registered before /students/{id} (otherwise "me" matches {id}).
        $group->get('/students/me/batch', [StudentPortalController::class, 'myBatch'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/payments', [StudentPortalController::class, 'myPayments'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/reminders', [StudentPortalController::class, 'myReminders'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/notifications', [StudentPortalController::class, 'myNotifications'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/support-tickets', [SupportTicketController::class, 'myTickets'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/students/me/support-tickets', [SupportTicketController::class, 'storeMine'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/support-tickets/{id}', [SupportTicketController::class, 'show'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/students/me/support-tickets/{id}/messages', [SupportTicketController::class, 'addMessage'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/batch-messages', [BatchMessageController::class, 'myBatchMessages'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/students/me/broadcast-messages', [BroadcastMessageController::class, 'myMessages'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/students/me/device-token', [DeviceTokenController::class, 'store'])
            ->add(new RoleMiddleware(['student']));
        $group->delete('/students/me/device-token', [DeviceTokenController::class, 'destroy'])
            ->add(new RoleMiddleware(['student']));

        $group->get('/settings/tournament-cta', [SettingsController::class, 'tournamentCta'])
            ->add(new RoleMiddleware(['student']));

        $group->get('/broadcast-messages', [BroadcastMessageController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/broadcast-messages', [BroadcastMessageController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/support-tickets', [SupportTicketController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->get('/support-tickets/{id}', [SupportTicketController::class, 'show'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/support-tickets/{id}/messages', [SupportTicketController::class, 'addMessage'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/support-tickets/{id}', [SupportTicketController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/students', [StudentController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->get('/students/{id}/payment-receipt', [LeadController::class, 'paymentReceipt'])
            ->add(new RoleMiddleware(['admin', 'accountant']));
        $group->get('/students/{id}', [StudentController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'coach']));
        $group->post('/students', [StudentController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'coach']));
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
            ->add(new RoleMiddleware(['admin', 'accountant', 'coach']));
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

        $group->get('/forms/{form_id}/messages', [BatchMessageController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'coach', 'student']));
        $group->post('/forms/{form_id}/messages', [BatchMessageController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/enrollments', [EnrollmentController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/enrollments', [EnrollmentController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/enrollments/bulk-assign', [EnrollmentController::class, 'bulkAssign'])
            ->add(new RoleMiddleware(['admin', 'coach']));
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

        $group->get('/chess-tournaments', [ChessTournamentController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->get('/chess-tournaments/{id}', [ChessTournamentController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->post('/chess-tournaments', [ChessTournamentController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/chess-tournaments/{id}', [ChessTournamentController::class, 'updateStatus'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/chess-tournaments/{id}/start-round', [ChessTournamentController::class, 'startRound'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/chess-tournaments/{id}/register', [ChessTournamentController::class, 'register'])
            ->add(new RoleMiddleware(['student']));

        $group->get('/live-matches/mine', [ChessLiveMatchController::class, 'myMatches'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/live-matches/queue', [ChessLiveMatchController::class, 'queueStatus'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/live-matches/queue', [ChessLiveMatchController::class, 'joinQueue'])
            ->add(new RoleMiddleware(['student']));
        $group->delete('/live-matches/queue', [ChessLiveMatchController::class, 'leaveQueue'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/live-matches/{id}/stream', [ChessLiveMatchController::class, 'stream'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/live-matches/{id}/revision', [ChessLiveMatchController::class, 'revision'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/live-matches/{id}', [ChessLiveMatchController::class, 'show'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/live-matches/{id}/moves', [ChessLiveMatchController::class, 'move'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/live-matches/{id}/resign', [ChessLiveMatchController::class, 'resign'])
            ->add(new RoleMiddleware(['student']));
        $group->get('/live-matches/{id}/voice/signals', [ChessLiveMatchController::class, 'voiceSignals'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/live-matches/{id}/voice/clear', [ChessLiveMatchController::class, 'clearVoiceSignals'])
            ->add(new RoleMiddleware(['student']));
        $group->post('/live-matches/{id}/voice/signals', [ChessLiveMatchController::class, 'postVoiceSignal'])
            ->add(new RoleMiddleware(['student']));

        $group->get('/practice-sessions', [PracticeSessionController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->post('/practice-sessions', [PracticeSessionController::class, 'store'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->get('/practice-sessions/{id}', [PracticeSessionController::class, 'show'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->post('/practice-sessions/{id}/moves', [PracticeSessionController::class, 'addMove'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->delete('/practice-sessions/{id}/moves/last', [PracticeSessionController::class, 'deleteLastMove'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->patch('/practice-sessions/{id}', [PracticeSessionController::class, 'finalize'])
            ->add(new RoleMiddleware(['admin', 'student']));

        $group->get('/puzzles', [PuzzleController::class, 'index'])
            ->add(new RoleMiddleware(['admin', 'student']));
        $group->get('/puzzles/next', [PuzzleController::class, 'next'])
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
            ->add(new RoleMiddleware(['admin', 'coach', 'student']));
        $group->put('/games/{id}', [GameController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/games/{id}', [GameController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->delete('/games/{id}', [GameController::class, 'destroy'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/users', [UserController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->post('/users', [UserController::class, 'store'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/users/{id}', [UserController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/users/{id}', [UserController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));

        $group->get('/settings', [SettingsController::class, 'index'])
            ->add(new RoleMiddleware(['admin']));
        $group->put('/settings', [SettingsController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
        $group->patch('/settings', [SettingsController::class, 'update'])
            ->add(new RoleMiddleware(['admin']));
    })->add($jwt);
};
