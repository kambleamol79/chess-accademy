<?php

declare(strict_types=1);

/**
 * Hostinger entry point when the web root is the api/ folder parent.
 * Apache/LiteSpeed rewrite: brainstorm/api/* → brainstorm/api/index.php
 */
require __DIR__ . '/public/index.php';
