<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Repositories\GameRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Services\PgnValidator;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class GameController
{
    use JsonResponse;

    public function __construct(
        private readonly GameRepository $games,
        private readonly StudentRepository $students,
        private readonly CoachRepository $coaches,
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
        $user = $request->getAttribute('user');
        if (!is_array($user)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $pgn = trim((string) ($body['pgn'] ?? ''));
        if ($pgn === '') {
            return $this->error($response, 'pgn is required', 422);
        }

        if (!PgnValidator::isValid($pgn)) {
            return $this->error($response, 'Invalid PGN. Include standard headers or move text (e.g. 1. e4 e5).', 422);
        }

        $role = (string) ($user['role'] ?? '');
        $studentId = isset($body['student_id']) ? (int) $body['student_id'] : 0;

        if ($role === 'student') {
            $profile = $this->students->findByUserId((int) $user['id']);
            if ($profile === null) {
                return $this->error($response, 'Student profile not found', 404);
            }
            $studentId = (int) $profile['id'];
        } elseif (!in_array($role, ['admin', 'coach'], true)) {
            return $this->error($response, 'Insufficient permissions', 403);
        } elseif ($studentId <= 0) {
            return $this->error($response, 'student_id is required', 422);
        }

        if ($this->students->findById($studentId) === null) {
            return $this->error($response, 'Student not found', 404);
        }

        $title = trim((string) ($body['title'] ?? ''));
        if ($title === '') {
            $title = PgnValidator::suggestTitle($pgn) ?? null;
        }

        $coachId = null;
        if ($role === 'coach') {
            $coach = $this->coaches->findByUserId((int) $user['id']);
            $coachId = $coach ? (int) $coach['id'] : null;
        } elseif (isset($body['coach_id']) && $body['coach_id'] !== '') {
            $coachId = (int) $body['coach_id'];
        }

        $created = $this->games->create([
            'student_id' => $studentId,
            'coach_id' => $coachId,
            'title' => $title !== '' ? $title : null,
            'pgn' => $pgn,
            'notes' => isset($body['notes']) ? trim((string) $body['notes']) : null,
        ]);

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
