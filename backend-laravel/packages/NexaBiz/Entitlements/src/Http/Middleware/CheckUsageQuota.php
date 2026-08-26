<?php

namespace NexaBiz\Entitlements\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use NexaBiz\Core\Exceptions\ForbiddenException;
use NexaBiz\Entitlements\Services\UsageLimitService;
use Symfony\Component\HttpFoundation\Response;

class CheckUsageQuota
{
    public function __construct(
        private readonly UsageLimitService $limitService
    ) {}

    public function handle(Request $request, Closure $next, string $meterKey): Response
    {
        $companyId = $request->header('X-Company-Id') ?? $request->input('company_id');

        if ($companyId) {
            try {
                $this->limitService->checkQuota($companyId, $meterKey);
            } catch (\Throwable $e) {
                throw new ForbiddenException($e->getMessage());
            }
        }

        return $next($request);
    }
}
