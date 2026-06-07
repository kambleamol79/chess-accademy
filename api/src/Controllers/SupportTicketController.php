<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Repositories\SupportTicketRepository;
use ChessAcademy\Services\MessagingService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class SupportTicketController
{
    use JsonResponse;

    public function __construct(
        private readonly SupportTicketRepository $tickets,
        private readonly StudentRepository $students,
        private readonly MessagingService $messaging,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser) || ($authUser['role'] ?? '') !== 'admin') {
            return $this->error($response, 'Admin access only', 403);
        }

        $query = $request->getQueryParams();
        $status = isset($query['status']) && is_string($query['status']) ? $query['status'] : null;

        return $this->success($response, ['tickets' => $this->tickets->findAll($status)]);
    }

    public function myTickets(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        return $this->success($response, ['tickets' => $this->tickets->findByStudent((int) $student['id'])]);
    }

    public function storeMine(Request $request, Response $response): Response
    {
        $student = $this->requireStudent($request, $response);
        if ($student instanceof Response) {
            return $student;
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $subject = trim((string) ($body['subject'] ?? ''));
        $message = trim((string) ($body['body'] ?? $body['message'] ?? ''));

        if ($subject === '') {
            return $this->error($response, 'Subject is required', 422);
        }
        if ($message === '') {
            return $this->error($response, 'Message is required', 422);
        }

        $authUser = $request->getAttribute('user');
        $ticket = $this->tickets->create([
            'student_id' => (int) $student['id'],
            'subject' => $subject,
        ]);
        $ticketMessage = $this->tickets->addMessage(
            (int) $ticket['id'],
            (int) $authUser['id'],
            $message
        );

        return $this->success($response, [
            'ticket' => $this->tickets->findById((int) $ticket['id']),
            'message' => $ticketMessage,
        ], 'Support request submitted', 201);
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $ticketId = (int) ($args['id'] ?? 0);
        if ($ticketId <= 0) {
            return $this->error($response, 'Invalid ticket id', 400);
        }

        if (!$this->messaging->canAccessTicket($authUser, $ticketId)) {
            return $this->error($response, 'Ticket not found', 404);
        }

        $ticket = $this->tickets->findById($ticketId);
        if ($ticket === null) {
            return $this->error($response, 'Ticket not found', 404);
        }

        return $this->success($response, [
            'ticket' => $ticket,
            'messages' => $this->tickets->messagesForTicket($ticketId),
        ]);
    }

    public function addMessage(Request $request, Response $response, array $args): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $ticketId = (int) ($args['id'] ?? 0);
        if ($ticketId <= 0) {
            return $this->error($response, 'Invalid ticket id', 400);
        }

        if (!$this->messaging->canAccessTicket($authUser, $ticketId)) {
            return $this->error($response, 'Ticket not found', 404);
        }

        $ticket = $this->tickets->findById($ticketId);
        if ($ticket === null) {
            return $this->error($response, 'Ticket not found', 404);
        }

        if (($ticket['status'] ?? '') === 'resolved') {
            return $this->error($response, 'This ticket is resolved and cannot receive new messages', 409);
        }

        $role = (string) ($authUser['role'] ?? '');
        if ($role !== 'admin' && $role !== 'student') {
            return $this->error($response, 'Not allowed to reply on this ticket', 403);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $message = trim((string) ($body['body'] ?? $body['message'] ?? ''));
        if ($message === '') {
            return $this->error($response, 'Message is required', 422);
        }

        $ticketMessage = $this->tickets->addMessage($ticketId, (int) $authUser['id'], $message);

        return $this->success($response, ['message' => $ticketMessage], 'Message sent', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser) || ($authUser['role'] ?? '') !== 'admin') {
            return $this->error($response, 'Admin access only', 403);
        }

        $ticketId = (int) ($args['id'] ?? 0);
        if ($ticketId <= 0) {
            return $this->error($response, 'Invalid ticket id', 400);
        }

        $ticket = $this->tickets->findById($ticketId);
        if ($ticket === null) {
            return $this->error($response, 'Ticket not found', 404);
        }

        $body = (array) ($request->getParsedBody() ?? []);
        $updates = [];

        if (!empty($body['assign_self'])) {
            $updates['assigned_to_user_id'] = (int) $authUser['id'];
        }

        if (isset($body['status']) && (string) $body['status'] === 'resolved') {
            $resolutionComment = trim((string) ($body['resolution_comment'] ?? ''));
            if ($resolutionComment === '') {
                return $this->error($response, 'Resolution comment is required when resolving a ticket', 422);
            }
            $updates['status'] = 'resolved';
            $updates['resolution_comment'] = $resolutionComment;
            if (!isset($updates['assigned_to_user_id']) && empty($ticket['assigned_to_user_id'])) {
                $updates['assigned_to_user_id'] = (int) $authUser['id'];
            }
        }

        if ($updates === []) {
            return $this->error($response, 'No valid updates provided', 422);
        }

        $updated = $this->tickets->update($ticketId, $updates);

        return $this->success($response, ['ticket' => $updated], 'Ticket updated');
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
