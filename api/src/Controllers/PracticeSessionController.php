<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\PracticeSessionRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class PracticeSessionController
{
    use JsonResponse;

    public function __construct(private readonly PracticeSessionRepository $sessions) {}

    public function index(Request $request, Response $response): Response
    {
        $userId = $this->userId($request, $response);
        if ($userId instanceof Response) {
            return $userId;
        }

        $params = $request->getQueryParams();
        $limit = isset($params['limit']) ? (int) $params['limit'] : 30;
        $offset = isset($params['offset']) ? (int) $params['offset'] : 0;

        $rows = $this->sessions->listForUser($userId, $limit, $offset);

        return $this->success($response, [
            'sessions' => array_map(
                fn (array $row): array => $this->sessions->formatSession($row),
                $rows
            ),
        ]);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $userId = $this->userId($request, $response);
        if ($userId instanceof Response) {
            return $userId;
        }

        $session = $this->sessions->findByIdForUser((int) $args['id'], $userId);
        if ($session === null) {
            return $this->error($response, 'Practice session not found', 404);
        }

        return $this->success($response, $this->sessions->formatSessionWithMoves($session));
    }

    public function store(Request $request, Response $response): Response
    {
        $userId = $this->userId($request, $response);
        if ($userId instanceof Response) {
            return $userId;
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $mode = $body['mode'] ?? 'vs_computer';
        if (!in_array($mode, ['vs_computer', 'free_play', 'vsComputer', 'freePlay'], true)) {
            return $this->error($response, 'Invalid mode', 422);
        }
        $mode = $mode === 'vsComputer' || $mode === 'vs_computer' ? 'vs_computer' : 'free_play';

        $playerColor = $body['player_color'] ?? $body['playerColor'] ?? 'white';
        if (!in_array($playerColor, ['white', 'black'], true)) {
            return $this->error($response, 'player_color must be white or black', 422);
        }

        $startFen = trim((string) ($body['start_fen'] ?? $body['startFen'] ?? ''));
        if ($startFen === '') {
            return $this->error($response, 'start_fen is required', 422);
        }

        $timeControl = (int) ($body['time_control_minutes'] ?? $body['timeControlMinutes'] ?? 10);
        if ($timeControl < 1 || $timeControl > 180) {
            return $this->error($response, 'time_control_minutes must be between 1 and 180', 422);
        }

        $level = $body['level'] ?? null;
        if ($level !== null) {
            $level = (string) $level;
        }

        $created = $this->sessions->create($userId, [
            'mode' => $mode,
            'level' => $level,
            'player_color' => $playerColor,
            'time_control_minutes' => $timeControl,
            'start_fen' => $startFen,
        ]);

        return $this->success($response, ['session' => $this->sessions->formatSession($created)], 'Session started', 201);
    }

    public function addMove(Request $request, Response $response, array $args): Response
    {
        $userId = $this->userId($request, $response);
        if ($userId instanceof Response) {
            return $userId;
        }

        $body = (array) ($request->getParsedBody() ?? []);
        foreach (['ply', 'san', 'uci', 'color', 'player', 'fen_after'] as $field) {
            if (!isset($body[$field]) && !isset($body[$this->camel($field)])) {
                return $this->error($response, "{$field} is required", 422);
            }
        }

        $color = (string) ($body['color'] ?? '');
        if (!in_array($color, ['w', 'b'], true)) {
            return $this->error($response, 'color must be w or b', 422);
        }

        $player = (string) ($body['player'] ?? '');
        if (!in_array($player, ['human', 'opponent'], true)) {
            return $this->error($response, 'player must be human or opponent', 422);
        }

        $move = $this->sessions->addMove((int) $args['id'], $userId, [
            'ply' => (int) ($body['ply'] ?? 0),
            'san' => (string) ($body['san'] ?? ''),
            'uci' => (string) ($body['uci'] ?? ''),
            'color' => $color,
            'player' => $player,
            'fen_after' => (string) ($body['fen_after'] ?? $body['fenAfter'] ?? ''),
        ]);

        if ($move === null) {
            return $this->error($response, 'Practice session not found', 404);
        }

        return $this->success($response, ['move' => $this->sessions->formatMove($move)], 'Move saved', 201);
    }

    public function deleteLastMove(Request $request, Response $response, array $args): Response
    {
        $userId = $this->userId($request, $response);
        if ($userId instanceof Response) {
            return $userId;
        }

        if (!$this->sessions->deleteLastMove((int) $args['id'], $userId)) {
            return $this->error($response, 'No move to remove or session not found', 404);
        }

        return $this->success($response, null, 'Last move removed');
    }

    public function finalize(Request $request, Response $response, array $args): Response
    {
        $userId = $this->userId($request, $response);
        if ($userId instanceof Response) {
            return $userId;
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $result = (string) ($body['result'] ?? 'ended');
        $allowed = ['ongoing', 'win', 'loss', 'draw', 'ended', 'timeout_win', 'timeout_loss'];
        if (!in_array($result, $allowed, true)) {
            return $this->error($response, 'Invalid result', 422);
        }

        $updated = $this->sessions->finalize((int) $args['id'], $userId, ['result' => $result]);
        if ($updated === null) {
            return $this->error($response, 'Practice session not found', 404);
        }

        return $this->success($response, ['session' => $this->sessions->formatSession($updated)], 'Session saved');
    }

    private function camel(string $snake): string
    {
        return lcfirst(str_replace('_', '', ucwords($snake, '_')));
    }

    private function userId(Request $request, Response $response): int|Response
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || empty($user['id'])) {
            return $this->error($response, 'Unauthorized', 401);
        }

        return (int) $user['id'];
    }
}
