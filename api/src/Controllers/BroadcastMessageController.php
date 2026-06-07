<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\BroadcastMessageRepository;
use ChessAcademy\Repositories\DeviceTokenRepository;
use ChessAcademy\Services\FirebaseMessagingService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class BroadcastMessageController
{
    use JsonResponse;

    public function __construct(
        private readonly BroadcastMessageRepository $broadcasts,
        private readonly DeviceTokenRepository $deviceTokens,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        return $this->success($response, ['messages' => $this->broadcasts->findAll()]);
    }

    public function store(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $title = trim((string) ($body['title'] ?? ''));
        $message = trim((string) ($body['body'] ?? $body['message'] ?? ''));

        if ($title === '') {
            $title = 'Brainstorm announcement';
        }
        if ($message === '') {
            return $this->error($response, 'Message is required', 422);
        }

        $data = [
            'type' => 'broadcast',
            'title' => $title,
        ];

        $firebase = FirebaseMessagingService::createOptional();
        $pushResult = $firebase->sendToStudentsTopic($title, $message, $data);
        if (!$pushResult['ok']) {
            $tokens = $this->deviceTokens->allTokens();
            if ($tokens !== []) {
                $tokenResult = $firebase->sendToTokens($tokens, $title, $message, $data);
                $pushResult = [
                    'ok' => $tokenResult['ok'],
                    'detail' => $tokenResult['detail'],
                ];
            }
        }

        $created = $this->broadcasts->create(
            (int) $authUser['id'],
            $title,
            $message,
            (bool) ($pushResult['ok'] ?? false),
            (string) ($pushResult['detail'] ?? null),
        );

        $apiMessage = ($pushResult['ok'] ?? false)
            ? 'Announcement sent to all students'
            : 'Announcement saved (Firebase push is optional and not configured)';

        return $this->success($response, [
            'message' => $created,
            'push' => $pushResult,
        ], $apiMessage, 201);
    }

    public function myMessages(Request $request, Response $response): Response
    {
        return $this->success($response, ['messages' => $this->broadcasts->findRecent()]);
    }
}
