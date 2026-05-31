<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Services\StudentPortalService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class StudentPortalController
{
    use JsonResponse;

    public function __construct(
        private readonly StudentRepository $students,
        private readonly StudentPortalService $portal,
    ) {}

    public function myBatch(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $batch = $this->portal->activeBatch((int) $student['id']);

        return $this->success($response, ['batch' => $batch]);
    }

    public function myPayments(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        return $this->success($response, $this->portal->paymentHistory((int) $student['id'], $student));
    }

    public function myReminders(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        return $this->success($response, ['reminders' => $this->portal->reminders((int) $student['id'], $student)]);
    }

    public function myNotifications(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        return $this->success($response, ['notifications' => $this->portal->notifications((int) $student['id'], $student)]);
    }

    /** @return array<string,mixed>|Response */
    private function requireStudent(Request $request, Response $response): array|Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        if (($authUser['role'] ?? '') !== 'student') {
            return $this->error($response, 'Student access only', 403);
        }

        $student = $this->students->findByUserId((int) $authUser['id']);
        if ($student === null) {
            return $this->error($response, 'Student profile not found', 404);
        }

        return $student;
    }
}
