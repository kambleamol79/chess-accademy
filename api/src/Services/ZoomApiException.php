<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

final class ZoomApiException extends \RuntimeException
{
    public function __construct(
        string $message,
        private readonly int $httpStatus = 0,
        private readonly string $responseBody = '',
        ?\Throwable $previous = null,
    ) {
        parent::__construct($message, $httpStatus, $previous);
    }

    public function httpStatus(): int
    {
        return $this->httpStatus;
    }

    public function responseBody(): string
    {
        return $this->responseBody;
    }
}
