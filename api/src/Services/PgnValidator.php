<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

final class PgnValidator
{
    public static function isValid(string $pgn): bool
    {
        $text = trim($pgn);
        if ($text === '' || strlen($text) < 8) {
            return false;
        }

        // Typical PGN: headers and/or numbered moves (1. e4 e5).
        if (preg_match('/\[\s*\w+\s+"[^"]*"\s*\]/', $text) === 1) {
            return true;
        }

        return preg_match('/\b\d+\.\s*\S+/', $text) === 1;
    }

    /** @return array<string, string> */
    public static function parseHeaders(string $pgn): array
    {
        $headers = [];
        foreach (preg_split('/\r\n|\r|\n/', $pgn) as $line) {
            $line = trim($line);
            if ($line === '' || $line[0] !== '[') {
                break;
            }
            if (preg_match('/^\[(\w+)\s+"(.*)"\s*\]$/', $line, $m) === 1) {
                $headers[$m[1]] = stripcslashes($m[2]);
            }
        }

        return $headers;
    }

    public static function suggestTitle(string $pgn): ?string
    {
        $headers = self::parseHeaders($pgn);
        foreach (['Event', 'White', 'Black', 'Site'] as $key) {
            if (!empty($headers[$key])) {
                if ($key === 'White' && !empty($headers['Black'])) {
                    return $headers['White'] . ' vs ' . $headers['Black'];
                }

                return $headers[$key];
            }
        }

        return null;
    }
}
