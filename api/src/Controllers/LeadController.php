<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\LeadRepository;
use ChessAcademy\Services\LeadCsvParser;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class LeadController
{
    use JsonResponse;

    public function __construct(
        private readonly LeadRepository $leads,
        private readonly LeadCsvParser $csvParser,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        return $this->success($response, $this->leads->findAll());
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $lead = $this->leads->findById((int) $args['id']);
        if ($lead === null) {
            return $this->error($response, 'Lead not found', 404);
        }

        return $this->success($response, $lead);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $user = $request->getAttribute('user');
        if (is_array($user)) {
            $body['updated_by'] = $user['id'];
        }

        $errors = $this->validate($body, true);
        if ($errors !== []) {
            return $this->error($response, 'Validation failed', 422, $errors);
        }

        $created = $this->leads->create($body);

        return $this->success($response, $created, 'Lead created', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $user = $request->getAttribute('user');
        if (is_array($user)) {
            $body['updated_by'] = $user['id'];
        }

        $errors = $this->validate($body, false);
        if ($errors !== []) {
            return $this->error($response, 'Validation failed', 422, $errors);
        }

        $updated = $this->leads->update((int) $args['id'], $body);
        if ($updated === null) {
            return $this->error($response, 'Lead not found', 404);
        }

        return $this->success($response, $updated, 'Lead updated');
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->leads->delete((int) $args['id'])) {
            return $this->error($response, 'Lead not found', 404);
        }

        return $this->success($response, null, 'Lead deleted');
    }

    public function bulk(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $user = $request->getAttribute('user');
        $updatedBy = is_array($user) ? (int) $user['id'] : null;

        $rows = [];
        $parseErrors = [];

        if (isset($body['csv']) && is_string($body['csv']) && trim($body['csv']) !== '') {
            $parsed = $this->csvParser->parse($body['csv']);
            $rows = $parsed['rows'];
            $parseErrors = $parsed['errors'];
        } elseif (isset($body['leads']) && is_array($body['leads'])) {
            $rows = $body['leads'];
        }

        if ($rows === []) {
            return $this->error($response, 'No leads to import. Upload a CSV or send a leads array.', 422);
        }

        $result = $this->leads->createMany($rows, $updatedBy);
        $result['errors'] = array_merge($parseErrors, $result['errors']);
        $result['skipped'] = count($result['errors']);
        $message = sprintf(
            'Imported %d lead(s). %d row(s) skipped.',
            $result['created'],
            $result['skipped']
        );

        return $this->success($response, $result, $message, 201);
    }

    /** @return array<string,string> */
    private function validate(array $body, bool $isCreate): array
    {
        $errors = [];

        if ($isCreate && empty(trim((string) ($body['child_name'] ?? '')))) {
            $errors['child_name'] = 'Child name is required';
        }

        foreach (['q1', 'q2', 'q3'] as $q) {
            if (isset($body[$q]) && $body[$q] !== null && $body[$q] !== '' && !in_array($body[$q], ['Yes', 'No'], true)) {
                $errors[$q] = 'Must be Yes or No';
            }
        }

        return $errors;
    }
}
