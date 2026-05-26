<?php

declare(strict_types=1);

namespace ChessAcademy\Services;

final class LeadCsvParser
{
    /** @var array<string, string> */
    private const HEADER_MAP = [
        'DATE' => 'captured_at',
        'CHILD NA' => 'child_name',
        'CHILD NAME' => 'child_name',
        'CHILD_NAME' => 'child_name',
        'PARENTS' => 'parents_name',
        'PARENTS NAME' => 'parents_name',
        'NUMBER' => 'phone',
        'PHONE' => 'phone',
        'MAIL' => 'email',
        'EMAIL' => 'email',
        'AGE' => 'age',
        'STD' => 'std',
        'STANDARD' => 'std',
        'CITY' => 'city',
        'Q1' => 'q1',
        'Q2' => 'q2',
        'Q3' => 'q3',
        'TIME' => 'time_slot',
        'TIME SLOT' => 'time_slot',
        'ATTD - NO' => 'attd_no',
        'ATTD-NO' => 'attd_no',
        'ATTD' => 'attd_no',
        'MODULE' => 'module',
        'INT' => 'status_int',
        'INTERESTED' => 'status_int',
        'NOT INT' => 'not_interested',
        'NOT INT.' => 'not_interested',
        'PAID' => 'paid',
        'DNP' => 'dnp',
        'ADDITIONAL REVIEW' => 'review',
        'ADDITIONAL' => 'additional',
        'REVIEW' => 'review',
    ];

    /**
     * @return array{rows: list<array<string, mixed>>, errors: list<array{row: int, message: string}>}
     */
    public function parse(string $csv): array
    {
        $csv = trim($csv);
        if ($csv === '') {
            return ['rows' => [], 'errors' => []];
        }

        $stream = fopen('php://memory', 'r+b');
        if ($stream === false) {
            return [];
        }

        fwrite($stream, $csv);
        rewind($stream);

        $header = null;
        $rows = [];
        $errors = [];
        $lineNum = 0;

        while (($line = fgetcsv($stream)) !== false) {
            $lineNum++;
            if ($line === [null] || $line === []) {
                continue;
            }

            $line = array_map(static fn ($v) => trim((string) $v), $line);

            if ($header === null) {
                $header = $this->mapHeader($line);
                continue;
            }

            $mapped = $this->mapRow($header, $line);
            if ($mapped['row'] !== null) {
                $rows[] = $mapped['row'];
            } elseif ($mapped['error'] !== null) {
                $errors[] = ['row' => $lineNum, 'message' => $mapped['error']];
            }
        }

        fclose($stream);

        return ['rows' => $rows, 'errors' => $errors];
    }

    /** @param list<string> $headerRow @return list<string|null> */
    private function mapHeader(array $headerRow): array
    {
        $mapped = [];
        foreach ($headerRow as $cell) {
            $key = strtoupper(preg_replace('/\s+/', ' ', $cell) ?? $cell);
            $mapped[] = self::HEADER_MAP[$key] ?? null;
        }

        return $mapped;
    }

    /**
     * @param list<string|null> $header
     * @param list<string> $values
     * @return array{row: array<string, mixed>|null, error: string|null}
     */
    private function mapRow(array $header, array $values): array
    {
        $data = [];
        $hasData = false;

        foreach ($header as $i => $field) {
            if ($field === null || !isset($values[$i])) {
                continue;
            }
            $value = trim($values[$i]);
            if ($value === '') {
                continue;
            }
            $hasData = true;
            $data[$field] = $this->normalizeValue($field, $value);
        }

        if (!$hasData) {
            return ['row' => null, 'error' => null];
        }

        if (!isset($data['child_name']) || trim((string) $data['child_name']) === '') {
            return ['row' => null, 'error' => 'Child name is required'];
        }

        if (!isset($data['captured_at'])) {
            $data['captured_at'] = date('Y-m-d H:i:s');
        }

        $data = $this->mergeAdditionalReviewFields($data);

        return ['row' => $data, 'error' => null];
    }

    private function normalizeValue(string $field, string $value): mixed
    {
        return match ($field) {
            'captured_at' => $this->parseDate($value),
            'q1', 'q2', 'q3' => $this->normalizeYesNo($value),
            'status_int' => strtoupper($value) === 'INT' || strtolower($value) === 'yes' ? 'INT' : $value,
            'paid' => strtoupper($value) === 'PAID' || strtolower($value) === 'yes' ? 'PAID' : $value,
            default => $value,
        };
    }

    private function parseDate(string $value): string
    {
        $ts = strtotime($value);

        return $ts !== false ? date('Y-m-d H:i:s', $ts) : date('Y-m-d H:i:s');
    }

    /** @param array<string, mixed> $data @return array<string, mixed> */
    private function mergeAdditionalReviewFields(array $data): array
    {
        $additional = trim((string) ($data['additional'] ?? ''));
        $review = trim((string) ($data['review'] ?? ''));

        if ($additional === '' && $review === '') {
            return $data;
        }

        $parts = array_values(array_filter([$additional, $review], static fn (string $s) => $s !== ''));
        $data['review'] = implode("\n\n", $parts);
        $data['additional'] = null;

        return $data;
    }

    private function normalizeYesNo(string $value): ?string
    {
        $v = strtolower(trim($value));
        if (in_array($v, ['yes', 'y', '1'], true)) {
            return 'Yes';
        }
        if (in_array($v, ['no', 'n', '0'], true)) {
            return 'No';
        }

        return in_array(ucfirst($v), ['Yes', 'No'], true) ? ucfirst($v) : null;
    }
}
