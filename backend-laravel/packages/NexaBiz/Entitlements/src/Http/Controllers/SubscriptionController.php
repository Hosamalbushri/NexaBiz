<?php

namespace NexaBiz\Entitlements\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use NexaBiz\Core\Exceptions\ValidationAppException;
use NexaBiz\Core\Http\Controllers\Controller;
use NexaBiz\Entitlements\Services\SubscriptionService;
use NexaBiz\Entitlements\Services\UsageLimitService;

class SubscriptionController extends Controller
{
    public function __construct(
        private readonly SubscriptionService $service,
        private readonly UsageLimitService $limitService
    ) {}

    public function show(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-Id') ?? $request->input('company_id');
        if (! $companyId) {
            throw new ValidationAppException('Header X-Company-Id is required.');
        }

        $subscription = $this->service->getActiveSubscription($companyId);

        return response()->json([
            'data' => $subscription,
        ]);
    }

    public function change(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-Id') ?? $request->input('company_id');
        $planId = $request->input('plan_id');
        $packages = $request->input('packages', $request->input('add_on_packages', []));
        $idempotencyKey = $request->header('Idempotency-Key') ?? $request->input('idempotency_key');

        if (! $companyId || ! $planId) {
            throw new ValidationAppException('Parameters X-Company-Id and plan_id are required.');
        }

        $updatedEntitlement = $this->service->changeSubscription(
            $companyId,
            $planId,
            $packages,
            $idempotencyKey
        );

        return response()->json([
            'message' => 'Subscription updated successfully.',
            'entitlement' => $updatedEntitlement,
        ]);
    }

    public function cancel(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-Id') ?? $request->input('company_id');
        if (! $companyId) {
            throw new ValidationAppException('Header X-Company-Id is required.');
        }

        $updatedEntitlement = $this->service->cancelSubscription($companyId);

        return response()->json([
            'message' => 'Subscription cancelled successfully.',
            'entitlement' => $updatedEntitlement,
        ]);
    }

    public function usage(Request $request): JsonResponse
    {
        $companyId = $request->header('X-Company-Id') ?? $request->input('company_id');
        if (! $companyId) {
            throw new ValidationAppException('Header X-Company-Id is required.');
        }

        $summary = $this->limitService->getUsageSummary($companyId);

        return response()->json([
            'data' => $summary,
        ]);
    }

    public function checkout(Request $request, ?string $company = null): JsonResponse
    {
        $companyId = $company ?? $request->header('X-Company-Id') ?? $request->input('company_id');
        $planId = $request->input('plan_id');
        $packages = $request->input('packages', $request->input('package_codes', []));

        if (! $companyId || ! $planId) {
            throw new ValidationAppException('Parameters company and plan_id are required.');
        }

        $result = $this->service->checkoutSubscription($companyId, $planId, $packages);

        return response()->json([
            'data' => $result,
        ]);
    }

    public function activate(Request $request, ?string $company = null): JsonResponse
    {
        $companyId = $company ?? $request->header('X-Company-Id') ?? $request->input('company_id');
        $subscriptionId = $request->input('subscription_id', '');
        $paymentReference = $request->input('payment_reference');
        $idempotencyKey = $request->header('Idempotency-Key') ?? $request->input('idempotency_key');

        if (! $companyId) {
            throw new ValidationAppException('Company ID parameter is required.');
        }

        $result = $this->service->activateSubscription(
            $companyId,
            $subscriptionId,
            $paymentReference,
            $idempotencyKey
        );

        return response()->json([
            'message' => 'Subscription activated successfully.',
            'data' => $result,
        ]);
    }
}
