<?php

declare(strict_types=1);

namespace ChessAcademy\Repositories;

use PDO;

final class MaterialRepository
{
    public function __construct(private readonly PDO $pdo) {}

    /** @return list<array<string,mixed>> */
    public function findAll(?int $formId = null): array
    {
        $sql = 'SELECT m.*, f.batch FROM class_materials m
                INNER JOIN forms f ON f.id = m.form_id WHERE 1=1';
        $params = [];
        if ($formId !== null) {
            $sql .= ' AND m.form_id = :form_id';
            $params['form_id'] = $formId;
        }
        $sql .= ' ORDER BY m.id DESC';
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);

        return $stmt->fetchAll();
    }

    /** @return array<string,mixed>|null */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare('SELECT * FROM class_materials WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch();

        return $row === false ? null : $row;
    }

    /** @param array<string,mixed> $data */
    public function create(array $data): array
    {
        $stmt = $this->pdo->prepare(
            'INSERT INTO class_materials (form_id, title, type, url, uploaded_by)
             VALUES (:form_id, :title, :type, :url, :uploaded_by)'
        );
        $stmt->execute([
            'form_id' => $data['form_id'],
            'title' => $data['title'],
            'type' => $data['type'] ?? 'link',
            'url' => $data['url'],
            'uploaded_by' => $data['uploaded_by'] ?? null,
        ]);

        return $this->findById((int) $this->pdo->lastInsertId()) ?? [];
    }

    public function delete(int $id): bool
    {
        $stmt = $this->pdo->prepare('DELETE FROM class_materials WHERE id = :id');
        $stmt->execute(['id' => $id]);

        return $stmt->rowCount() > 0;
    }
}
