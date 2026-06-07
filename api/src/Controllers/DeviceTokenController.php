<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\DeviceTokenRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class DeviceTokenController
{
    use JsonResponse;

    public function __construct(private readonly DeviceTokenRepository $tokens) {}

    public function store(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $token = trim((string) ($body['token'] ?? ''));
        $platform = strtolower(trim((string) ($body['platform'] ?? 'android')));

        if ($token === '') {
            return $this->error($response, 'token is required', 422);
        }
        if (!in_array($platform, ['android', 'ios', 'web'], true)) {
            $platform = 'android';
        }

        $this->tokens->upsert((int) $authUser['id'], $token, $platform);

        return $this->success($response, null, 'Device token registered');
    }

    public function destroy(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $token = trim((string) ($body['token'] ?? ''));
        if ($token !== '') {
            $this->tokens->deleteToken($token);
        }

        return $this->success($response, null, 'Device token removed');
    }
}
