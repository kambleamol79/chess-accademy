<?php

declare(strict_types=1);

namespace ChessAcademy\Middleware;

use ChessAcademy\Http\CorsHeaders;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Slim\Psr7\Response;

final class CorsMiddleware implements MiddlewareInterface
{
    public function __construct(private readonly CorsHeaders $cors) {}

    public function process(ServerRequestInterface $request, RequestHandlerInterface $handler): ResponseInterface
    {
        if ($request->getMethod() === 'OPTIONS') {
            $response = new Response(204);

            return $this->cors->apply($request, $response);
        }

        return $this->cors->apply($request, $handler->handle($request));
    }
}
