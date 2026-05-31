<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use ChessAcademy\Repositories\ChessLiveMatchRepository;

final class LiveMatchBroadcaster
{
    public function __construct(
        private readonly ChessLiveMatchRepository $matches,
        private readonly string $varDir,
        private readonly bool $wsEnabled,
        private readonly string $wsBroadcastUrl,
        private readonly string $wsInternalSecret,
    ) {}

    public function publish(int $matchId, string $type = 'update'): int
    {
        $seq = $this->matches->bumpEventSeq($matchId);
        $payload = json_encode([
            'match_id' => $matchId,
            'event_seq' => $seq,
            'type' => $type,
            'ts' => time(),
        ], JSON_THROW_ON_ERROR);

        $dir = $this->varDir . '/live-events';
        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }
        file_put_contents($dir . '/' . $matchId . '.json', $payload, LOCK_EX);

        if ($this->wsEnabled && $this->wsBroadcastUrl !== '') {
            $this->notifyWebSocket($payload);
        }

        return $seq;
    }

    private function notifyWebSocket(string $payload): void
    {
        $ch = curl_init($this->wsBroadcastUrl);
        if ($ch === false) {
            return;
        }

        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'X-Live-Secret: ' . $this->wsInternalSecret,
            ],
            CURLOPT_POSTFIELDS => $payload,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT_MS => 800,
            CURLOPT_CONNECTTIMEOUT_MS => 400,
        ]);
        curl_exec($ch);
        curl_close($ch);
    }
}
