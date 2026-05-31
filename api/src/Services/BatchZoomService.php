<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

final class BatchZoomService
{
    /** @var array<string, int> */
    private const WEEKDAY_TO_ZOOM = [
        'SUN' => 1,
        'MON' => 2,
        'TUE' => 3,
        'WED' => 4,
        'THU' => 5,
        'FRI' => 6,
        'SAT' => 7,
    ];

    /** @var array<string, int> */
    private const WEEKDAY_TO_PHP = [
        'SUN' => 0,
        'MON' => 1,
        'TUE' => 2,
        'WED' => 3,
        'THU' => 4,
        'FRI' => 5,
        'SAT' => 6,
    ];

    public function __construct(private readonly ZoomService $zoom) {}

    public function isEnabled(): bool
    {
        return $this->zoom->isEnabled();
    }

    public function getSetupIssue(): ?string
    {
        return $this->zoom->getSetupIssue();
    }

    /** @param array<string, mixed> $batch */
    public function createForBatch(array $batch): array
    {
        $response = $this->zoom->createRecurringMeeting($this->buildMeetingPayload($batch));

        return $this->mapMeetingResponse($response);
    }

    /** @param array<string, mixed> $batch */
    public function updateForBatch(array $batch): array
    {
        $meetingId = (string) ($batch['zoom_meeting_id'] ?? '');
        if ($meetingId === '') {
            return $this->createForBatch($batch);
        }

        // Recreate so meeting type/settings (e.g. no fixed start time) stay in sync with Zoom.
        try {
            $this->zoom->deleteMeeting($meetingId);
        } catch (ZoomApiException) {
            // Meeting may already be gone on Zoom.
        }

        return $this->createForBatch($batch);
    }

    /** @param array<string, mixed> $batch */
    public function deleteForBatch(array $batch): void
    {
        $meetingId = (string) ($batch['zoom_meeting_id'] ?? '');
        if ($meetingId === '') {
            return;
        }

        $this->zoom->deleteMeeting($meetingId);
    }

    /** @param array<string, mixed> $batch */
    public function scheduleChanged(array $batch, array $body): bool
    {
        foreach (['time', 'day_1', 'day_2', 'batch', 'module'] as $field) {
            if (!array_key_exists($field, $body)) {
                continue;
            }
            if ((string) ($batch[$field] ?? '') !== (string) $body[$field]) {
                return true;
            }
        }

        return false;
    }

    /** @param array<string, mixed> $batch */
    private function buildMeetingPayload(array $batch): array
    {
        $batchCode = trim((string) ($batch['batch'] ?? 'Batch'));
        $module = trim((string) ($batch['module'] ?? ''));
        $day1 = strtoupper(trim((string) ($batch['day_1'] ?? '')));
        $day2 = strtoupper(trim((string) ($batch['day_2'] ?? '')));
        $timeSlot = trim((string) ($batch['time'] ?? ''));

        if ($day1 === '' || $day2 === '') {
            throw new ZoomApiException('Batch weekdays are required for Zoom scheduling');
        }

        [, , $duration] = $this->parseTimeSlot($timeSlot);
        $timezone = $this->zoom->timezone();
        $topic = $module !== '' ? "{$batchCode} — {$module}" : "{$batchCode} — Chess Class";
        $notes = trim((string) ($batch['notes'] ?? ''));

        return [
            'topic' => $topic,
            // Recurring with no fixed time — host can start anytime (avoids "Meeting has not started").
            'type' => 3,
            'duration' => $duration,
            'timezone' => $timezone,
            'agenda' => $notes !== '' ? $notes : 'Chess Academy recurring batch session',
            'recurrence' => [
                'type' => 2,
                'repeat_interval' => 1,
                'weekly_days' => $this->weeklyDays($day1, $day2),
            ],
            'settings' => [
                'host_video' => true,
                'participant_video' => true,
                'join_before_host' => true,
                'jbh_time' => 0,
                'mute_upon_entry' => true,
                'waiting_room' => false,
                'approval_type' => 0,
                'audio' => 'both',
                'auto_recording' => 'none',
            ],
        ];
    }

    /** @return array{zoom_meeting_id: string, zoom_join_url: string|null, zoom_start_url: string|null, zoom_password: string|null} */
    private function mapMeetingResponse(array $response): array
    {
        return [
            'zoom_meeting_id' => (string) ($response['id'] ?? ''),
            'zoom_join_url' => isset($response['join_url']) ? (string) $response['join_url'] : null,
            'zoom_start_url' => isset($response['start_url']) ? (string) $response['start_url'] : null,
            'zoom_password' => isset($response['password']) ? (string) $response['password'] : null,
        ];
    }

    private function weeklyDays(string $day1, string $day2): string
    {
        $days = array_values(array_unique([$day1, $day2]));
        $zoomDays = [];

        foreach ($days as $day) {
            if (!isset(self::WEEKDAY_TO_ZOOM[$day])) {
                throw new ZoomApiException("Unsupported weekday: {$day}");
            }
            $zoomDays[] = self::WEEKDAY_TO_ZOOM[$day];
        }

        sort($zoomDays);

        return implode(',', $zoomDays);
    }

    /** @return array{0: int, 1: int, 2: int} */
    private function parseTimeSlot(string $timeSlot): array
    {
        if (!preg_match('/^(\d{1,2})\.(\d{2})-(\d{1,2})\.(\d{2})$/', $timeSlot, $matches)) {
            throw new ZoomApiException('Invalid batch time slot format');
        }

        $startHour = (int) $matches[1];
        $startMinute = (int) $matches[2];
        $endHour = (int) $matches[3];
        $endMinute = (int) $matches[4];
        $startTotal = $startHour * 60 + $startMinute;
        $endTotal = $endHour * 60 + $endMinute;

        if ($endTotal <= $startTotal) {
            throw new ZoomApiException('Batch end time must be after start time');
        }

        return [$startHour, $startMinute, $endTotal - $startTotal];
    }

    private function computeNextStartTime(string $day1, int $hour, int $minute, string $timezone): string
    {
        if (!isset(self::WEEKDAY_TO_PHP[$day1])) {
            throw new ZoomApiException("Unsupported weekday: {$day1}");
        }

        $targetDow = self::WEEKDAY_TO_PHP[$day1];
        $tz = new \DateTimeZone($timezone);
        $now = new \DateTime('now', $tz);
        $candidate = (clone $now)->setTime($hour, $minute, 0);

        for ($i = 0; $i < 14; $i++) {
            if ((int) $candidate->format('w') === $targetDow && $candidate > $now) {
                return $candidate->format('Y-m-d\TH:i:s');
            }
            $candidate->modify('+1 day');
            $candidate->setTime($hour, $minute, 0);
        }

        throw new ZoomApiException('Could not compute next Zoom meeting start time');
    }
}
