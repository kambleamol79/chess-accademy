<?php

declare(strict_types=1);

namespace ChessAcademy\Controllers;

use ChessAcademy\Http\JsonResponse;
use ChessAcademy\Repositories\CoachRepository;
use ChessAcademy\Repositories\DashboardRepository;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;

final class DashboardController
{
    use JsonResponse;

    public function __construct(
        private readonly DashboardRepository $dashboard,
        private readonly CoachRepository $coaches
    ) {}

    public function metrics(Request $request, Response $response): Response
    {
        return $this->success($response, $this->dashboard->metrics());
    }

    public function coachSchedule(Request $request, Response $response): Response
    {
        $authUser = $request->getAttribute('user');
        if (!is_array($authUser)) {
            return $this->error($response, 'Unauthorized', 401);
        }

        $coach = $this->coaches->findByUserId((int) $authUser['id']);
        if ($coach === null) {
            return $this->error($response, 'Coach not found', 404);
        }

        $assignments = $this->coaches->findAssignedBatches((int) $coach['id']);
        $timeSlots = [];
        foreach ($assignments as $row) {
            $timeSlots[$row['time']] = true;
        }
        $timeSlots = array_keys($timeSlots);
        sort($timeSlots);

        return $this->success($response, [
            'coach' => [
                'id' => (int) $coach['id'],
                'first_name' => $coach['first_name'],
                'last_name' => $coach['last_name'],
                'display_name' => strtoupper(trim("{$coach['first_name']} {$coach['last_name']}")),
            ],
            'days' => ['MON', 'TUE', 'WED', 'THUR', 'FRI', 'SAT'],
            'time_slots' => $timeSlots,
            'assignments' => $assignments,
        ]);
    }
}
