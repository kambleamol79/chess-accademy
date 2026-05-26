<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\LeadRepository;
use ChessAcademy\Repositories\StudentRepository;
use ChessAcademy\Services\LeadConversionService;
use ChessAcademy\Services\LeadCsvParser;
use ChessAcademy\Services\PaymentReceiptUploadService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class LeadController
{
    use JsonResponse;

    public function __construct(
        private readonly LeadRepository $leads,
        private readonly LeadCsvParser $csvParser,
        private readonly LeadConversionService $conversion,
        private readonly PaymentReceiptUploadService $receiptUploads,
        private readonly StudentRepository $students,
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

        if (isset($body['paid']) && strtoupper((string) $body['paid']) === 'PAID') {
            return $this->error(
                $response,
                'Upload a payment receipt using Mark as paid (paid checkbox + receipt file).',
                422
            );
        }

        $updated = $this->leads->update((int) $args['id'], $body);
        if ($updated === null) {
            return $this->error($response, 'Lead not found', 404);
        }

        return $this->success($response, $updated, 'Lead updated');
    }

    public function markPaid(Request $request, Response $response, array $args): Response
    {
        $leadId = (int) $args['id'];
        $lead = $this->leads->findById($leadId);
        if ($lead === null) {
            return $this->error($response, 'Lead not found', 404);
        }

        $uploaded = $request->getUploadedFiles()['payment_receipt'] ?? null;
        if ($uploaded === null) {
            return $this->error($response, 'Payment receipt file is required', 422);
        }

        $parsed = $this->parseLeadBody($request);
        if (isset($parsed['errors'])) {
            return $this->error($response, 'Validation failed', 422, $parsed['errors']);
        }

        $body = $parsed['body'];
        $user = $request->getAttribute('user');
        if (is_array($user)) {
            $body['updated_by'] = $user['id'];
        }
        $body['paid'] = 'PAID';

        try {
            $storedName = $this->receiptUploads->store($uploaded);
            $result = $this->conversion->convert($leadId, $body, $storedName);
        } catch (\InvalidArgumentException $e) {
            return $this->error($response, $e->getMessage(), 422);
        } catch (\PDOException $e) {
            if (str_contains($e->getMessage(), 'payment_receipt_path')
                || str_contains($e->getMessage(), 'source_lead_id')) {
                return $this->error(
                    $response,
                    'Database is missing payment columns. Run: mysql ... chess_academy < api/database/leads_payment_migration.sql',
                    503
                );
            }

            return $this->error($response, $this->conversionErrorMessage($e), 500);
        } catch (\Throwable $e) {
            return $this->error($response, $this->conversionErrorMessage($e), 500);
        }

        return $this->success($response, [
            'converted' => true,
            'student' => $result['student'],
            'temporary_password' => $result['temporary_password'],
        ], 'Lead converted to student');
    }

    public function paymentReceipt(Request $request, Response $response, array $args): Response
    {
        $student = $this->students->findById((int) $args['studentId']);
        if ($student === null || empty($student['payment_receipt_path'])) {
            return $this->error($response, 'Student or receipt not found', 404);
        }

        $path = $this->receiptUploads->resolvePath((string) $student['payment_receipt_path']);
        if ($path === null) {
            return $this->error($response, 'Receipt file not found', 404);
        }

        $stream = fopen($path, 'rb');
        if ($stream === false) {
            return $this->error($response, 'Could not read receipt', 500);
        }

        $body = $response->getBody();
        $body->write((string) stream_get_contents($stream));
        fclose($stream);

        $mime = mime_content_type($path) ?: 'application/octet-stream';

        return $response
            ->withHeader('Content-Type', $mime)
            ->withHeader('Content-Disposition', 'inline; filename="' . basename($path) . '"');
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

    /**
     * @return array{body: array<string,mixed>}|array{errors: array<string,string>}
     */
    private function parseLeadBody(Request $request): array
    {
        $parsed = $request->getParsedBody();
        if (isset($parsed['data']) && is_string($parsed['data'])) {
            $decoded = json_decode($parsed['data'], true);
            if (!is_array($decoded)) {
                return ['errors' => ['data' => 'Invalid lead data']];
            }
            $body = $decoded;
        } else {
            $body = (array) ($parsed ?? []);
        }

        $errors = $this->validate($body, false);
        if ($errors !== []) {
            return ['errors' => $errors];
        }

        return ['body' => $body];
    }

    private function conversionErrorMessage(\Throwable $e): string
    {
        $debug = filter_var($_ENV['APP_DEBUG'] ?? 'true', FILTER_VALIDATE_BOOLEAN);

        if ($debug) {
            return 'Could not convert lead to student: ' . $e->getMessage();
        }

        return 'Could not convert lead to student';
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
