<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

final class ZoomService
{
    private ?string $accessToken = null;
    private int $tokenExpiresAt = 0;

    public function __construct(
        private readonly bool $flagEnabled,
        private readonly string $accountId,
        private readonly string $clientId,
        private readonly string $clientSecret,
        private readonly string $userId,
        private readonly string $timezone,
    ) {}

    public function isEnabled(): bool
    {
        return $this->getSetupIssue() === null && $this->hasAnyCredentials();
    }

    /** User-facing reason when Zoom credentials exist but integration cannot run. */
    public function getSetupIssue(): ?string
    {
        if (!$this->hasAnyCredentials()) {
            return null;
        }

        if ($this->accountId === '' || $this->clientId === '' || $this->clientSecret === '') {
            return 'Complete ZOOM_ACCOUNT_ID, ZOOM_CLIENT_ID, and ZOOM_CLIENT_SECRET in api/.env';
        }

        if (!$this->flagEnabled) {
            return 'Set ZOOM_ENABLED=true in api/.env';
        }

        if ($this->userId === '') {
            return 'Set ZOOM_USER_ID to the Zoom host email in api/.env (the account that owns the meetings)';
        }

        return null;
    }

    private function hasAnyCredentials(): bool
    {
        return $this->accountId !== '' || $this->clientId !== '' || $this->clientSecret !== '';
    }

    /** @param array<string, mixed> $payload */
    public function createRecurringMeeting(array $payload): array
    {
        return $this->request('POST', '/users/' . rawurlencode($this->userId) . '/meetings', $payload);
    }

    /** @param array<string, mixed> $payload */
    public function updateMeeting(string $meetingId, array $payload): array
    {
        return $this->request('PATCH', '/meetings/' . rawurlencode($meetingId), $payload);
    }

    public function deleteMeeting(string $meetingId): void
    {
        $this->request('DELETE', '/meetings/' . rawurlencode($meetingId));
    }

    public function timezone(): string
    {
        return $this->timezone;
    }

    public function hostUserId(): string
    {
        return $this->userId;
    }

    /** ZAK token lets a host start or join outside the scheduled window. */
    public function getHostZakToken(): string
    {
        if (!$this->isEnabled()) {
            throw new ZoomApiException('Zoom integration is not configured');
        }

        /** @var array{token?: string} $data */
        $data = $this->request('GET', '/users/' . rawurlencode($this->userId) . '/token?type=zak');

        $token = trim((string) ($data['token'] ?? ''));
        if ($token === '') {
            throw new ZoomApiException(
                'Zoom did not return a host token (ZAK). In the Chess S2S app on Zoom Marketplace, '
                . 'add the user:read:token scope under Scopes, then Activate the app again.'
            );
        }

        return $token;
    }

    /** @return array<string, mixed> */
    private function request(string $method, string $path, ?array $body = null): array
    {
        if (!$this->isEnabled()) {
            throw new ZoomApiException('Zoom integration is not configured');
        }

        $url = 'https://api.zoom.us/v2' . $path;
        $headers = [
            'Authorization: Bearer ' . $this->getAccessToken(),
            'Content-Type: application/json',
        ];

        $ch = curl_init($url);
        if ($ch === false) {
            throw new ZoomApiException('Could not initialize Zoom HTTP client');
        }

        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST => $method,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => $headers,
            CURLOPT_TIMEOUT => 30,
        ]);

        if ($body !== null) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body, JSON_THROW_ON_ERROR));
        }

        $responseBody = curl_exec($ch);
        $httpStatus = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);

        if ($responseBody === false) {
            throw new ZoomApiException('Zoom request failed: ' . $curlError);
        }

        if ($httpStatus >= 400) {
            $message = $this->extractErrorMessage($responseBody) ?? 'Zoom API request failed';
            throw new ZoomApiException($message, $httpStatus, $responseBody);
        }

        if ($method === 'DELETE' || trim($responseBody) === '') {
            return [];
        }

        /** @var array<string, mixed> */
        return json_decode($responseBody, true, 512, JSON_THROW_ON_ERROR);
    }

    private function getAccessToken(): string
    {
        if ($this->accessToken !== null && time() < $this->tokenExpiresAt - 60) {
            return $this->accessToken;
        }

        $url = 'https://zoom.us/oauth/token?grant_type=account_credentials&account_id=' . rawurlencode($this->accountId);
        $auth = base64_encode($this->clientId . ':' . $this->clientSecret);

        $ch = curl_init($url);
        if ($ch === false) {
            throw new ZoomApiException('Could not initialize Zoom OAuth client');
        }

        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER => [
                'Authorization: Basic ' . $auth,
                'Content-Type: application/x-www-form-urlencoded',
            ],
            CURLOPT_TIMEOUT => 30,
        ]);

        $responseBody = curl_exec($ch);
        $httpStatus = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);

        if ($responseBody === false) {
            throw new ZoomApiException('Zoom OAuth failed: ' . $curlError);
        }

        if ($httpStatus >= 400) {
            $message = $this->extractErrorMessage($responseBody) ?? 'Zoom OAuth failed';
            throw new ZoomApiException($message, $httpStatus, $responseBody);
        }

        /** @var array{access_token?: string, expires_in?: int} $data */
        $data = json_decode($responseBody, true, 512, JSON_THROW_ON_ERROR);
        if (empty($data['access_token'])) {
            throw new ZoomApiException('Zoom OAuth response missing access token');
        }

        $this->accessToken = $data['access_token'];
        $this->tokenExpiresAt = time() + (int) ($data['expires_in'] ?? 3600);

        return $this->accessToken;
    }

    private function extractErrorMessage(string $responseBody): ?string
    {
        try {
            /** @var array{message?: string, reason?: string} $data */
            $data = json_decode($responseBody, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException) {
            return null;
        }

        if (!empty($data['message'])) {
            return (string) $data['message'];
        }

        if (!empty($data['reason'])) {
            return (string) $data['reason'];
        }

        return null;
    }
}
