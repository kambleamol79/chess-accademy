<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\DashboardRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class DashboardController
{
    use JsonResponse;

    public function __construct(private readonly DashboardRepository $dashboard) {}

    public function metrics(Request $request, Response $response): Response
    {
        return $this->success($response, $this->dashboard->metrics());
    }
}
