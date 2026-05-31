<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\ChessLiveMatchRepository;
use ChessAcademy\Repositories\ChessTournamentRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Services\ChessLiveMatchService;
use ChessAcademy\Services\LiveMatchBroadcaster;
use ChessAcademy\Services\LiveMatchVoiceSignaling;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class ChessLiveMatchController
{
    use JsonResponse;

    public function __construct(
        private readonly ChessLiveMatchRepository $matches,
        private readonly ChessTournamentRepository $tournaments,
        private readonly ChessLiveMatchService $live,
        private readonly StudentRepository $students,
        private readonly LiveMatchBroadcaster $broadcaster,
        private readonly LiveMatchVoiceSignaling $voiceSignaling,
    ) {}

    public function myMatches(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $rows = $this->matches->forStudent((int) $student['id']);
        $active = $this->matches->activeForStudent((int) $student['id']);

        return $this->success($response, [
            'matches' => array_map(fn (array $m): array => $this->live->formatMatch($m), $rows),
            'active_match_id' => $active ? (int) $active['id'] : null,
        ]);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->matches->findById((int) $args['id']);
        if ($match === null) {
            return $this->error($response, 'Match not found', 404);
        }

        $sid = (int) $student['id'];
        if ((int) $match['white_student_id'] !== $sid && (int) $match['black_student_id'] !== $sid) {
            return $this->error($response, 'You are not in this match', 403);
        }

        return $this->success($response, $this->live->stateForStudent($match, $sid));
    }

    public function revision(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $matchId = (int) $args['id'];
        $row = $this->matches->revision($matchId);
        if ($row === null) {
            return $this->error($response, 'Match not found', 404);
        }

        $sid = (int) $student['id'];
        if ((int) $row['white_student_id'] !== $sid && (int) $row['black_student_id'] !== $sid) {
            return $this->error($response, 'You are not in this match', 403);
        }

        $since = max(0, (int) ($request->getQueryParams()['since'] ?? 0));
        $seq = (int) ($row['event_seq'] ?? 0);
        $changed = $seq > $since;

        $payload = [
            'event_seq' => $seq,
            'status' => $row['status'],
            'ply_count' => (int) ($row['ply_count'] ?? 0),
            'changed' => $changed,
        ];

        if ($changed) {
            $full = $this->matches->findById($matchId);
            if ($full !== null) {
                $payload['state'] = $this->live->stateForStudent($full, $sid);
            }
        }

        return $this->success($response, $payload);
    }

    public function stream(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->matches->findById((int) $args['id']);
        if ($match === null) {
            return $this->error($response, 'Match not found', 404);
        }

        $sid = (int) $student['id'];
        if ((int) $match['white_student_id'] !== $sid && (int) $match['black_student_id'] !== $sid) {
            return $this->error($response, 'You are not in this match', 403);
        }

        $since = max(0, (int) ($request->getQueryParams()['since'] ?? 0));
        $matchId = (int) $match['id'];

        $response = $response
            ->withHeader('Content-Type', 'text/event-stream')
            ->withHeader('Cache-Control', 'no-cache')
            ->withHeader('Connection', 'keep-alive')
            ->withHeader('X-Accel-Buffering', 'no');

        $body = $response->getBody();
        // Keep connections short — long SSE blocks php -S (single-threaded).
        $deadline = time() + 8;

        while (time() < $deadline) {
            if (connection_aborted()) {
                break;
            }

            $current = $this->matches->findById($matchId);
            if ($current === null) {
                break;
            }

            $seq = (int) ($current['event_seq'] ?? 0);
            if ($seq > $since) {
                $state = $this->live->stateForStudent($current, $sid);
                $payload = json_encode([
                    'event_seq' => $seq,
                    'state' => $state,
                ], JSON_THROW_ON_ERROR);
                $body->write("event: update\ndata: {$payload}\n\n");
                $this->flushSse();
                $since = $seq;

                if (($current['status'] ?? '') === 'completed') {
                    break;
                }
            }

            usleep(150_000);
        }

        $body->write("event: ping\ndata: {}\n\n");
        $this->flushSse();

        return $response;
    }

    public function move(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->matches->findById((int) $args['id']);
        if ($match === null) {
            return $this->error($response, 'Match not found', 404);
        }

        try {
            $state = $this->live->applyMove($match, (int) $student['id'], (array) ($request->getParsedBody() ?? []));
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage(), 422);
        }

        return $this->success($response, $state, 'Move played');
    }

    public function voiceSignals(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->requireMatchParticipant((int) $args['id'], (int) $student['id'], $response);
        if ($match instanceof Response) {
            return $match;
        }

        $since = max(0, (int) ($request->getQueryParams()['since'] ?? 0));
        $signals = $this->voiceSignaling->listForStudent((int) $match['id'], (int) $student['id'], $since);

        return $this->success($response, ['signals' => $signals]);
    }

    public function clearVoiceSignals(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->requireMatchParticipant((int) $args['id'], (int) $student['id'], $response);
        if ($match instanceof Response) {
            return $match;
        }

        $this->voiceSignaling->clear((int) $match['id']);

        return $this->success($response, null, 'Voice signals cleared');
    }

    public function postVoiceSignal(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->requireMatchParticipant((int) $args['id'], (int) $student['id'], $response);
        if ($match instanceof Response) {
            return $match;
        }

        if (($match['status'] ?? '') !== 'active') {
            return $this->error($response, 'Voice chat is only available during an active match', 422);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $type = trim((string) ($body['type'] ?? ''));
        if (!in_array($type, ['offer', 'answer', 'ice'], true)) {
            return $this->error($response, 'Invalid signal type', 422);
        }

        $payload = $body['payload'] ?? $body['data'] ?? null;
        if (!is_array($payload)) {
            return $this->error($response, 'payload object is required', 422);
        }

        $seq = $this->voiceSignaling->append((int) $match['id'], (int) $student['id'], $type, $payload);

        return $this->success($response, ['seq' => $seq], 'Signal stored');
    }

    public function resign(Request $request, Response $response, array $args): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $match = $this->matches->findById((int) $args['id']);
        if ($match === null || $match['status'] !== 'active') {
            return $this->error($response, 'Match not found or not active', 404);
        }

        $sid = (int) $student['id'];
        $result = (int) $match['white_student_id'] === $sid ? 'black_win' : 'white_win';
        $matchId = (int) $args['id'];
        $updated = $this->matches->finish($matchId, $result);
        if ($updated === null) {
            return $this->error($response, 'Could not end match', 500);
        }

        $this->broadcaster->publish($matchId, 'resign');

        return $this->success($response, $this->live->stateForStudent($updated, $sid), 'You resigned');
    }

    public function joinQueue(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $tournamentId = isset($body['tournament_id']) ? (int) $body['tournament_id'] : null;
        if ($tournamentId !== null && $tournamentId > 0) {
            if (!$this->tournaments->isEntered($tournamentId, (int) $student['id'])) {
                return $this->error($response, 'Register for the tournament first', 422);
            }
            $t = $this->tournaments->findById($tournamentId);
            $tc = (int) ($t['time_control_minutes'] ?? 10);
        } else {
            $tournamentId = null;
            $tc = (int) ($body['time_control_minutes'] ?? 10);
        }
        $tc = max(1, min(180, $tc));

        $active = $this->matches->activeForStudent((int) $student['id']);
        if ($active !== null) {
            return $this->success($response, [
                'status' => 'matched',
                'match' => $this->live->formatMatch($active),
                'match_id' => (int) $active['id'],
            ]);
        }

        $opponent = $this->matches->findQueueOpponent((int) $student['id'], $tournamentId);
        if ($opponent !== null) {
            $oppId = (int) $opponent['student_id'];
            $white = (int) $student['id'];
            $black = $oppId;
            if ($white > $black) {
                [$white, $black] = [$black, $white];
            }
            $this->matches->clearQueuePair($white, $black);
            $match = $this->matches->createPair($white, $black, $tournamentId, $tc);
            $this->broadcaster->publish((int) $match['id'], 'matched');

            return $this->success($response, [
                'status' => 'matched',
                'match' => $this->live->formatMatch($match),
                'match_id' => (int) $match['id'],
            ], 'Opponent found');
        }

        $this->matches->joinQueue((int) $student['id'], $tournamentId);

        return $this->success($response, ['status' => 'waiting'], 'Waiting for opponent');
    }

    public function leaveQueue(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $tournamentId = isset($body['tournament_id']) ? (int) $body['tournament_id'] : null;
        if ($tournamentId !== null && $tournamentId <= 0) {
            $tournamentId = null;
        }

        $this->matches->leaveQueue((int) $student['id'], $tournamentId);

        return $this->success($response, null, 'Left matchmaking queue');
    }

    public function queueStatus(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $active = $this->matches->activeForStudent((int) $student['id']);
        if ($active !== null) {
            return $this->success($response, [
                'status' => 'matched',
                'match_id' => (int) $active['id'],
            ]);
        }

        return $this->success($response, ['status' => 'idle']);
    }

    private function flushSse(): void
    {
        if (ob_get_level() > 0) {
            ob_flush();
        }
        flush();
    }

    /** @return array<string,mixed>|Response */
    private function requireMatchParticipant(int $matchId, int $studentId, Response $response): array|Response
    {
        $match = $this->matches->findById($matchId);
        if ($match === null) {
            return $this->error($response, 'Match not found', 404);
        }

        if ((int) $match['white_student_id'] !== $studentId && (int) $match['black_student_id'] !== $studentId) {
            return $this->error($response, 'You are not in this match', 403);
        }

        return $match;
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
