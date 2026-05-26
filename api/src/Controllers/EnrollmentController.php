<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\EnrollmentRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class EnrollmentController
{
    use JsonResponse;

    public function __construct(private readonly EnrollmentRepository $enrollments) {}

    public function index(Request $request, Response $response): Response
    {
        $query = $request->getQueryParams();
        $formId = isset($query['form_id']) ? (int) $query['form_id'] : null;
        $studentId = isset($query['student_id']) ? (int) $query['student_id'] : null;

        return $this->success($response, $this->enrollments->findAll($formId, $studentId));
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        if (empty($body['form_id']) || empty($body['student_id'])) {
            return $this->error($response, 'form_id and student_id are required', 422);
        }

        try {
            $created = $this->enrollments->create($body);
        } catch (\PDOException $e) {
            return $this->error($response, 'Enrollment already exists or invalid references', 422);
        }

        return $this->success($response, $created, 'Enrolled', 201);
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->enrollments->delete((int) $args['id'])) {
            return $this->error($response, 'Enrollment not found', 404);
        }

        return $this->success($response, null, 'Enrollment removed');
    }

    public function bulkAssign(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $formId = (int) ($body['form_id'] ?? 0);
        $studentIds = $body['student_ids'] ?? [];

        if ($formId <= 0) {
            return $this->error($response, 'form_id is required', 422);
        }
        if (!is_array($studentIds) || $studentIds === []) {
            return $this->error($response, 'student_ids must be a non-empty array', 422);
        }

        $result = $this->enrollments->assignBatch($formId, $studentIds);
        $message = sprintf(
            '%d student(s) assigned to batch',
            $result['created']
        );

        return $this->success($response, $result, $message, 201);
    }
}
