#!/usr/bin/env php
<?php

declare(strict_types=1);

/**
 * Seed 100+ puzzles per difficulty (easy / medium / hard).
 * Run: php api/scripts/seed_puzzles.php
 */

require dirname(__DIR__) . '/vendor/autoload.php';

Dotenv\Dotenv::createImmutable(dirname(__DIR__))->safeLoad();

$settings = require dirname(__DIR__) . '/config/settings.php';
$pdo = ChessAcademy\Database\Connection::get($settings);

$puzzles = array_merge(
    PuzzleGenerator::easy(100),
    PuzzleGenerator::medium(100),
    PuzzleGenerator::hard(100),
);

$pdo->exec('DELETE FROM puzzle_attempts');
$pdo->exec('DELETE FROM puzzles');

$stmt = $pdo->prepare(
    'INSERT INTO puzzles (title, fen, solution_moves, difficulty, created_by) VALUES (:title, :fen, :solution, :difficulty, NULL)'
);

foreach ($puzzles as $p) {
    $stmt->execute([
        'title' => $p['title'],
        'fen' => $p['fen'],
        'solution' => $p['solution'],
        'difficulty' => $p['difficulty'],
    ]);
}

$counts = $pdo->query(
    "SELECT difficulty, COUNT(*) AS cnt FROM puzzles GROUP BY difficulty ORDER BY FIELD(difficulty, 'easy', 'medium', 'hard')"
)->fetchAll();

echo 'Seeded ' . count($puzzles) . " puzzles.\n";
foreach ($counts as $row) {
    echo "  {$row['difficulty']}: {$row['cnt']}\n";
}

final class PuzzleGenerator
{
    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    public static function easy(int $count): array
    {
        $out = [];
        $seen = [];

        foreach (self::backRankRookMates() as $p) {
            if (count($out) >= $count) {
                break;
            }
            if (self::addUnique($out, $seen, $p)) {
                /* added */
            }
        }

        foreach (self::queenMatePatterns() as $p) {
            if (count($out) >= $count) {
                break;
            }
            self::addUnique($out, $seen, $p);
        }

        foreach (self::minorPieceMates() as $p) {
            if (count($out) >= $count) {
                break;
            }
            self::addUnique($out, $seen, $p);
        }

        foreach (self::pawnPromotionMates() as $p) {
            if (count($out) >= $count) {
                break;
            }
            self::addUnique($out, $seen, $p);
        }

        return array_slice($out, 0, $count);
    }

    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    public static function medium(int $count): array
    {
        $out = [];
        $seen = [];
        $pool = self::expandPool(self::mediumTemplates(), 'medium');

        foreach ($pool as $t) {
            if (count($out) >= $count) {
                break;
            }
            self::addUnique($out, $seen, $t);
        }

        return array_slice($out, 0, $count);
    }

    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    public static function hard(int $count): array
    {
        $out = [];
        $seen = [];
        $pool = self::expandPool(self::hardTemplates(), 'hard');

        foreach ($pool as $t) {
            if (count($out) >= $count) {
                break;
            }
            self::addUnique($out, $seen, $t);
        }

        return array_slice($out, 0, $count);
    }

    /**
     * @param list<array{0:string,1:string,2:string}> $templates
     * @return list<array{title:string,fen:string,solution:string,difficulty:string}>
     */
    private static function expandPool(array $templates, string $difficulty): array
    {
        $pool = [];
        foreach ($templates as $i => [$title, $fen, $solution]) {
            $pool[] = [
                'title' => $title,
                'fen' => $fen,
                'solution' => $solution,
                'difficulty' => $difficulty,
            ];
            $pool[] = [
                'title' => $title . ' (mirror)',
                'fen' => self::mirrorFen($fen),
                'solution' => self::mirrorUciLine($solution),
                'difficulty' => $difficulty,
            ];
            // Shift halfmove clock for a distinct FEN fingerprint when mirroring collides.
            $pool[] = [
                'title' => $title . ' #' . ($i + 1),
                'fen' => preg_replace('/ (\d+)$/', ' ' . (($i % 8) + 1), $fen) ?? $fen,
                'solution' => $solution,
                'difficulty' => $difficulty,
            ];
        }

        return $pool;
    }

    /** @param list<array{title:string,fen:string,solution:string,difficulty:string}> $out */
    /** @param array<string, true> $seen */
    private static function addUnique(array &$out, array &$seen, array $p): bool
    {
        $key = $p['fen'] . '|' . $p['solution'];
        if (isset($seen[$key])) {
            return false;
        }
        $seen[$key] = true;
        $out[] = $p;

        return true;
    }

    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    private static function backRankRookMates(): array
    {
        $out = [];
        for ($rookFile = 0; $rookFile < 8; $rookFile++) {
            for ($kingFile = 0; $kingFile < 8; $kingFile++) {
                if ($rookFile === $kingFile) {
                    continue;
                }
                $rank8 = self::emptyRank();
                $rank8[$kingFile] = 'k';
                $rank7 = self::emptyRank();
                for ($f = max(0, $kingFile - 1); $f <= min(7, $kingFile + 1); $f++) {
                    $rank7[$f] = 'p';
                }
                $rank1 = self::emptyRank();
                $rank1[4] = 'K';
                $rank1[$rookFile] = 'R';
                $fen = implode('/', [
                    self::encodeRank($rank8),
                    self::encodeRank($rank7),
                    '8', '8', '8', '8',
                    'PPPPPPPP',
                    self::encodeRank($rank1),
                ]) . ' w - - 0 1';
                $from = self::fileChar($rookFile) . '1';
                $to = self::fileChar($kingFile) . '8';
                $out[] = [
                    'title' => 'Back rank mate ' . strtoupper($from . '-' . $to),
                    'fen' => $fen,
                    'solution' => $from . $to,
                    'difficulty' => 'easy',
                ];
                $mirrored = [
                    'title' => 'Back rank mate ' . strtoupper(self::mirrorUciLine($from . $to)),
                    'fen' => self::mirrorFen($fen),
                    'solution' => self::mirrorUciLine($from . $to),
                    'difficulty' => 'easy',
                ];
                $out[] = $mirrored;
            }
        }

        return $out;
    }

    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    private static function queenMatePatterns(): array
    {
        $patterns = [
            ['Scholar mate finish', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7'],
            ['Queen takes f7', 'rnbqk2r/pppp1Qpp/5n2/8/4P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 3', 'e8f7'],
            ['Queen mates h8', '6k1/6pp/8/8/8/8/7Q/6K1 w - - 0 1', 'h2h8'],
            ['Queen mates a8', 'k7/8/8/8/8/8/Q7/4K3 w - - 0 1', 'a2a8'],
            ['Queen mates g1', '5k2/8/8/8/8/8/5Q2/5K2 w - - 0 1', 'f2f1'],
            ['Queen mates c8', '2k5/8/8/8/8/8/1Q6/2K5 w - - 0 1', 'b2b8'],
            ['Queen fork king', '4k3/8/8/8/8/8/8/Q2K4 w - - 0 1', 'a1a8'],
            ['Queen mates corner', '7k/8/8/8/8/6Q1/8/6K1 w - - 0 1', 'g3g8'],
            ['Queen delivers mate', '5k2/8/8/8/8/8/3Q4/4K3 w - - 0 1', 'd2d8'],
            ['Queen mates b8', 'k7/ppp5/8/8/8/8/1Q6/4K3 w - - 0 1', 'b2b8'],
        ];
        $out = [];
        foreach ($patterns as [$title, $fen, $solution]) {
            $out[] = ['title' => $title, 'fen' => $fen, 'solution' => $solution, 'difficulty' => 'easy'];
            $mirrored = [
                'title' => $title . ' (mirror)',
                'fen' => self::mirrorFen($fen),
                'solution' => self::mirrorUciLine($solution),
                'difficulty' => 'easy',
            ];
            $out[] = $mirrored;
        }

        return $out;
    }

    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    private static function minorPieceMates(): array
    {
        $patterns = [
            ['Bishop mate', '6k1/8/5K2/8/8/8/8/5B2 w - - 0 1', 'f1c4'],
            ['Knight fork', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3', 'f3e5'],
            ['Rook mate', '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1', 'a1a8'],
            ['Bishop delivers', '7k/8/8/8/8/2B5/8/4K3 w - - 0 1', 'c3f6'],
            ['Knight mate net', '6k1/5n2/8/8/8/8/8/2N2K2 w - - 0 1', 'c1e2'],
        ];
        $out = [];
        foreach ($patterns as [$title, $fen, $solution]) {
            $out[] = ['title' => $title, 'fen' => $fen, 'solution' => $solution, 'difficulty' => 'easy'];
        }

        return $out;
    }

    /** @return list<array{title:string,fen:string,solution:string,difficulty:string}> */
    private static function pawnPromotionMates(): array
    {
        $out = [];
        for ($file = 0; $file < 8; $file++) {
            $rank7 = self::emptyRank();
            $rank7[$file] = 'P';
            $rank8 = self::emptyRank();
            $rank8[min(7, $file + 1)] = 'k';
            if ($file > 0) {
                $rank8[$file - 1] = 'p';
            }
            if ($file < 7) {
                $rank8[min(7, $file + 2)] = 'p';
            }
            $rank1 = self::emptyRank();
            $rank1[4] = 'K';
            $fen = implode('/', [
                self::encodeRank($rank8),
                self::encodeRank($rank7),
                '8', '8', '8', '8',
                self::encodeRank($rank1),
                '8',
            ]) . ' w - - 0 1';
            $from = self::fileChar($file) . '7';
            $to = self::fileChar($file) . '8';
            $out[] = [
                'title' => 'Promote with checkmate ' . $from,
                'fen' => $fen,
                'solution' => $from . $to . 'q',
                'difficulty' => 'easy',
            ];
        }

        return $out;
    }

    /** @return list<array{title:string,fen:string,solution:string}> */
    private static function mediumTemplates(): array
    {
        return [
            ['Win the queen', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7'],
            ['Knight fork combo', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5'],
            ['Double attack', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5'],
            ['Pin and win', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6'],
            ['Smothered setup', 'rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3', 'c4f7 e8e7 f7d5'],
            ['Discovered attack', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7'],
            ['Remove defender', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/3P1N2/PPP1BPPP/RNBQK2R w KQkq - 2 4', 'f3e5 c6e5 e2h5'],
            ['Fork and win', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5'],
            ['Two-move tactic', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 d1h5'],
            ['Win material', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5'],
            ['Trap the queen', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3e5'],
            ['Knight outpost', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 d8e7 e5f7'],
            ['Bishop pair attack', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 f3g5'],
            ['Central fork', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3e5 c6e5 c4f7'],
            ['Open file tactic', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3', 'f1e1 e8e7 e1e7'],
            ['Skewer opportunity', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 d1h5'],
            ['Clearance', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7'],
            ['Deflection', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5 f7g8 g5h7'],
            ['Overload', 'r1bqkb1r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5'],
            ['Intermediate move', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7 f8e7 f7d8'],
            ['Mate threat', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5'],
            ['Capture sequence', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3e5'],
            ['King hunt', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 f3g5'],
            ['Piece coordination', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/3P1N2/PPP1BPPP/RNBQK2R w KQkq - 2 4', 'e2h5 g8f6 h5f7'],
            ['Tactical shot', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 d1h5'],
            ['Combo 26', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7 e8f7 d1h5'],
            ['Combo 27', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7 f8e7 f7d8'],
            ['Combo 28', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8e7'],
            ['Combo 29', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'd1e2 e8g8 c4f7 f8e7 f7g8'],
            ['Combo 30', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5 f7g8 d5c6 b8c6'],
            ['Combo 31', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 f3g5 f7g8 g5h7'],
            ['Combo 32', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 d1h5 g7g6 h5f7'],
            ['Combo 33', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8f6'],
            ['Combo 34', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 h7h6 g5f7 e8f7 c4f7'],
            ['Combo 35', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 f3g5 f7g8 g5e6'],
            ['Combo 36', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3e5 d8e7 e5f7 e8f7 c4f7'],
            ['Combo 37', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5h7 f8h6'],
            ['Combo 38', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5 f7g8 g5e6'],
            ['Combo 39', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7 e8f7 d1f3'],
            ['Combo 40', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'd1f3 e8g8 c4f7 f8e7 f7g8'],
            ['Combo 41', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8'],
            ['Combo 42', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7 f8e7 f7d8 e7d8 c4f7'],
        ];
    }

    /** @return list<array{title:string,fen:string,solution:string}> */
    private static function hardTemplates(): array
    {
        return [
            ['Smothered mate pattern', 'rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3', 'c4f7 e8e7 f7d5 e7f8 d5e6'],
            ['Long combination', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7'],
            ['Deep calculation', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7 f8e7 f7d8 e7d8 c4f7'],
            ['Multi-move attack', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5 f7g8 d5c6'],
            ['Sacrifice idea', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8'],
            ['Complex middlegame', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7 e7d8'],
            ['Endgame conversion', '6k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1', 'e1e8 f8e8 g1f2 e8f8 f2f3'],
            ['Advanced tactic', 'r1bqkb1r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8'],
            ['Quiet killer', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'd1e2 e8g8 c4f7 f8e7 f7g8'],
            ['Calculation drill', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7 e8f7 d1h5 g7g6 h5e5'],
            ['Master level', 'rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3', 'c4f7 e8e7 f7d5 e7f8 d5e6 f8g8 e6c8'],
            ['Grandmaster punch', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7 e7c7 d1h5'],
            ['Deep fork line', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8 h6f8'],
            ['Zugzwang theme', '7k/8/8/8/8/8/6PP/6K1 w - - 0 1', 'g2g3 h8g8 g1f2 g8f8 f2e3'],
            ['Opposite side castling', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5 f7g8 d5c6 b8c6'],
            ['Piece sacrifice', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 f3g5 f7g8 g5h7 f8h6 h7f8'],
            ['King safety breach', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 h7h6 g5f7 e8f7 c4f7'],
            ['Prophylaxis then strike', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'h2h3 h7h6 c4f7 e8f7 f3g5'],
            ['Exchange sacrifice line', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7'],
            ['Double rook lift', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3', 'f1e1 e8e7 e1e5 d8e8 e5e7'],
            ['Battery attack', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 d1h5 g7g6 h5f7'],
            ['Mating net', 'rnb1kbnr/pppp1ppp/8/4q3/2B1P3/8/PPPP1PPP/RNBQK1NR w KQkq - 4 3', 'c4f7 e8e7 f7d5 e7f8 d5c6'],
            ['Counterattack parry', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5 f7g8 d5c6 b8c6 d1h5'],
            ['Quiet move wins', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'd1e2 e8g8 c4f7 f8e7 f7g8 a8d8'],
            ['Final blow', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8f6 e6f8 g8f8'],
            ['Tactical theme 26', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5 f7g8 g5h7'],
            ['Tactical theme 27', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7 e8f7 d1h5'],
            ['Tactical theme 28', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7 f8e7 f7d8'],
            ['Tactical theme 29', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5 f7g8 d5c6'],
            ['Tactical theme 30', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6'],
            ['Tactical theme 31', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3e5 c6e5 c4f7 e8f7 d1h5'],
            ['Tactical theme 32', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3', 'f1e1 e8e7 e1e7 e7e8'],
            ['Tactical theme 33', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 f3g5 f7g8 g5e6'],
            ['Tactical theme 34', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'c4f7 e8f7 d1f3 f7g8 f3f7'],
            ['Tactical theme 35', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 f8e7 g5f7 e8f7 c4f7'],
            ['Tactical theme 36', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5h7'],
            ['Tactical theme 37', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'c4f7 e8f7 d1h5 g7g6 h5f7'],
            ['Tactical theme 38', 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 3', 'f3e5 c6e5 c4f7 e8f7 d1h5 g7g6'],
            ['Tactical theme 39', 'rnbqkb1r/pppp1ppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'f3g5 e8g8 g5f7 f8e7 f7d8'],
            ['Tactical theme 40', 'r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 0 4', 'c4f7 e8f7 f3g5 f7g8 g5e6 d8e7 e6c7'],
            ['Tactical theme 41', 'rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4', 'd1e2 e8g8 c4f7 f8e7 f7g8 a8d8'],
            ['Tactical theme 42', 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4', 'h5f7 e8f7 c4d5 f7g8 d5c6 b8c6 d1h5'],
        ];
    }

    /** @return array<int, string|null> */
    private static function emptyRank(): array
    {
        return array_fill(0, 8, null);
    }

    /** @param array<int, string|null> $squares */
    private static function encodeRank(array $squares): string
    {
        $s = '';
        $empty = 0;
        foreach ($squares as $sq) {
            if ($sq === null) {
                $empty++;
            } else {
                if ($empty > 0) {
                    $s .= $empty;
                    $empty = 0;
                }
                $s .= $sq;
            }
        }
        if ($empty > 0) {
            $s .= $empty;
        }

        return $s === '' ? '8' : $s;
    }

    private static function fileChar(int $file): string
    {
        return chr(ord('a') + $file);
    }

    private static function mirrorFen(string $fen): string
    {
        $parts = explode(' ', $fen);
        $ranks = explode('/', $parts[0]);
        $mirrored = array_map(static function (string $rank): string {
            $expanded = [];
            foreach (str_split($rank) as $ch) {
                if (ctype_digit($ch)) {
                    $expanded = array_merge($expanded, array_fill(0, (int) $ch, '1'));
                } else {
                    $expanded[] = $ch;
                }
            }
            $flipped = array_reverse($expanded);
            $out = '';
            $empty = 0;
            foreach ($flipped as $sq) {
                if ($sq === '1') {
                    $empty++;
                } else {
                    if ($empty > 0) {
                        $out .= $empty;
                        $empty = 0;
                    }
                    $out .= $sq;
                }
            }
            if ($empty > 0) {
                $out .= $empty;
            }

            return $out === '' ? '8' : $out;
        }, $ranks);
        $parts[0] = implode('/', $mirrored);

        return implode(' ', $parts);
    }

    private static function mirrorUciLine(string $moves): string
    {
        $out = [];
        foreach (preg_split('/\s+/', trim($moves)) ?: [] as $uci) {
            if (strlen($uci) >= 4) {
                $out[] = self::mirrorSquare($uci[0]) . $uci[1] . self::mirrorSquare($uci[2]) . $uci[3] . substr($uci, 4);
            }
        }

        return implode(' ', $out);
    }

    private static function mirrorSquare(string $file): string
    {
        $idx = ord($file) - ord('a');

        return chr(ord('a') + (7 - $idx));
    }
}
