<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\GameRepository;
use ChessAcademy\Repositories\StudentRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class GameController
{
    use JsonResponse;

    public function __construct(
        private readonly GameRepository $games,
        private readonly StudentRepository $students
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $user = $request->getAttribute('user');
        $studentId = isset($request->getQueryParams()['student_id'])
            ? (int) $request->getQueryParams()['student_id']
            : null;

        if ($studentId === null && is_array($user) && $user['role'] === 'student') {
            $profile = $this->students->findByUserId((int) $user['id']);
            $studentId = $profile ? (int) $profile['id'] : null;
        }

        return $this->success($response, $this->games->findAll($studentId));
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $game = $this->games->findById((int) $args['id']);
        if ($game === null) {
            return $this->error($response, 'Game not found', 404);
        }

        return $this->success($response, $game);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        if (empty($body['student_id']) || empty($body['pgn'])) {
            return $this->error($response, 'student_id and pgn are required', 422);
        }

        $created = $this->games->create($body);

        return $this->success($response, $created, 'Game saved', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $updated = $this->games->update((int) $args['id'], $body);
        if ($updated === null) {
            return $this->error($response, 'Game not found', 404);
        }

        return $this->success($response, $updated, 'Game updated');
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->games->delete((int) $args['id'])) {
            return $this->error($response, 'Game not found', 404);
        }

        return $this->success($response, null, 'Game deleted');
    }
}
