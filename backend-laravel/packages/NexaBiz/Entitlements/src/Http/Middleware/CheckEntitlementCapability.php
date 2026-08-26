<?php

namespace NexaBiz\Entitlements\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use NexaBiz\Core\Exceptions\ForbiddenException;
use NexaBiz\Entitlements\Services\EntitlementResolver;
use Symfony\Component\HttpFoundation\Response;

class CheckEntitlementCapability
{
    public function __construct(
        private readonly EntitlementResolver $resolver
    ) {}

    public function handle(Request $request, Closure $next, string $capability): Response
    {
        $authContext = $request->attributes->get('auth_context');
        $companyId = $authContext?->companyId ?? $request->header('X-Company-Id') ?? $request->input('company_id');

        if (! $companyId) {
            throw new ForbiddenException('Company ID is missing for entitlement validation.');
        }

        $snapshot = $this->resolver->resolveForCompany($companyId);
        $capabilities = $snapshot['capabilities'] ?? [];
        $status = $snapshot['status'] ?? 'expired';

        if ($status === 'expired' || $status === 'cancelled') {
            throw new ForbiddenException("Entitlement status is '{$status}'. Access denied.");
        }

        if (! in_array($capability, $capabilities, true)) {
            throw new ForbiddenException("Entitlement capability '{$capability}' is required for this operation.");
        }

        return $next($request);
    }
}
