<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\InvoiceRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class BillingController
{
    use JsonResponse;

    public function __construct(private readonly InvoiceRepository $invoices) {}

    public function index(Request $request, Response $response): Response
    {
        $status = $request->getQueryParams()['status'] ?? null;

        return $this->success($response, $this->invoices->findAll(is_string($status) ? $status : null));
    }

    public function show(Request $request, Response $response, array $args): Response
    {
        $invoice = $this->invoices->findById((int) $args['id']);
        if ($invoice === null) {
            return $this->error($response, 'Invoice not found', 404);
        }

        return $this->success($response, $invoice);
    }

    public function store(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        if (empty($body['student_id']) || !isset($body['amount'])) {
            return $this->error($response, 'student_id and amount are required', 422);
        }

        $created = $this->invoices->create($body);

        return $this->success($response, $created, 'Invoice created', 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        $updated = $this->invoices->update((int) $args['id'], $body);
        if ($updated === null) {
            return $this->error($response, 'Invoice not found', 404);
        }

        return $this->success($response, $updated, 'Invoice updated');
    }

    public function pay(Request $request, Response $response, array $args): Response
    {
        $updated = $this->invoices->markPaid((int) $args['id']);
        if ($updated === null) {
            return $this->error($response, 'Invoice not found', 404);
        }

        return $this->success($response, $updated, 'Invoice marked as paid');
    }

    public function destroy(Request $request, Response $response, array $args): Response
    {
        if (!$this->invoices->delete((int) $args['id'])) {
            return $this->error($response, 'Invoice not found', 404);
        }

        return $this->success($response, null, 'Invoice deleted');
    }
}
