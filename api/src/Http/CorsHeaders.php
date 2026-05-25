<?php

declare(strict_types=1);

namespace ChessAcademy\Http;

use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\ServerRequestInterface;

final class CorsHeaders
{
    /** @param list<string> $allowedOrigins */
    public function __construct(
        private readonly array $allowedOrigins,
        private readonly bool $allowLocalDevOrigins = true
    ) {}

    public function apply(ServerRequestInterface $request, ResponseInterface $response): ResponseInterface
    {
        $origin = $request->getHeaderLine('Origin');
        $allowOrigin = $this->resolveAllowedOrigin($origin);

        if ($allowOrigin === null) {
            return $response;
        }

        return $response
            ->withHeader('Access-Control-Allow-Origin', $allowOrigin)
            ->withHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, X-Requested-With')
            ->withHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
            ->withHeader('Access-Control-Max-Age', '86400')
            ->withHeader('Vary', 'Origin');
    }

    public function resolveAllowedOrigin(string $origin): ?string
    {
        if ($origin === '') {
            return $this->allowedOrigins[0] ?? null;
        }

        if (in_array($origin, $this->allowedOrigins, true)) {
            return $origin;
        }

        if ($this->allowLocalDevOrigins && preg_match('#^https?://(localhost|127\.0\.0\.1)(:\d+)?$#', $origin)) {
            return $origin;
        }

        return null;
    }
}
