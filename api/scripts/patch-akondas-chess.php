<?php

declare(strict_types=1);

/**
 * akondas/chess.php uses $str{$i} removed in PHP 8.4+. Re-apply after composer install/update.
 */
$target = dirname(__DIR__) . '/vendor/akondas/chess.php/src/Chess.php';
if (!is_file($target)) {
    fwrite(STDERR, "akondas/chess.php not installed — skip patch.\n");
    exit(0);
}

$source = file_get_contents($target);
if ($source === false) {
    fwrite(STDERR, "Could not read Chess.php\n");
    exit(1);
}

// Curly-brace string/array offset (removed in PHP 8.4+).
$patched = preg_replace('/(\$\w+(?:\[[^\]]+\])?)\{(\d+)\}/', "\$1[\$2]", $source);
if ($patched === null) {
    fwrite(STDERR, "Regex patch failed\n");
    exit(1);
}

if ($patched === $source) {
    echo "akondas/chess.php already patched (PHP 8.4+ compatible).\n");
    exit(0);
}

file_put_contents($target, $patched);
echo "Patched akondas/chess.php for PHP 8.4+ offset syntax.\n";
