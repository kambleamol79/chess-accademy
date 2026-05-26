<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

use Psr\Http\Message\UploadedFileInterface;

final class PaymentReceiptUploadService
{
    /** @var list<string> */
    private const ALLOWED_MIME = [
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
    ];

    public function __construct(
        private readonly string $storageDir,
        private readonly int $maxBytes,
    ) {}

    public function store(UploadedFileInterface $file): string
    {
        if ($file->getError() !== UPLOAD_ERR_OK) {
            throw new \InvalidArgumentException('Payment receipt upload failed');
        }

        if ($file->getSize() !== null && $file->getSize() > $this->maxBytes) {
            throw new \InvalidArgumentException('Payment receipt must be 5 MB or smaller');
        }

        $clientName = (string) $file->getClientFilename();
        $ext = strtolower(pathinfo($clientName, PATHINFO_EXTENSION));
        $ext = match ($ext) {
            'pdf', 'jpg', 'jpeg', 'png', 'webp' => $ext,
            default => throw new \InvalidArgumentException('Receipt must be PDF, JPG, PNG, or WEBP'),
        };

        $mime = $file->getClientMediaType();
        if ($mime !== null && $mime !== '' && !in_array($mime, self::ALLOWED_MIME, true)) {
            throw new \InvalidArgumentException('Invalid receipt file type');
        }

        if (!is_dir($this->storageDir) && !mkdir($this->storageDir, 0755, true) && !is_dir($this->storageDir)) {
            throw new \RuntimeException('Could not create upload directory');
        }

        $storedName = bin2hex(random_bytes(16)) . '.' . $ext;
        $target = $this->storageDir . DIRECTORY_SEPARATOR . $storedName;
        $file->moveTo($target);

        return $storedName;
    }

    public function resolvePath(string $storedName): ?string
    {
        if ($storedName === '' || str_contains($storedName, '/') || str_contains($storedName, '\\')) {
            return null;
        }

        $path = $this->storageDir . DIRECTORY_SEPARATOR . $storedName;
        if (!is_file($path)) {
            return null;
        }

        return $path;
    }
}
