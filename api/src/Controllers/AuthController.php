<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\UserRepository;
use ChessAcademy\Services\AuthService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class AuthController
{
    use JsonResponse;

    public function __construct(
        private readonly AuthService $auth,
        private readonly UserRepository $users
    ) {}

    public function login(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $email = trim((string) ($body['email'] ?? ''));
        $password = (string) ($body['password'] ?? '');

        if ($email === '' || $password === '') {
            return $this->error($response, 'Email and password are required', 422);
        }

        $result = $this->auth->login($email, $password);
        if ($result === null) {
            return $this->error($response, 'Invalid credentials', 401);
        }

        return $this->success($response, $result);
    }

    public function register(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $errors = $this->validateRegister($body);
        if ($errors !== []) {
            return $this->error($response, 'Validation failed', 422, $errors);
        }

        if (($body['role'] ?? 'student') === 'admin') {
            return $this->error($response, 'Cannot self-register as admin', 422);
        }

        try {
            $result = $this->auth->register($body);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage(), 422);
        }

        return $this->success($response, $result, 'Registered successfully', 201);
    }

    public function refresh(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $token = (string) ($body['refresh_token'] ?? '');
        if ($token === '') {
            return $this->error($response, 'refresh_token is required', 422);
        }

        $result = $this->auth->refresh($token);
        if ($result === null) {
            return $this->error($response, 'Invalid or expired refresh token', 401);
        }

        return $this->success($response, $result);
    }

    public function logout(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $token = (string) ($body['refresh_token'] ?? '');
        if ($token !== '') {
            $this->auth->logout($token);
        }

        return $this->success($response, null, 'Logged out');
    }

    public function me(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $user = $this->users->findWithProfile((int) $authUser['id']);
        if ($user === null) {
            return $this->error($response, 'User not found', 404);
        }

        return $this->success($response, $user);
    }

    /** @return array<string,string> */
    private function validateRegister(array $body): array
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

        return $errors;
    }
}
