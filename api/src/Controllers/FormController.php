<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Repositories\FormRepository;
use ChessAcademy\Repositories\UserRepository;
use ChessAcademy\Services\BatchZoomService;
use ChessAcademy\Services\ZoomApiException;
use ChessAcademy\Services\ZoomSdkService;
use ChessAcademy\Services\ZoomService;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class FormController
{
    public function __construct(
        private readonly FormRepository $forms,
        private readonly BatchZoomService $batchZoom,
        private readonly ZoomSdkService $zoomSdk,
        private readonly ZoomService $zoom,
        private readonly UserRepository $users,
    ) {}

    public function index(Request $request, Response $response): Response
    {
        $rows = array_map(
            fn (array $row): array => $this->sanitizeFormForClient($row),
            $this->forms->findAll()
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

        return $this->json($response, ['success' => true, 'data' => $this->sanitizeFormForClient($form)]);
    }

    public function zoomSignature(Request $request, Response $response, array $args): Response
    {
        $id = (int) $args['id'];
        $form = $this->forms->findById($id);

        if ($form === null) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Form not found',
            ], 404);
        }

        $meetingNumber = ZoomSdkService::normalizeMeetingNumber((string) ($form['zoom_meeting_id'] ?? ''));
        if ($meetingNumber === '') {
            return $this->json($response, [
                'success' => false,
                'message' => 'This batch has no Zoom meeting yet',
            ], 422);
        }

        if (!$this->zoomSdk->isConfigured()) {
            return $this->json($response, [
                'success' => false,
                'message' => 'Zoom Meeting SDK is not configured on the server',
            ], 503);
        }

        /** @var array{id:int,email:string,role:string} $authUser */
        $authUser = $request->getAttribute('user');
        $profile = $this->users->findById($authUser['id']);
        $userName = trim((string) (($profile['first_name'] ?? '') . ' ' . ($profile['last_name'] ?? '')));
        if ($userName === '') {
            $userName = $authUser['email'];
        }

        $role = $this->zoomSdk->roleForUser($authUser['role']);
        $wantsHost = $role === 1;
        $zak = null;
        $hostStartUrl = null;
        $hostWarning = null;

        if ($wantsHost) {
            try {
                $zak = $this->zoom->getHostZakToken();
            } catch (ZoomApiException) {
                $role = 0;
                $hostStartUrl = trim((string) ($form['zoom_start_url'] ?? ''));
                $hostWarning = $hostStartUrl !== ''
                    ? 'Start the class in Zoom first (button below), then click Join class.'
                    : 'Add user:read:token scope to the Chess S2S app, Activate it, then re-save this batch.';
            }
        }

        try {
            $signature = $this->zoomSdk->createSignature($meetingNumber, $role);
        } catch (ZoomApiException $e) {
            return $this->json($response, [
                'success' => false,
                'message' => $e->getMessage(),
            ], 503);
        }

        $topic = (string) ($form['batch'] ?? 'Batch');
        $module = trim((string) ($form['module'] ?? ''));
        if ($module !== '') {
            $topic .= ' — ' . $module;
        }

        return $this->json($response, [
            'success' => true,
            'data' => [
                'signature' => $signature,
                'sdkKey' => $this->zoomSdk->sdkClientId(),
                'meetingNumber' => $meetingNumber,
                'password' => (string) ($form['zoom_password'] ?? ''),
                'userName' => $userName,
                'role' => $role,
                'topic' => $topic,
                'zak' => $zak,
                'hostStartUrl' => $hostStartUrl !== '' ? $hostStartUrl : null,
                'hostWarning' => $hostWarning,
                'setupHint' => $this->zoomSdk->setupHint(),
            ],
        ]);
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
        $zoomWarning = $this->syncZoomOnCreate((int) $created['id']);
        $created = $this->forms->findById((int) $created['id']) ?? $created;

        $payload = [
            'success' => true,
            'data' => $this->sanitizeFormForClient($created),
            'message' => 'Form created',
        ];

        if ($zoomWarning !== null) {
            $payload['zoom_warning'] = $zoomWarning;
        }

        return $this->json($response, $payload, 201);
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

        $zoomWarning = null;
        if ($this->batchZoom->scheduleChanged($existing, $body)) {
            $zoomWarning = $this->syncZoomOnUpdate($updated);
            $updated = $this->forms->findById($id) ?? $updated;
        }

        $payload = [
            'success' => true,
            'data' => $this->sanitizeFormForClient($updated),
            'message' => 'Form updated',
        ];

        if ($zoomWarning !== null) {
            $payload['zoom_warning'] = $zoomWarning;
        }

        return $this->json($response, $payload);
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

        if ($this->batchZoom->isEnabled()) {
            try {
                $this->batchZoom->deleteForBatch($existing);
            } catch (ZoomApiException) {
                // Batch removal should not fail if Zoom cleanup fails.
            }
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

    private function syncZoomOnCreate(int $formId): ?string
    {
        $setupIssue = $this->batchZoom->getSetupIssue();
        if ($setupIssue !== null) {
            return 'Batch saved, but Zoom meeting was not created: ' . $setupIssue;
        }

        if (!$this->batchZoom->isEnabled()) {
            return null;
        }

        $form = $this->forms->findById($formId);
        if ($form === null) {
            return null;
        }

        try {
            $zoom = $this->batchZoom->createForBatch($form);
            $this->forms->updateZoom($formId, $zoom);
        } catch (ZoomApiException $e) {
            return 'Batch saved, but Zoom meeting could not be created: ' . $this->formatZoomError($e);
        }

        return null;
    }

    /** @param array<string, mixed> $updated */
    private function syncZoomOnUpdate(array $updated): ?string
    {
        $setupIssue = $this->batchZoom->getSetupIssue();
        if ($setupIssue !== null) {
            return 'Batch updated, but Zoom meeting was not created: ' . $setupIssue;
        }

        if (!$this->batchZoom->isEnabled()) {
            return null;
        }

        try {
            $zoom = $this->batchZoom->updateForBatch($updated);
            $this->forms->updateZoom((int) $updated['id'], $zoom);
        } catch (ZoomApiException $e) {
            return 'Batch updated, but Zoom meeting could not be updated: ' . $this->formatZoomError($e);
        }

        return null;
    }

    private function formatZoomError(ZoomApiException $e): string
    {
        $message = $e->getMessage();

        if (str_contains($message, 'does not contain scopes')) {
            $message .= '. In Zoom Marketplace, add scope meeting:write:meeting:admin to your Server-to-Server app, then click Activate.';
        }

        return $message;
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

    /** @param array<string, mixed> $form */
    private function sanitizeFormForClient(array $form): array
    {
        unset($form['zoom_join_url'], $form['zoom_start_url'], $form['zoom_password']);

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
