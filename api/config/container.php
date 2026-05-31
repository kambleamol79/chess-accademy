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
use ChessAcademy\Database\Connection;
use ChessAcademy\Middleware\JwtAuthMiddleware;
use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Repositories\DashboardRepository;
use ChessAcademy\Repositories\EnrollmentRepository;
use ChessAcademy\Repositories\FormRepository;
use ChessAcademy\Repositories\LeadRepository;
use ChessAcademy\Repositories\ChessLiveMatchRepository;
use ChessAcademy\Repositories\ChessTournamentRepository;
use ChessAcademy\Repositories\GameRepository;
use ChessAcademy\Repositories\InvoiceRepository;
use ChessAcademy\Repositories\PracticeSessionRepository;
use ChessAcademy\Repositories\PuzzleRepository;
use ChessAcademy\Repositories\SettingsRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Repositories\UserRepository;
use ChessAcademy\Services\AuthService;
use ChessAcademy\Services\BatchZoomService;
use ChessAcademy\Services\JwtService;
use ChessAcademy\Services\LeadConversionService;
use ChessAcademy\Services\LeadCsvParser;
use ChessAcademy\Services\PaymentReceiptUploadService;
use ChessAcademy\Services\ZoomSdkService;
use ChessAcademy\Services\ZoomService;
use ChessAcademy\Services\ChessLiveMatchService;
use ChessAcademy\Services\ChessRulesService;
use ChessAcademy\Services\LiveMatchBroadcaster;
use ChessAcademy\Services\LiveMatchVoiceSignaling;
use ChessAcademy\Services\StudentPortalService;
use DI\Container;

/** @param array<string,mixed> $settings */
return function (array $settings): Container {
    $container = new Container();
    $container->set('settings', $settings);

    $container->set(PDO::class, fn () => Connection::get($settings));

    $container->set(JwtService::class, fn () => new JwtService(
        $settings['jwt']['secret'],
        $settings['jwt']['ttl']
    ));

    $container->set(UserRepository::class, fn (Container $c) => new UserRepository($c->get(PDO::class)));
    $container->set(FormRepository::class, fn (Container $c) => new FormRepository($c->get(PDO::class)));
    $container->set(ZoomService::class, fn () => new ZoomService(
        filter_var($settings['zoom']['enabled'] ?? 'false', FILTER_VALIDATE_BOOLEAN),
        (string) ($settings['zoom']['account_id'] ?? ''),
        (string) ($settings['zoom']['client_id'] ?? ''),
        (string) ($settings['zoom']['client_secret'] ?? ''),
        (string) ($settings['zoom']['user_id'] ?? ''),
        (string) ($settings['zoom']['timezone'] ?? 'Asia/Kolkata'),
    ));
    $container->set(BatchZoomService::class, fn (Container $c) => new BatchZoomService($c->get(ZoomService::class)));
    $container->set(ZoomSdkService::class, fn () => new ZoomSdkService(
        (string) ($settings['zoom']['sdk_client_id'] ?? ''),
        (string) ($settings['zoom']['sdk_client_secret'] ?? ''),
    ));
    $container->set(LeadRepository::class, fn (Container $c) => new LeadRepository($c->get(PDO::class)));
    $container->set(LeadCsvParser::class, fn () => new LeadCsvParser());
    $container->set(PaymentReceiptUploadService::class, fn (Container $c) => new PaymentReceiptUploadService(
        (string) $c->get('settings')['uploads']['payment_receipts_dir'],
        (int) $c->get('settings')['uploads']['payment_receipt_max_bytes'],
    ));
    $container->set(LeadConversionService::class, fn (Container $c) => new LeadConversionService(
        $c->get(PDO::class),
        $c->get(LeadRepository::class),
        $c->get(UserRepository::class),
        $c->get(StudentRepository::class),
    ));
    $container->set(StudentRepository::class, fn (Container $c) => new StudentRepository($c->get(PDO::class)));
    $container->set(CoachRepository::class, fn (Container $c) => new CoachRepository($c->get(PDO::class)));
    $container->set(EnrollmentRepository::class, fn (Container $c) => new EnrollmentRepository($c->get(PDO::class)));
    $container->set(InvoiceRepository::class, fn (Container $c) => new InvoiceRepository($c->get(PDO::class)));
    $container->set(PuzzleRepository::class, fn (Container $c) => new PuzzleRepository($c->get(PDO::class)));
    $container->set(GameRepository::class, fn (Container $c) => new GameRepository($c->get(PDO::class)));
    $container->set(SettingsRepository::class, fn (Container $c) => new SettingsRepository($c->get(PDO::class)));
    $container->set(DashboardRepository::class, fn (Container $c) => new DashboardRepository($c->get(PDO::class)));

    $container->set(AuthService::class, fn (Container $c) => new AuthService(
        $c->get(UserRepository::class),
        $c->get(JwtService::class),
        $c->get(PDO::class),
        $settings['jwt']['refresh_ttl_days']
    ));

    $container->set(JwtAuthMiddleware::class, fn (Container $c) => new JwtAuthMiddleware($c->get(JwtService::class)));

    $container->set(AuthController::class, fn (Container $c) => new AuthController(
        $c->get(AuthService::class),
        $c->get(UserRepository::class)
    ));
    $container->set(FormController::class, fn (Container $c) => new FormController(
        $c->get(FormRepository::class),
        $c->get(BatchZoomService::class),
        $c->get(ZoomSdkService::class),
        $c->get(ZoomService::class),
        $c->get(UserRepository::class),
    ));
    $container->set(LeadController::class, fn (Container $c) => new LeadController(
        $c->get(LeadRepository::class),
        $c->get(LeadCsvParser::class),
        $c->get(LeadConversionService::class),
        $c->get(PaymentReceiptUploadService::class),
        $c->get(StudentRepository::class),
    ));
    $container->set(DashboardController::class, fn (Container $c) => new DashboardController(
        $c->get(DashboardRepository::class),
        $c->get(CoachRepository::class)
    ));
    $container->set(StudentController::class, fn (Container $c) => new StudentController(
        $c->get(StudentRepository::class),
        $c->get(UserRepository::class),
        $c->get(AuthService::class)
    ));
    $container->set(StudentPortalService::class, fn (Container $c) => new StudentPortalService(
        $c->get(EnrollmentRepository::class),
        $c->get(InvoiceRepository::class),
    ));
    $container->set(StudentPortalController::class, fn (Container $c) => new StudentPortalController(
        $c->get(StudentRepository::class),
        $c->get(StudentPortalService::class),
    ));
    $container->set(CoachController::class, fn (Container $c) => new CoachController(
        $c->get(CoachRepository::class),
        $c->get(AuthService::class)
    ));
    $container->set(EnrollmentController::class, fn (Container $c) => new EnrollmentController($c->get(EnrollmentRepository::class)));
    $container->set(BillingController::class, fn (Container $c) => new BillingController($c->get(InvoiceRepository::class)));
    $container->set(ChessTournamentRepository::class, fn (Container $c) => new ChessTournamentRepository($c->get(PDO::class)));
    $container->set(ChessLiveMatchRepository::class, fn (Container $c) => new ChessLiveMatchRepository($c->get(PDO::class)));
    $container->set(ChessRulesService::class, fn () => new ChessRulesService());
    $container->set(LiveMatchBroadcaster::class, fn (Container $c) => new LiveMatchBroadcaster(
        $c->get(ChessLiveMatchRepository::class),
        (string) $c->get('settings')['live']['var_dir'],
        (bool) $c->get('settings')['live']['ws_enabled'],
        (string) $c->get('settings')['live']['ws_broadcast_url'],
        (string) $c->get('settings')['live']['ws_internal_secret'],
    ));
    $container->set(LiveMatchVoiceSignaling::class, fn (Container $c) => new LiveMatchVoiceSignaling(
        (string) $c->get('settings')['live']['var_dir'],
    ));
    $container->set(ChessLiveMatchService::class, fn (Container $c) => new ChessLiveMatchService(
        $c->get(ChessLiveMatchRepository::class),
        $c->get(ChessRulesService::class),
        $c->get(LiveMatchBroadcaster::class),
    ));
    $container->set(ChessTournamentController::class, fn (Container $c) => new ChessTournamentController(
        $c->get(ChessTournamentRepository::class),
        $c->get(ChessLiveMatchRepository::class),
        $c->get(StudentRepository::class),
    ));
    $container->set(ChessLiveMatchController::class, fn (Container $c) => new ChessLiveMatchController(
        $c->get(ChessLiveMatchRepository::class),
        $c->get(ChessTournamentRepository::class),
        $c->get(ChessLiveMatchService::class),
        $c->get(StudentRepository::class),
        $c->get(LiveMatchBroadcaster::class),
        $c->get(LiveMatchVoiceSignaling::class),
    ));
    $container->set(PracticeSessionRepository::class, fn (Container $c) => new PracticeSessionRepository($c->get(PDO::class)));
    $container->set(PracticeSessionController::class, fn (Container $c) => new PracticeSessionController(
        $c->get(PracticeSessionRepository::class)
    ));
    $container->set(PuzzleController::class, fn (Container $c) => new PuzzleController(
        $c->get(PuzzleRepository::class),
        $c->get(StudentRepository::class)
    ));
    $container->set(GameController::class, fn (Container $c) => new GameController(
        $c->get(GameRepository::class),
        $c->get(StudentRepository::class),
        $c->get(CoachRepository::class),
    ));
    $container->set(SettingsController::class, fn (Container $c) => new SettingsController($c->get(SettingsRepository::class)));

    return $container;
};
