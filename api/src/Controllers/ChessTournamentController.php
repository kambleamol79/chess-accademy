<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\ChessLiveMatchRepository;
use ChessAcademy\Repositories\ChessTournamentRepository;
use ChessAcademy\Repositories\StudentRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class ChessTournamentController
{
    use JsonResponse;

    public function __construct(
        private readonly ChessTournamentRepository $tournaments,
        private readonly ChessLiveMatchRepository $matches,
        private readonly StudentRepository $students,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $status = $request->getQueryParams()['status'] ?? null;

        return $this->success($response, [
            'tournaments' => $this->tournaments->list(is_string($status) ? $status : null),
        ]);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $tournament = $this->tournaments->findById((int) $args['id']);
        if ($tournament === null) {
            return $this->error($response, 'Tournament not found', 404);
        }

        return $this->success($response, [
            'tournament' => $tournament,
            'entries' => $this->tournaments->entries((int) $args['id']),
        ]);
    }

    public function store(Request $request, Response $response): Response
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || ($user['role'] ?? '') !== 'admin') {
            return $this->error($response, 'Admin only', 403);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $title = trim((string) ($body['title'] ?? ''));
        $startsAt = trim((string) ($body['starts_at'] ?? $body['startsAt'] ?? ''));
        if ($title === '' || $startsAt === '') {
            return $this->error($response, 'title and starts_at are required', 422);
        }

        $tc = (int) ($body['time_control_minutes'] ?? $body['timeControlMinutes'] ?? 10);
        if ($tc < 1 || $tc > 180) {
            return $this->error($response, 'time_control_minutes must be 1–180', 422);
        }

        $created = $this->tournaments->create([
            'title' => $title,
            'description' => $body['description'] ?? null,
            'starts_at' => $startsAt,
            'time_control_minutes' => $tc,
            'status' => $body['status'] ?? 'registration',
            'created_by' => (int) $user['id'],
        ]);

        return $this->success($response, ['tournament' => $created], 'Tournament created', 201);
    }

    public function updateStatus(Request $request, Response $response, array $args): Response
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || ($user['role'] ?? '') !== 'admin') {
            return $this->error($response, 'Admin only', 403);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $status = (string) ($body['status'] ?? '');
        $allowed = ['scheduled', 'registration', 'active', 'finished', 'cancelled'];
        if (!in_array($status, $allowed, true)) {
            return $this->error($response, 'Invalid status', 422);
        }

        $updated = $this->tournaments->updateStatus((int) $args['id'], $status);
        if ($updated === null) {
            return $this->error($response, 'Tournament not found', 404);
        }

        return $this->success($response, ['tournament' => $updated], 'Tournament updated');
    }

    public function startRound(Request $request, Response $response, array $args): Response
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || ($user['role'] ?? '') !== 'admin') {
            return $this->error($response, 'Admin only', 403);
        }

        $tournament = $this->tournaments->findById((int) $args['id']);
        if ($tournament === null) {
            return $this->error($response, 'Tournament not found', 404);
        }

        $tc = (int) $tournament['time_control_minutes'];
        $pairings = $this->matches->createRoundRobinPairings((int) $args['id'], $tc);
        $this->tournaments->updateStatus((int) $args['id'], 'active');

        return $this->success($response, [
            'match_count' => count($pairings),
            'matches' => $pairings,
        ], 'Round started');
    }

    public function register(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $tournament = $this->tournaments->findById((int) $args['id']);
        if ($tournament === null) {
            return $this->error($response, 'Tournament not found', 404);
        }

        if (!in_array($tournament['status'], ['scheduled', 'registration', 'active'], true)) {
            return $this->error($response, 'Registration is closed', 422);
        }

        $this->tournaments->addEntry((int) $args['id'], (int) $student['id']);

        return $this->success($response, null, 'Registered for tournament');
    }

    /** @return array<string,mixed>|Response */
    private function requireStudent(Request $request, Response $response): array|Response
    {
        $user = $request->getAttribute('user');
        if (!is_array($user)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        if (($user['role'] ?? '') !== 'student') {
            return $this->error($response, 'Student access only', 403);
        }

        $student = $this->students->findByUserId((int) $user['id']);
        if ($student === null) {
            return $this->error($response, 'Student profile not found', 404);
        }

        return $student;
    }
}
