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
use ChessAcademy\Database\Connection;
use ChessAcademy\Middleware\JwtAuthMiddleware;
use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Repositories\DashboardRepository;
use ChessAcademy\Repositories\EnrollmentRepository;
use ChessAcademy\Repositories\FormRepository;
use ChessAcademy\Repositories\GameRepository;
use ChessAcademy\Repositories\InvoiceRepository;
use ChessAcademy\Repositories\MaterialRepository;
use ChessAcademy\Repositories\PuzzleRepository;
use ChessAcademy\Repositories\SettingsRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Repositories\UserRepository;
use ChessAcademy\Services\AuthService;
use ChessAcademy\Services\JwtService;
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
    $container->set(StudentRepository::class, fn (Container $c) => new StudentRepository($c->get(PDO::class)));
    $container->set(CoachRepository::class, fn (Container $c) => new CoachRepository($c->get(PDO::class)));
    $container->set(EnrollmentRepository::class, fn (Container $c) => new EnrollmentRepository($c->get(PDO::class)));
    $container->set(InvoiceRepository::class, fn (Container $c) => new InvoiceRepository($c->get(PDO::class)));
    $container->set(PuzzleRepository::class, fn (Container $c) => new PuzzleRepository($c->get(PDO::class)));
    $container->set(GameRepository::class, fn (Container $c) => new GameRepository($c->get(PDO::class)));
    $container->set(MaterialRepository::class, fn (Container $c) => new MaterialRepository($c->get(PDO::class)));
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
    $container->set(FormController::class, fn (Container $c) => new FormController($c->get(FormRepository::class)));
    $container->set(DashboardController::class, fn (Container $c) => new DashboardController($c->get(DashboardRepository::class)));
    $container->set(StudentController::class, fn (Container $c) => new StudentController(
        $c->get(StudentRepository::class),
        $c->get(UserRepository::class),
        $c->get(AuthService::class)
    ));
    $container->set(CoachController::class, fn (Container $c) => new CoachController(
        $c->get(CoachRepository::class),
        $c->get(AuthService::class)
    ));
    $container->set(EnrollmentController::class, fn (Container $c) => new EnrollmentController($c->get(EnrollmentRepository::class)));
    $container->set(BillingController::class, fn (Container $c) => new BillingController($c->get(InvoiceRepository::class)));
    $container->set(PuzzleController::class, fn (Container $c) => new PuzzleController(
        $c->get(PuzzleRepository::class),
        $c->get(StudentRepository::class)
    ));
    $container->set(GameController::class, fn (Container $c) => new GameController(
        $c->get(GameRepository::class),
        $c->get(StudentRepository::class)
    ));
    $container->set(MaterialController::class, fn (Container $c) => new MaterialController($c->get(MaterialRepository::class)));
    $container->set(SettingsController::class, fn (Container $c) => new SettingsController($c->get(SettingsRepository::class)));

    return $container;
};
