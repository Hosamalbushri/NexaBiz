<?php

namespace NexaBiz\Entitlements\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use NexaBiz\Core\Exceptions\NotFoundException;
use NexaBiz\Core\Exceptions\ValidationAppException;
use NexaBiz\Core\Http\Controllers\Controller;
use NexaBiz\Entitlements\Models\Package;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Services\EntitlementResolver;

class EntitlementController extends Controller
{
    public function __construct(
        private readonly EntitlementResolver $resolver
    ) {}

    public function show(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-Id') ?? $request->input('company_id');

        if (! $companyId) {
            throw new ValidationAppException('Header X-Company-Id is required for entitlement resolution.');
        }

        $entitlement = $this->resolver->resolveForCompany($companyId);

        return response()->json($entitlement);
    }

    public function plans(): JsonResponse
    {
        $plans = Plan::with('packages.features')
            ->where('is_active', true)
            ->orderBy('sort_order', 'asc')
            ->get();

        return response()->json([
            'data' => $plans,
        ]);
    }

    public function showPlan(string $planId): JsonResponse
    {
        $plan = Plan::with('packages.features')
            ->where('id', $planId)
            ->orWhere('code', $planId)
            ->first();

        if (! $plan) {
            throw new NotFoundException("Plan '{$planId}' not found.");
        }

        return response()->json([
            'data' => $plan,
        ]);
    }

    public function packages(): JsonResponse
    {
        $packages = Package::with(['features', 'dependencies'])
            ->where('is_active', true)
            ->get();

        return response()->json([
            'data' => $packages,
        ]);
    }

    public function showPackage(string $packageId): JsonResponse
    {
        $package = Package::with(['features', 'dependencies'])
            ->where('id', $packageId)
            ->orWhere('code', $packageId)
            ->first();

        if (! $package) {
            throw new NotFoundException("Package '{$packageId}' not found.");
        }

        return response()->json([
            'data' => $package,
        ]);
    }
}
