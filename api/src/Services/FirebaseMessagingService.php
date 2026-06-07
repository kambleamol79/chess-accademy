<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use Firebase\JWT\JWT;

final class FirebaseMessagingService
{
    private ?array $serviceAccount = null;
    private ?string $accessToken = null;
    private int $accessTokenExpiresAt = 0;

    public function __construct(
        private readonly string $projectId,
        private readonly string $serviceAccountPath,
        private readonly string $studentsTopic,
    ) {}

    /** @param array<string,mixed> $settings */
    public static function fromSettings(array $settings): self
    {
        $firebase = $settings['firebase'] ?? [];

        return new self(
            trim((string) ($firebase['project_id'] ?? '')),
            trim((string) ($firebase['service_account_path'] ?? '')),
            trim((string) ($firebase['students_topic'] ?? 'students')) ?: 'students',
        );
    }

    /** Optional Firebase client — reads env when settings array is unavailable. */
    public static function createOptional(): self
    {
        return new self(
            trim((string) ($_ENV['FIREBASE_PROJECT_ID'] ?? getenv('FIREBASE_PROJECT_ID') ?: '')),
            trim((string) ($_ENV['FIREBASE_SERVICE_ACCOUNT_PATH'] ?? getenv('FIREBASE_SERVICE_ACCOUNT_PATH') ?: '')),
            trim((string) ($_ENV['FIREBASE_STUDENTS_TOPIC'] ?? getenv('FIREBASE_STUDENTS_TOPIC') ?: 'students')) ?: 'students',
        );
    }

    public function isConfigured(): bool
    {
        return $this->projectId !== ''
            && $this->serviceAccountPath !== ''
            && is_readable($this->serviceAccountPath);
    }

    /**
     * @param array<string,string> $data
     * @return array{ok: bool, detail: string}
     */
    public function sendToStudentsTopic(string $title, string $body, array $data = []): array
    {
        if (!$this->isConfigured()) {
            return ['ok' => false, 'detail' => 'Firebase not configured'];
        }

        $message = [
            'topic' => $this->studentsTopic,
            'notification' => [
                'title' => $title,
                'body' => $body,
            ],
            'data' => $this->normalizeData($data),
            'android' => ['priority' => 'HIGH'],
            'apns' => ['headers' => ['apns-priority' => '10']],
        ];

        return $this->sendMessage($message);
    }

    /**
     * @param list<string> $tokens
     * @param array<string,string> $data
     * @return array{ok: bool, detail: string, sent: int, failed: int}
     */
    public function sendToTokens(array $tokens, string $title, string $body, array $data = []): array
    {
        if (!$this->isConfigured()) {
            return ['ok' => false, 'detail' => 'Firebase not configured', 'sent' => 0, 'failed' => count($tokens)];
        }

        $sent = 0;
        $failed = 0;
        $lastError = '';

        foreach (array_values(array_unique(array_filter($tokens))) as $token) {
            $result = $this->sendMessage([
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                ],
                'data' => $this->normalizeData($data),
                'android' => ['priority' => 'HIGH'],
                'apns' => ['headers' => ['apns-priority' => '10']],
            ]);

            if ($result['ok']) {
                $sent++;
            } else {
                $failed++;
                $lastError = $result['detail'];
            }
        }

        if ($sent === 0 && $failed > 0) {
            return ['ok' => false, 'detail' => $lastError !== '' ? $lastError : 'All token sends failed', 'sent' => 0, 'failed' => $failed];
        }

        return [
            'ok' => true,
            'detail' => sprintf('Sent to %d device(s)', $sent),
            'sent' => $sent,
            'failed' => $failed,
        ];
    }

    /** @param array<string,mixed> $message */
    private function sendMessage(array $message): array
    {
        $accessToken = $this->getAccessToken();
        if ($accessToken === null) {
            return ['ok' => false, 'detail' => 'Could not obtain Firebase access token'];
        }

        $url = sprintf(
            'https://fcm.googleapis.com/v1/projects/%s/messages:send',
            rawurlencode($this->projectId)
        );

        $payload = json_encode(['message' => $message], JSON_THROW_ON_ERROR);
        $response = $this->httpRequest('POST', $url, $payload, [
            'Authorization: Bearer ' . $accessToken,
            'Content-Type: application/json',
        ]);

        if ($response['status'] >= 200 && $response['status'] < 300) {
            return ['ok' => true, 'detail' => 'Push sent'];
        }

        $detail = trim($response['body']);
        if ($detail === '') {
            $detail = 'FCM request failed with status ' . $response['status'];
        }

        return ['ok' => false, 'detail' => $detail];
    }

    private function getAccessToken(): ?string
    {
        if ($this->accessToken !== null && time() < $this->accessTokenExpiresAt - 60) {
            return $this->accessToken;
        }

        $account = $this->loadServiceAccount();
        if ($account === null) {
            return null;
        }

        $now = time();
        $jwt = JWT::encode([
            'iss' => $account['client_email'],
            'sub' => $account['client_email'],
            'aud' => 'https://oauth2.googleapis.com/token',
            'iat' => $now,
            'exp' => $now + 3600,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        ], $account['private_key'], 'RS256');

        $response = $this->httpRequest(
            'POST',
            'https://oauth2.googleapis.com/token',
            http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ]),
            ['Content-Type: application/x-www-form-urlencoded']
        );

        if ($response['status'] < 200 || $response['status'] >= 300) {
            return null;
        }

        /** @var array<string,mixed>|null $decoded */
        $decoded = json_decode($response['body'], true);
        $token = is_array($decoded) ? (string) ($decoded['access_token'] ?? '') : '';
        if ($token === '') {
            return null;
        }

        $this->accessToken = $token;
        $this->accessTokenExpiresAt = $now + (int) ($decoded['expires_in'] ?? 3600);

        return $this->accessToken;
    }

    /** @return array<string,mixed>|null */
    private function loadServiceAccount(): ?array
    {
        if ($this->serviceAccount !== null) {
            return $this->serviceAccount;
        }

        if (!$this->isConfigured()) {
            return null;
        }

        $raw = file_get_contents($this->serviceAccountPath);
        if ($raw === false) {
            return null;
        }

        /** @var array<string,mixed>|null $decoded */
        $decoded = json_decode($raw, true);
        if (!is_array($decoded) || empty($decoded['client_email']) || empty($decoded['private_key'])) {
            return null;
        }

        $this->serviceAccount = $decoded;

        return $this->serviceAccount;
    }

    /** @param array<string,string> $data */
    private function normalizeData(array $data): array
    {
        $normalized = [];
        foreach ($data as $key => $value) {
            $normalized[(string) $key] = (string) $value;
        }

        return $normalized;
    }

    /**
     * @param list<string> $headers
     * @return array{status: int, body: string}
     */
    private function httpRequest(string $method, string $url, string $body, array $headers): array
    {
        if (function_exists('curl_init')) {
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_CUSTOMREQUEST => $method,
                CURLOPT_POSTFIELDS => $body,
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 20,
            ]);
            $responseBody = curl_exec($ch);
            $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
            curl_close($ch);

            return [
                'status' => $status,
                'body' => is_string($responseBody) ? $responseBody : '',
            ];
        }

        $context = stream_context_create([
            'http' => [
                'method' => $method,
                'header' => implode("\r\n", $headers),
                'content' => $body,
                'ignore_errors' => true,
                'timeout' => 20,
            ],
        ]);
        $responseBody = file_get_contents($url, false, $context);
        $status = 0;
        if (isset($http_response_header[0]) && preg_match('/\s(\d{3})\s/', $http_response_header[0], $matches)) {
            $status = (int) $matches[1];
        }

        return [
            'status' => $status,
            'body' => is_string($responseBody) ? $responseBody : '',
        ];
    }
}
