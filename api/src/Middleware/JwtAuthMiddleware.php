<?php

declare(strict_types=1);

namespace ChessAcademy\Middleware;

use ChessAcademy\Services\JwtService;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Slim\Psr7\Response;

final class JwtAuthMiddleware implements MiddlewareInterface
{
    public function __construct(private readonly JwtService $jwt) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        $header = $request->getHeaderLine('Authorization');
        if (!preg_match('/Bearer\s+(\S+)/i', $header, $matches)) {
            return $this->unauthorized('Missing or invalid Authorization header');
        }

        try {
            $user = $this->jwt->decodeAccessToken($matches[1]);
        } catch (ExpiredException) {
            return $this->unauthorized('Token expired');
        } catch (SignatureInvalidException|\UnexpectedValueException|\InvalidArgumentException) {
            return $this->unauthorized('Invalid token');
        }

        return $handler->handle($request->withAttribute('user', $user));
    }

    private function unauthorized(string $message): ResponseInterface
    {
        $response = new Response(401);
        $response->getBody()->write(json_encode([
            'success' => false,
            'message' => $message,
        ], JSON_THROW_ON_ERROR));

        return $response->withHeader('Content-Type', 'application/json');
    }
}
