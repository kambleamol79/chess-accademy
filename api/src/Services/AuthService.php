<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use ChessAcademy\Repositories\UserRepository;
use PDO;

final class AuthService
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly JwtService $jwt,
        private readonly PDO $pdo,
        private readonly int $refreshTtlDays = 30
    ) {}

    /** @return array{user:array,access_token:string,refresh_token:string}|null */
    public function login(string $email, string $password): ?array
    {
        $user = $this->users->findByEmail($email);
        if ($user === null || !(bool) $user['is_active']) {
            return null;
        }
        if (!password_verify($password, (string) $user['password_hash'])) {
            return null;
        }

        return $this->issueTokens($user);
    }

    /** @param array<string,mixed> $data */
    public function register(array $data): array
    {
        if ($this->users->findByEmail((string) $data['email']) !== null) {
            throw new \InvalidArgumentException('Email already registered');
        }

        $role = (string) ($data['role'] ?? 'student');
        if (!in_array($role, ['admin', 'coach', 'student', 'accountant'], true)) {
            throw new \InvalidArgumentException('Invalid role');
        }
        if ($role === 'admin') {
            throw new \InvalidArgumentException('Cannot register as admin via API');
        }

        $this->pdo->beginTransaction();
        try {
            $userId = $this->users->create([
                'email' => $data['email'],
                'password_hash' => password_hash((string) $data['password'], PASSWORD_BCRYPT),
                'role' => $role,
                'first_name' => $data['first_name'],
                'last_name' => $data['last_name'],
                'phone' => $data['phone'] ?? null,
            ]);

            if ($role === 'coach') {
                $this->users->createCoachProfile($userId, [
                    'title' => $data['title'] ?? null,
                    'bio' => $data['bio'] ?? null,
                    'rating' => $data['rating'] ?? null,
                ]);
            }

            if ($role === 'student') {
                $this->users->createStudentProfile($userId, [
                    'parent_name' => $data['parent_name'] ?? null,
                    'parent_phone' => $data['parent_phone'] ?? null,
                    'date_of_birth' => $data['date_of_birth'] ?? null,
                    'chess_rating' => (int) ($data['chess_rating'] ?? 0),
                ]);
            }

            $this->pdo->commit();
            $user = $this->users->findById($userId);

            return $this->issueTokens($user ?? []);
        } catch (\Throwable $e) {
            $this->pdo->rollBack();
            throw $e;
        }
    }

    /** @return array{user:array,access_token:string,refresh_token:string}|null */
    public function refresh(string $refreshToken): ?array
    {
        $hash = $this->jwt->hashRefreshToken($refreshToken);
        $row = $this->users->findRefreshToken($hash);
        if ($row === null) {
            return null;
        }

        $user = $this->users->findById((int) $row['user_id']);
        if ($user === null || !(bool) $user['is_active']) {
            return null;
        }

        $this->users->deleteRefreshToken($hash);

        return $this->issueTokens($user);
    }

    public function logout(string $refreshToken): void
    {
        $this->users->deleteRefreshToken($this->jwt->hashRefreshToken($refreshToken));
    }

    public function logoutAll(int $userId): void
    {
        $this->users->deleteAllRefreshTokens($userId);
    }

    /** @param array<string,mixed> $user */
    private function issueTokens(array $user): array
    {
        $publicUser = $this->users->toPublic($user);
        $access = $this->jwt->createAccessToken([
            'id' => (int) $user['id'],
            'email' => (string) $user['email'],
            'role' => (string) $user['role'],
        ]);

        $refresh = $this->jwt->createRefreshToken();
        $this->users->storeRefreshToken(
            (int) $user['id'],
            $this->jwt->hashRefreshToken($refresh),
            date('Y-m-d H:i:s', strtotime("+{$this->refreshTtlDays} days"))
        );

        return [
            'user' => $publicUser,
            'access_token' => $access,
            'refresh_token' => $refresh,
        ];
    }
}
