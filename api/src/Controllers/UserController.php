<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\UserRepository;
use ChessAcademy\Services\AuthService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class UserController
{
    use JsonResponse;

    public function __construct(
        private readonly UserRepository $users,
        private readonly AuthService $auth,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        return $this->success($response, $this->users->findStaffUsers());
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $errors = $this->validateCreate($body);
        if ($errors !== []) {
            return $this->error($response, 'Validation failed', 422, $errors);
        }

        try {
            $result = $this->auth->createStaffUser($body);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage(), 422);
        }

        return $this->success($response, $result['user'], 'Staff account created', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $id = (int) $args['id'];
        $user = $this->users->findById($id);
        if ($user === null) {
            return $this->error($response, 'User not found', 404);
        }

        if (!$this->users->isStaffRole((string) $user['role'])) {
            return $this->error($response, 'Only staff accounts can be updated here', 422);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $password = isset($body['password']) ? trim((string) $body['password']) : '';
        if ($password === '') {
            return $this->error($response, 'password is required', 422, [
                'password' => 'Password must be at least 8 characters',
            ]);
        }
        if (strlen($password) < 8) {
            return $this->error($response, 'Password must be at least 8 characters', 422, [
                'password' => 'Password must be at least 8 characters',
            ]);
        }

        if (!$this->users->updatePassword($id, password_hash($password, PASSWORD_BCRYPT))) {
            return $this->error($response, 'User not found', 404);
        }

        $this->auth->logoutAll($id);

        $updated = $this->users->findById($id);

        return $this->success(
            $response,
            $updated !== null ? $this->users->toPublic($updated) : null,
            'Password updated'
        );
    }

    /** @return array<string, string> */
    private function validateCreate(array $body): array
    {
        $errors = [];
        if (empty($body['email'])) {
            $errors['email'] = 'Email is required';
        }
        if (empty($body['password']) || strlen((string) $body['password']) < 8) {
            $errors['password'] = 'Password must be at least 8 characters';
        }
        if (empty($body['first_name'])) {
            $errors['first_name'] = 'First name is required';
        }
        if (empty($body['last_name'])) {
            $errors['last_name'] = 'Last name is required';
        }
        $role = (string) ($body['role'] ?? '');
        if (!in_array($role, ['admin', 'coach', 'accountant'], true)) {
            $errors['role'] = 'Role must be admin, coach, or accountant';
        }

        return $errors;
    }
}
