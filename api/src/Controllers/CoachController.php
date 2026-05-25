<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Services\AuthService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class CoachController
{
    use JsonResponse;

    public function __construct(
        private readonly CoachRepository $coaches,
        private readonly AuthService $auth
    ) {}

    public function index(Request $request, Response $response): Response
    {
        return $this->success($response, $this->coaches->findAll());
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $coach = $this->coaches->findById((int) $args['id']);
        if ($coach === null) {
            return $this->error($response, 'Coach not found', 404);
        }

        return $this->success($response, $coach);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $body['role'] = 'coach';
        try {
            $result = $this->auth->register($body);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage(), 422);
        }

        $rows = $this->coaches->findAll();
        $created = null;
        foreach ($rows as $row) {
            if ((int) $row['user_id'] === (int) $result['user']['id']) {
                $created = $row;
                break;
            }
        }

        return $this->success($response, $created, 'Coach created', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $updated = $this->coaches->update((int) $args['id'], $body);
        if ($updated === null) {
            return $this->error($response, 'Coach not found', 404);
        }

        return $this->success($response, $updated, 'Coach updated');
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->coaches->delete((int) $args['id'])) {
            return $this->error($response, 'Coach not found', 404);
        }

        return $this->success($response, null, 'Coach deleted');
    }
}
