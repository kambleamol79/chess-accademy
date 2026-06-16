<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\SettingsRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class SettingsController
{
    use JsonResponse;

    private const TOURNAMENT_URL_DEFAULT = 'https://www.chess.com/play/arena/31279193';
    private const TOURNAMENT_LABEL_DEFAULT = "Today's tournament";
    private const TOURNAMENT_TIMEZONE_DEFAULT = 'Asia/Kolkata';

    public function __construct(private readonly SettingsRepository $settings) {}

    public function index(Request $request, Response $response): Response
    {
        return $this->success($response, $this->settings->all());
    }

    public function tournamentCta(Request $request, Response $response): Response
    {
        $url = $this->settings->get('today_tournament_url', self::TOURNAMENT_URL_DEFAULT);
        $label = $this->settings->get('today_tournament_label', self::TOURNAMENT_LABEL_DEFAULT);
        $timezone = $this->settings->get('today_tournament_timezone', null);
        if (!is_string($timezone) || trim($timezone) === '') {
            $timezone = $this->settings->get('timezone', self::TOURNAMENT_TIMEZONE_DEFAULT);
        }
        $visibleFrom = $this->settings->get('today_tournament_visible_from', null);
        $visibleUntil = $this->settings->get('today_tournament_visible_until', null);

        $url = is_string($url) ? trim($url) : '';
        $label = is_string($label) && trim($label) !== ''
            ? trim($label)
            : self::TOURNAMENT_LABEL_DEFAULT;
        $timezone = is_string($timezone) && trim($timezone) !== ''
            ? trim($timezone)
            : self::TOURNAMENT_TIMEZONE_DEFAULT;
        $visibleFrom = is_string($visibleFrom) ? trim($visibleFrom) : '';
        $visibleUntil = is_string($visibleUntil) ? trim($visibleUntil) : '';

        return $this->success($response, [
            'url' => $url,
            'label' => $label,
            'timezone' => $timezone,
            'visible_from' => $visibleFrom !== '' ? $visibleFrom : null,
            'visible_until' => $visibleUntil !== '' ? $visibleUntil : null,
            'visible' => $url !== '' && $this->isTournamentVisible($timezone, $visibleFrom, $visibleUntil),
        ]);
    }

    public function update(Request $request, Response $response): Response
    {
        $body = (array) ($request->getParsedBody() ?? []);
        if ($body === []) {
            return $this->error($response, 'No settings provided', 422);
        }

        foreach ($body as $key => $value) {
            $this->settings->set((string) $key, $value);
        }

        return $this->success($response, $this->settings->all(), 'Settings updated');
    }

    private function isTournamentVisible(string $timezone, string $from, string $until): bool
    {
        if ($from === '' && $until === '') {
            return true;
        }

        try {
            $tz = new \DateTimeZone($timezone);
        } catch (\Exception) {
            return true;
        }

        $today = (new \DateTime('now', $tz))->format('Y-m-d');
        $fromDate = $from !== '' ? $this->parseDate($from) : null;
        $untilDate = $until !== '' ? $this->parseDate($until) : null;

        if ($from !== '' && $fromDate === null) {
            return true;
        }
        if ($until !== '' && $untilDate === null) {
            return true;
        }
        if ($fromDate !== null && $today < $fromDate) {
            return false;
        }
        if ($untilDate !== null && $today > $untilDate) {
            return false;
        }

        return true;
    }

    private function parseDate(string $date): ?string
    {
        if (!preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', trim($date), $matches)) {
            return null;
        }

        $year = (int) $matches[1];
        $month = (int) $matches[2];
        $day = (int) $matches[3];
        if (!checkdate($month, $day, $year)) {
            return null;
        }

        return sprintf('%04d-%02d-%02d', $year, $month, $day);
    }
}
