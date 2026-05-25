<?php

declare(strict_types=1);

namespace ChessAcademy\Middleware;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Slim\Psr7\Response;

final class RoleMiddleware implements MiddlewareInterface
{
    /** @param list<string> $roles */
    public function __construct(private readonly array $roles) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || !isset($user['role'])) {
            return $this->forbidden('Unauthorized');
        }

        if (!in_array($user['role'], $this->roles, true)) {
            return $this->forbidden('Insufficient permissions');
        }

        return $handler->handle($request);
    }

    private function forbidden(string $message): ResponseInterface
    {
        $response = new Response(403);
        $response->getBody()->write(json_encode([
            'success' => false,
            'message' => $message,
        ], JSON_THROW_ON_ERROR));

        return $response->withHeader('Content-Type', 'application/json');
    }
}
