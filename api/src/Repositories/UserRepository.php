<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class UserRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return array<string,mixed>|null */
    public function findByEmail(string $email): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM users WHERE email = :email LIMIT 1');
        $stmt->execute(['email' => strtolower(trim($email))]);

        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM users WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): int
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO users (email, password_hash, role, first_name, last_name, phone)
             VALUES (:email, :password_hash, :role, :first_name, :last_name, :phone)'
        );
        $stmt->execute([
            'email' => strtolower(trim((string) $data['email'])),
            'password_hash' => $data['password_hash'],
            'role' => $data['role'],
            'first_name' => $data['first_name'],
            'last_name' => $data['last_name'],
            'phone' => $data['phone'] ?? null,
        ]);

        return (int) $this->pdo->lastInsertId();
    }

    /** @param array<string,mixed> $data */
    public function createCoachProfile(int $userId, array $data): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO coaches (user_id, title, bio, rating) VALUES (:user_id, :title, :bio, :rating)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'title' => $data['title'] ?? null,
            'bio' => $data['bio'] ?? null,
            'rating' => $data['rating'] ?? null,
        ]);
    }

    /** @param array<string,mixed> $data */
    public function createStudentProfile(int $userId, array $data): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO students (user_id, parent_name, parent_phone, date_of_birth, chess_rating)
             VALUES (:user_id, :parent_name, :parent_phone, :date_of_birth, :chess_rating)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'parent_name' => $data['parent_name'] ?? null,
            'parent_phone' => $data['parent_phone'] ?? null,
            'date_of_birth' => $data['date_of_birth'] ?? null,
            'chess_rating' => (int) ($data['chess_rating'] ?? 0),
        ]);
    }

    public function storeRefreshToken(int $userId, string $hash, string $expiresAt): void
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (:user_id, :token_hash, :expires_at)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'token_hash' => $hash,
            'expires_at' => $expiresAt,
        ]);
    }

    /** @return array<string,mixed>|null */
    public function findRefreshToken(string $hash): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM refresh_tokens WHERE token_hash = :hash AND expires_at > NOW() LIMIT 1'
        );
        $stmt->execute(['hash' => $hash]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    public function deleteRefreshToken(string $hash): void
    {
        $stmt = $this->pdo->prepare('DELETE FROM refresh_tokens WHERE token_hash = :hash');
        $stmt->execute(['hash' => $hash]);
    }

    public function deleteAllRefreshTokens(int $userId): void
    {
        $stmt = $this->pdo->prepare('DELETE FROM refresh_tokens WHERE user_id = :user_id');
        $stmt->execute(['user_id' => $userId]);
    }

    /** @param array<string,mixed> $user */
    public function toPublic(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'email' => $user['email'],
            'role' => $user['role'],
            'first_name' => $user['first_name'],
            'last_name' => $user['last_name'],
            'phone' => $user['phone'],
            'is_active' => (bool) $user['is_active'],
            'created_at' => $user['created_at'],
        ];
    }

    /** @return array<string,mixed>|null */
    public function findWithProfile(int $id): ?array
    {
        $user = $this->findById($id);
        if ($user === null) {
            return null;
        }

        $public = $this->toPublic($user);

        if ($user['role'] === 'coach') {
            $stmt = $this->pdo->prepare('SELECT * FROM coaches WHERE user_id = :id');
            $stmt->execute(['id' => $id]);
            $public['coach'] = $stmt->fetch() ?: null;
        }

        if ($user['role'] === 'student') {
            $stmt = $this->pdo->prepare('SELECT * FROM students WHERE user_id = :id');
            $stmt->execute(['id' => $id]);
            $public['student'] = $stmt->fetch() ?: null;
        }

        return $public;
    }
}
