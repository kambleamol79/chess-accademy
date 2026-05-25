<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use Firebase\JWT\JWT;
use Firebase\JWT\Key;

final class JwtService
{
    public function __construct(
        private readonly string $secret,
        private readonly int $ttlSeconds,
        private readonly string $issuer = 'chess-academy'
    ) {}

    /** @param array{id:int,email:string,role:string} $user */
    public function createAccessToken(array $user): string
    {
        $now = time();

        return JWT::encode([
            'iss' => $this->issuer,
            'iat' => $now,
            'exp' => $now + $this->ttlSeconds,
            'sub' => (string) $user['id'],
            'email' => $user['email'],
            'role' => $user['role'],
        ], $this->secret, 'HS256');
    }

    /** @return array{id:int,email:string,role:string} */
    public function decodeAccessToken(string $token): array
    {
        $decoded = JWT::decode($token, new Key($this->secret, 'HS256'));

        return [
            'id' => (int) $decoded->sub,
            'email' => (string) $decoded->email,
            'role' => (string) $decoded->role,
        ];
    }

    public function createRefreshToken(): string
    {
        return bin2hex(random_bytes(32));
    }

    public function hashRefreshToken(string $token): string
    {
        return hash('sha256', $token);
    }
}
