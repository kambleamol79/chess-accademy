<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\PuzzleRepository;
use ChessAcademy\Repositories\StudentRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class PuzzleController
{
    use JsonResponse;

    public function __construct(
        private readonly PuzzleRepository $puzzles,
        private readonly StudentRepository $students
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $difficulty = $request->getQueryParams()['difficulty'] ?? null;
        if ($difficulty !== null && in_array($difficulty, ['easy', 'medium', 'hard'], true)) {
            return $this->success($response, $this->puzzles->findByDifficulty($difficulty));
        }

        return $this->success($response, $this->puzzles->findAll());
    }

    public function next(Request $request, Response $response): Response
    {
        $params = $request->getQueryParams();
        $difficulty = (string) ($params['difficulty'] ?? 'easy');
        if (!in_array($difficulty, ['easy', 'medium', 'hard'], true)) {
            return $this->error($response, 'difficulty must be easy, medium, or hard', 422);
        }

        $excludeId = isset($params['exclude']) ? (int) $params['exclude'] : null;
        if ($excludeId !== null && $excludeId <= 0) {
            $excludeId = null;
        }

        $studentId = null;
        $user = $request->getAttribute('user');
        if (is_array($user) && ($user['role'] ?? '') === 'student') {
            $profile = $this->students->findByUserId((int) $user['id']);
            $studentId = $profile ? (int) $profile['id'] : null;
        }

        $puzzle = $this->puzzles->findNextForStudent($difficulty, $studentId, $excludeId);
        if ($puzzle === null) {
            return $this->error($response, 'No puzzles available for this level yet', 404);
        }

        return $this->success($response, ['puzzle' => $puzzle]);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $puzzle = $this->puzzles->findById((int) $args['id']);
        if ($puzzle === null) {
            return $this->error($response, 'Puzzle not found', 404);
        }

        return $this->success($response, $puzzle);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $user = $request->getAttribute('user');
        if (is_array($user)) {
            $body['created_by'] = $user['id'];
        }
        if (empty($body['fen']) || empty($body['solution_moves'])) {
            return $this->error($response, 'fen and solution_moves are required', 422);
        }

        $created = $this->puzzles->create($body);

        return $this->success($response, $created, 'Puzzle created', 201);
    }

    public function attempt(Request $request, Response $response, array $args): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $user = $request->getAttribute('user');
        if (!is_array($user)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $studentId = isset($body['student_id']) ? (int) $body['student_id'] : null;
        if ($studentId === null && $user['role'] === 'student') {
            $profile = $this->students->findByUserId((int) $user['id']);
            $studentId = $profile ? (int) $profile['id'] : null;
        }
        if ($studentId === null && ($user['role'] ?? '') === 'admin') {
            return $this->success($response, ['is_correct' => $isCorrect], 'Attempt recorded (admin preview)');
        }
        if ($studentId === null) {
            return $this->error($response, 'student_id is required', 422);
        }

        $puzzle = $this->puzzles->findById((int) $args['id']);
        if ($puzzle === null) {
            return $this->error($response, 'Puzzle not found', 404);
        }

        $isCorrect = (bool) ($body['is_correct'] ?? false);
        $this->puzzles->recordAttempt((int) $args['id'], $studentId, $isCorrect);

        return $this->success($response, ['is_correct' => $isCorrect], 'Attempt recorded');
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->puzzles->delete((int) $args['id'])) {
            return $this->error($response, 'Puzzle not found', 404);
        }

        return $this->success($response, null, 'Puzzle deleted');
    }
}
