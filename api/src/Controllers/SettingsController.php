<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\SettingsRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class SettingsController
{
    use JsonResponse;

    public function __construct(private readonly SettingsRepository $settings) {}

    public function index(Request $request, Response $response): Response
    {
        return $this->success($response, $this->settings->all());
    }

    public function update(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        if ($body === []) {
            return $this->error($response, 'No settings provided', 422);
        }

        foreach ($body as $key => $value) {
            $this->settings->set((string) $key, $value);
        }

        return $this->success($response, $this->settings->all(), 'Settings updated');
    }
}
