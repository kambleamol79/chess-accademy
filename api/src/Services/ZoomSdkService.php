<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use Firebase\JWT\JWT;

final class ZoomSdkService
{
    public function __construct(
        private readonly string $sdkClientId,
        private readonly string $sdkClientSecret,
    ) {}

    public function isConfigured(): bool
    {
        return $this->sdkClientId !== '' && $this->sdkClientSecret !== '';
    }

    public function sdkClientId(): string
    {
        return $this->sdkClientId;
    }

    public static function normalizeMeetingNumber(string $meetingNumber): string
    {
        return preg_replace('/\D/', '', $meetingNumber) ?? '';
    }

    public function createSignature(string $meetingNumber, int $role = 0): string
    {
        if (!$this->isConfigured()) {
            throw new ZoomApiException('Zoom Meeting SDK is not configured');
        }

        $mn = self::normalizeMeetingNumber($meetingNumber);
        if ($mn === '') {
            throw new ZoomApiException('Invalid Zoom meeting number');
        }

        // Match Zoom auth-endpoint sample: iat slightly in the past for clock skew.
        $iat = time() - 30;
        $exp = $iat + 60 * 60 * 2;

        // Cross-platform payload (Zoom auth-endpoint sample + SDK 6.x web docs).
        $payload = [
            'appKey' => $this->sdkClientId,
            'sdkKey' => $this->sdkClientId,
            'mn' => $mn,
            'role' => $role,
            'iat' => $iat,
            'exp' => $exp,
            'tokenExp' => $exp,
        ];

        return JWT::encode($payload, $this->sdkClientSecret, 'HS256');
    }

    /** Hosts start the meeting; students join as participants once it is running. */
    public function roleForUser(string $userRole): int
    {
        return in_array($userRole, ['admin', 'coach'], true) ? 1 : 0;
    }

    public function setupHint(): string
    {
        return 'Error 3712 means Zoom rejected the Meeting SDK JWT. Server-to-Server OAuth credentials '
            . 'cannot sign SDK joins unless Meeting SDK is enabled on the same General App. '
            . 'In Zoom Marketplace → your app → Features, turn on Meeting SDK. '
            . 'If you enabled it after publishing, republish the app. '
            . 'Then set ZOOM_SDK_CLIENT_ID and ZOOM_SDK_CLIENT_SECRET to that app\'s Client ID/Secret '
            . '(Development credentials for unpublished apps, Production if published).';
    }
}
