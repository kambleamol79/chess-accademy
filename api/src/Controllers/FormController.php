<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Repositories\FormRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class FormController
{
    public function __construct(
        private readonly FormRepository $forms,
        private readonly CoachRepository $coaches,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $rows = $this->formsForRequest($request);
        $rows = array_map(
            fn (array $row): array => $this->sanitizeFormForClient($row),
            $rows
        );

        return $this->json($response, [
            'success' => true,
            'data' => $rows,
        ]);
    }

    public function nextBatch(Request $request, Response $response): Response
    {
        return $this->json($response, [
            'success' => true,
            'data' => ['batch' => $this->forms->nextBatchCode()],
        ]);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $id = (int) $args['id'];
        $form = $this->forms->findById($id);

        if ($form === null) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Form not found',
            ], 404);
        }

        if (!$this->coachCanAccessForm($request, $id)) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Insufficient permissions',
            ], 403);
        }

        return $this->json($response, ['success' => true, 'data' => $this->sanitizeFormForClient($form)]);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $errors = $this->validate($body, true);

        if ($errors !== []) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $errors,
            ], 422);
        }

        $created = $this->forms->create($body);
        $created = $this->forms->findById((int) $created['id']) ?? $created;

        return $this->json($response, [
            'success' => true,
            'data' => $this->sanitizeFormForClient($created),
            'message' => 'Form created',
        ], 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $id = (int) $args['id'];
        $existing = $this->forms->findById($id);

        if ($existing === null) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Form not found',
            ], 404);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $errors = $this->validate($body, false);

        if ($errors !== []) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $errors,
            ], 422);
        }

        $updated = $this->forms->update($id, $body);

        if ($updated === null) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Form not found',
            ], 404);
        }

        return $this->json($response, [
            'success' => true,
            'data' => $this->sanitizeFormForClient($updated),
            'message' => 'Form updated',
        ]);
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        $id = (int) $args['id'];
        $existing = $this->forms->findById($id);

        if ($existing === null) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Form not found',
            ], 404);
        }

        if (!$this->forms->delete($id)) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Form not found',
            ], 404);
        }

        return $this->json($response, [
            'success' => true,
            'message' => 'Form deleted',
        ]);
    }

    /** @return array<string, string> */
    private function validate(array $body, bool $isCreate): array
    {
        $errors = [];

        if ($isCreate) {
            if (empty($body['batch'])) {
                $errors['batch'] = 'Batch is required';
            }
            if (empty($body['time'])) {
                $errors['time'] = 'Time is required';
            }
            if (empty($body['days_summary'])) {
                $errors['days_summary'] = 'Days summary is required';
            }
            if (empty($body['day_1'])) {
                $errors['day_1'] = 'Day 1 is required';
            }
            if (empty($body['day_2'])) {
                $errors['day_2'] = 'Day 2 is required';
            }
        }

        if (isset($body['highlight']) && !in_array($body['highlight'], ['blue', 'beige'], true)) {
            $errors['highlight'] = 'Highlight must be blue or beige';
        }

        return $errors;
    }

    /** @return list<array<string, mixed>> */
    private function formsForRequest(Request $request): array
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || ($user['role'] ?? '') !== 'coach') {
            return $this->forms->findAll();
        }

        $coach = $this->coaches->findByUserId((int) $user['id']);
        if ($coach === null) {
            return [];
        }

        return $this->coaches->findAssignedForms((int) $coach['id']);
    }

    private function coachCanAccessForm(Request $request, int $formId): bool
    {
        $user = $request->getAttribute('user');
        if (!is_array($user) || ($user['role'] ?? '') !== 'coach') {
            return true;
        }

        $coach = $this->coaches->findByUserId((int) $user['id']);
        if ($coach === null) {
            return false;
        }

        return $this->coaches->isAssignedToForm((int) $coach['id'], $formId);
    }

    /** @param array<string, mixed> $form */
    private function sanitizeFormForClient(array $form): array
    {
        unset($form['zoom_meeting_id'], $form['zoom_start_url']);

        return $form;
    }

    private function json(Response $response, array $payload, int $status = 200): Response
    {
        $response->getBody()->write((string) json_encode($payload, JSON_THROW_ON_ERROR));

        return $response
            ->withHeader('Content-Type', 'application/json')
            ->withStatus($status);
    }
}
