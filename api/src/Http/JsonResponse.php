<?php

declare(strict_types=1);

namespace ChessAcademy\Http;

use Psr\Http\Message\ResponseInterface as Response;

trait JsonResponse
{
    protected function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write((string) json_encode($payload, JSON_THROW_ON_ERROR));

        return $response
            ->withHeader('Content-Type', 'application/json')
            ->withStatus($status);
    }

    protected function success(Response $response, mixed $data = null, ?string $message = null, int $status = 200): Response
    {
        $payload = ['success' => true];
        if ($data !== null) {
            $payload['data'] = $data;
        }
        if ($message !== null) {
            $payload['message'] = $message;
        }

        return $this->json($response, $payload, $status);
    }

    protected function error(Response $response, string $message, int $status = 400, ?array $errors = null): Response
    {
        $payload = ['success' => false, 'message' => $message];
        if ($errors !== null) {
            $payload['errors'] = $errors;
        }

        return $this->json($response, $payload, $status);
    }
}
