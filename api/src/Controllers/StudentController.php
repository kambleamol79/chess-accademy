<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Repositories\UserRepository;
use ChessAcademy\Services\AuthService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class StudentController
{
    use JsonResponse;

    public function __construct(
        private readonly StudentRepository $students,
        private readonly UserRepository $users,
        private readonly AuthService $auth
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $user = $request->getAttribute('user');
        if (is_array($user) && $user['role'] === 'student') {
            $profile = $this->students->findByUserId((int) $user['id']);
            if ($profile === null) {
                return $this->success($response, []);
            }
            $full = $this->students->findById((int) $profile['id']);

            return $this->success($response, $full ? [$full] : []);
        }

        return $this->success($response, $this->students->findAll());
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $student = $this->students->findById((int) $args['id']);
        if ($student === null) {
            return $this->error($response, 'Student not found', 404);
        }

        return $this->success($response, $student);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $body['role'] = 'student';
        try {
            $result = $this->auth->register($body);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage(), 422);
        }

        $profile = $this->students->findByUserId((int) $result['user']['id']);
        if ($profile !== null) {
            $updated = $this->students->update((int) $profile['id'], $body);
            if ($updated !== null) {
                $profile = $updated;
            }
        }

        return $this->success($response, $profile, 'Student created', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);

        if (isset($body['password']) && (string) $body['password'] !== '') {
            if (strlen((string) $body['password']) < 8) {
                return $this->error($response, 'Password must be at least 8 characters', 422, [
                    'password' => 'Password must be at least 8 characters',
                ]);
            }
        } else {
            unset($body['password']);
        }

        if (isset($body['email']) && $body['email'] !== '') {
            $student = $this->students->findById((int) $args['id']);
            if ($student !== null) {
                $existing = $this->users->findByEmail((string) $body['email']);
                if ($existing !== null && (int) $existing['id'] !== (int) $student['user_id']) {
                    return $this->error($response, 'Email already in use', 422, [
                        'email' => 'Email already in use',
                    ]);
                }
            }
        }

        $updated = $this->students->update((int) $args['id'], $body);
        if ($updated === null) {
            return $this->error($response, 'Student not found', 404);
        }

        return $this->success($response, $updated, 'Student updated');
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->students->delete((int) $args['id'])) {
            return $this->error($response, 'Student not found', 404);
        }

        return $this->success($response, null, 'Student deleted');
    }
}
