<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\MaterialRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class MaterialController
{
    use JsonResponse;

    public function __construct(private readonly MaterialRepository $materials) {}

    public function index(Request $request, Response $response): Response
    {
        $formId = isset($request->getQueryParams()['form_id'])
            ? (int) $request->getQueryParams()['form_id']
            : null;

        return $this->success($response, $this->materials->findAll($formId));
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $user = $request->getAttribute('user');
        if (is_array($user)) {
            $body['uploaded_by'] = $user['id'];
        }
        if (empty($body['form_id']) || empty($body['title']) || empty($body['url'])) {
            return $this->error($response, 'form_id, title, and url are required', 422);
        }

        $created = $this->materials->create($body);

        return $this->success($response, $created, 'Material created', 201);
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->materials->delete((int) $args['id'])) {
            return $this->error($response, 'Material not found', 404);
        }

        return $this->success($response, null, 'Material deleted');
    }
}
