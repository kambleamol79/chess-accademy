<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\BatchMessageRepository;
use ChessAcademy\Repositories\EnrollmentRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Services\MessagingService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class BatchMessageController
{
    use JsonResponse;

    public function __construct(
        private readonly BatchMessageRepository $messages,
        private readonly MessagingService $messaging,
        private readonly StudentRepository $students,
        private readonly EnrollmentRepository $enrollments,
    ) {}

    public function index(Request $request, Response $response, array $args): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $formId = (int) ($args['form_id'] ?? 0);
        if ($formId <= 0) {
            return $this->error($response, 'Invalid batch id', 400);
        }

        if (!$this->messaging->canAccessBatchMessages($authUser, $formId)) {
            return $this->error($response, 'Batch not found or access denied', 404);
        }

        return $this->success($response, ['messages' => $this->messages->findByForm($formId)]);
    }

    public function store(Request $request, Response $response, array $args): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $formId = (int) ($args['form_id'] ?? 0);
        if ($formId <= 0) {
            return $this->error($response, 'Invalid batch id', 400);
        }

        if (!$this->messaging->canSendBatchMessage($authUser, $formId)) {
            return $this->error($response, 'Only admins can send batch messages', 403);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $message = trim((string) ($body['body'] ?? $body['message'] ?? ''));
        if ($message === '') {
            return $this->error($response, 'Message is required', 422);
        }

        $created = $this->messages->create($formId, (int) $authUser['id'], $message);

        return $this->success($response, ['message' => $created], 'Batch message sent', 201);
    }

    public function myBatchMessages(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser) || ($authUser['role'] ?? '') !== 'student') {
            return $this->error($response, 'Student access only', 403);
        }

        $student = $this->students->findByUserId((int) $authUser['id']);
        if ($student === null) {
            return $this->error($response, 'Student profile not found', 404);
        }

        $enrollment = $this->enrollments->findActiveByStudent((int) $student['id']);
        if ($enrollment === null) {
            return $this->success($response, ['messages' => [], 'form_id' => null]);
        }

        $formId = (int) $enrollment['form_id'];

        return $this->success($response, [
            'form_id' => $formId,
            'messages' => $this->messages->findByForm($formId),
        ]);
    }
}
