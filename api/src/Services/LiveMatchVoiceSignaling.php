<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

/**
 * Stores WebRTC signaling messages per match (offer / answer / ICE) for peer voice chat.
 */
final class LiveMatchVoiceSignaling
{
    private const MAX_SIGNALS_PER_MATCH = 200;

    public function __construct(private readonly string $varDir) {}

    /** @param array<string,mixed> $payload */
    public function append(int $matchId, int $fromStudentId, string $type, array $payload): int
    {
        $dir = $this->varDir . '/live-voice';
        if (!is_dir($dir)) {
            mkdir($dir, 0775, true);
        }

        $path = $this->path($matchId);
        $signals = $this->readAll($path);
        $seq = empty($signals) ? 1 : ((int) end($signals)['seq']) + 1;

        $signals[] = [
            'seq' => $seq,
            'from_student_id' => $fromStudentId,
            'type' => $type,
            'payload' => $payload,
            'created_at' => time(),
        ];

        if (count($signals) > self::MAX_SIGNALS_PER_MATCH) {
            $signals = array_slice($signals, -self::MAX_SIGNALS_PER_MATCH);
        }

        file_put_contents($path, json_encode($signals, JSON_THROW_ON_ERROR), LOCK_EX);

        return $seq;
    }

    /**
     * @return list<array<string,mixed>>
     */
    public function listForStudent(int $matchId, int $studentId, int $sinceSeq): array
    {
        $signals = $this->readAll($this->path($matchId));
        $out = [];
        $cutoff = time() - 120;

        foreach ($signals as $row) {
            $seq = (int) ($row['seq'] ?? 0);
            if ($seq <= $sinceSeq) {
                continue;
            }
            if ((int) ($row['created_at'] ?? 0) < $cutoff) {
                continue;
            }
            if ((int) ($row['from_student_id'] ?? 0) === $studentId) {
                continue;
            }
            $out[] = [
                'seq' => $seq,
                'type' => (string) ($row['type'] ?? ''),
                'payload' => is_array($row['payload'] ?? null) ? $row['payload'] : [],
            ];
        }

        return $out;
    }

    public function clear(int $matchId): void
    {
        $path = $this->path($matchId);
        if (is_file($path)) {
            unlink($path);
        }
    }

    private function path(int $matchId): string
    {
        return $this->varDir . '/live-voice/' . $matchId . '.json';
    }

    /**
     * @return list<array<string,mixed>>
     */
    private function readAll(string $path): array
    {
        if (!is_file($path)) {
            return [];
        }
        $raw = file_get_contents($path);
        if ($raw === false || $raw === '') {
            return [];
        }
        $decoded = json_decode($raw, true);

        return is_array($decoded) ? $decoded : [];
    }
}
