<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use InvalidArgumentException;
use Ryanhs\Chess\Chess;

final class ChessRulesService
{
    /**
     * @return array{san: string, fen_after: string, game_over: bool, result: string|null}
     */
    public function applyUci(string $currentFen, string $uci): array
    {
        $uci = strtolower(trim($uci));
        if (strlen($uci) < 4) {
            throw new InvalidArgumentException('Invalid UCI move');
        }

        $from = substr($uci, 0, 2);
        $to = substr($uci, 2, 2);
        $promotion = strlen($uci) > 4 ? substr($uci, 4, 1) : null;

        $currentFen = trim($currentFen);
        if ($currentFen === '') {
            throw new InvalidArgumentException('Invalid position');
        }

        try {
            $chess = new Chess();
            if ($chess->load($currentFen) !== true) {
                throw new InvalidArgumentException('Invalid position');
            }
        } catch (InvalidArgumentException $e) {
            throw $e;
        } catch (\Throwable) {
            throw new InvalidArgumentException('Invalid position');
        }

        $pretty = $chess->move([
            'from' => $from,
            'to' => $to,
            'promotion' => $promotion,
        ]);

        if ($pretty === null) {
            throw new InvalidArgumentException('Illegal move');
        }

        $fenAfter = $chess->fen();
        $gameOver = $chess->gameOver();
        $result = null;
        if ($gameOver) {
            $result = $this->resultFromPosition($chess);
        }

        $san = is_array($pretty) && isset($pretty['san']) ? (string) $pretty['san'] : $uci;

        return [
            'san' => $san,
            'fen_after' => $fenAfter,
            'game_over' => $gameOver,
            'result' => $result,
        ];
    }

    public function fenEquivalent(string $a, string $b): bool
    {
        $pa = $this->fenParts($a);
        $pb = $this->fenParts($b);

        // Board, side to move, and castling must match (chess.js vs chess.php may differ on ep/halfmove).
        return $pa[0] === $pb[0] && $pa[1] === $pb[1] && $pa[2] === $pb[2];
    }

    /** @return array{0: string, 1: string, 2: string} */
    private function fenParts(string $fen): array
    {
        $parts = preg_split('/\s+/', trim($fen)) ?: [];

        return [
            $parts[0] ?? '',
            $parts[1] ?? 'w',
            $parts[2] ?? '-',
        ];
    }

    private function resultFromPosition(Chess $chess): string
    {
        if ($chess->inCheckmate()) {
            return $chess->turn() === Chess::WHITE ? 'black_win' : 'white_win';
        }

        return 'draw';
    }
}
