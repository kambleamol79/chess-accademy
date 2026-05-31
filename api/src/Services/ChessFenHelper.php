<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

final class ChessFenHelper
{
    public static function activeColor(string $fen): string
    {
        $parts = preg_split('/\s+/', trim($fen));

        return ($parts[1] ?? 'w') === 'b' ? 'b' : 'w';
    }

    public static function isStartingPosition(string $fen): bool
    {
        return str_starts_with(trim($fen), 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR');
    }
}
