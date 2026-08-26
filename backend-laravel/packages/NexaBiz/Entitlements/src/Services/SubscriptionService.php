<?php

namespace NexaBiz\Entitlements\Services;

use Illuminate\Support\Str;
use NexaBiz\Core\Exceptions\AppException;
use NexaBiz\Core\Exceptions\ConflictException;
use NexaBiz\Entitlements\Contracts\PaymentGateway;
use NexaBiz\Entitlements\Models\Package;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Models\Subscription;
use NexaBiz\Entitlements\Models\SubscriptionEvent;

class SubscriptionService
{
    public function __construct(
        private readonly EntitlementResolver $resolver,
        private readonly PackageResolver $packageResolver,
        private readonly PaymentGateway $paymentGateway
    ) {}

    public function getActiveSubscription(string $companyId): ?Subscription
    {
        return Subscription::with(['plan.packages', 'items.package'])
            ->where('company_id', $companyId)
            ->first();
    }

    public function changeSubscription(
        string $companyId,
        string $planId,
        array $requestedPackageCodes = [],
        ?string $idempotencyKey = null
    ): array {
        $idempotencyKey = $idempotencyKey ?? 'sub_change_'.$companyId.'_'.time();

        // Check idempotency
        $existingEvent = SubscriptionEvent::where('idempotency_key', $idempotencyKey)->first();
        if ($existingEvent) {
            return $this->resolver->resolveForCompany($companyId);
        }

        $plan = Plan::where('id', $planId)->orWhere('code', $planId)->first();
        if (! $plan) {
            throw new AppException("Plan '{$planId}' not found.", 404);
        }

        // Server-side package dependency resolution
        $resolvedPackageCodes = $this->packageResolver->resolveDependencies($requestedPackageCodes);

        $subscription = Subscription::updateOrCreate(
            ['company_id' => $companyId],
            [
                'plan_id' => $plan->id,
                'status' => $plan->is_free ? 'free' : 'active',
                'starts_at' => now(),
                'ends_at' => $plan->is_free ? null : now()->addYear(),
                'grace_ends_at' => null,
                'cancelled_at' => null,
            ]
        );

        // Clear existing subscription items and re-attach resolved add-ons
        $subscription->items()->delete();

        $addonPackages = Package::whereIn('code', $resolvedPackageCodes)
            ->where('is_addon', true)
            ->get();

        foreach ($addonPackages as $pkg) {
            $subscription->items()->create([
                'id' => (string) Str::uuid(),
                'package_id' => $pkg->id,
                'status' => 'active',
                'is_addon' => true,
                'quantity' => 1,
                'starts_at' => now(),
            ]);
        }

        // Record Audit / Idempotency Event
        SubscriptionEvent::create([
            'id' => (string) Str::uuid(),
            'company_id' => $companyId,
            'subscription_id' => $subscription->id,
            'event_type' => 'subscription_changed',
            'payload' => [
                'plan_id' => $plan->id,
                'plan_code' => $plan->code,
                'requested_packages' => $requestedPackageCodes,
                'resolved_packages' => $resolvedPackageCodes,
            ],
            'idempotency_key' => $idempotencyKey,
            'created_at' => now(),
        ]);

        return $this->resolver->resolveForCompany($companyId);
    }

    public function cancelSubscription(string $companyId): array
    {
        $freePlan = Plan::where('is_free', true)->first();
        $planId = $freePlan?->id ?? 'plan_free';

        $subscription = Subscription::where('company_id', $companyId)->first();
        if ($subscription) {
            $subscription->update([
                'status' => 'cancelled',
                'cancelled_at' => now(),
            ]);
        } else {
            $subscription = Subscription::create([
                'id' => (string) Str::uuid(),
                'company_id' => $companyId,
                'plan_id' => $planId,
                'status' => 'cancelled',
                'starts_at' => now(),
                'cancelled_at' => now(),
            ]);
        }

        return $this->resolver->resolveForCompany($companyId);
    }

    public function checkoutSubscription(
        string $companyId,
        string $planId,
        array $requestedPackageCodes = []
    ): array {
        $plan = Plan::where('id', $planId)->orWhere('code', $planId)->first();
        if (! $plan) {
            throw new AppException("Plan '{$planId}' not found.", 404);
        }

        $resolvedPackageCodes = $this->packageResolver->resolveDependencies($requestedPackageCodes);

        $subscription = Subscription::updateOrCreate(
            ['company_id' => $companyId],
            [
                'plan_id' => $plan->id,
                'status' => 'pending_payment',
                'starts_at' => now(),
                'ends_at' => null,
                'grace_ends_at' => null,
                'cancelled_at' => null,
            ]
        );

        $subscription->items()->delete();
        $addonPackages = Package::whereIn('code', $resolvedPackageCodes)
            ->where('is_addon', true)
            ->get();

        foreach ($addonPackages as $pkg) {
            $subscription->items()->create([
                'id' => (string) Str::uuid(),
                'package_id' => $pkg->id,
                'status' => 'pending_payment',
                'is_addon' => true,
                'quantity' => 1,
                'starts_at' => now(),
            ]);
        }

        return [
            'subscription_id' => (string) $subscription->id,
            'company_id' => $companyId,
            'plan_id' => $plan->id,
            'plan_code' => $plan->code,
            'status' => 'pending_payment',
            'price' => $plan->price ?? 49.00,
            'currency' => 'USD',
            'package_codes' => $resolvedPackageCodes,
        ];
    }

    public function activateSubscription(
        string $companyId,
        string $subscriptionId,
        ?string $paymentReference = null,
        ?string $idempotencyKey = null
    ): array {
        $idempotencyKey = $idempotencyKey ?? 'sub_act_'.$subscriptionId.'_'.time();

        $existingEvent = SubscriptionEvent::where('idempotency_key', $idempotencyKey)->first();
        if ($existingEvent) {
            return [
                'subscription' => $this->getActiveSubscription($companyId),
                'entitlement' => $this->resolver->resolveForCompany($companyId),
            ];
        }

        $subscription = Subscription::where('company_id', $companyId)
            ->where('id', $subscriptionId)
            ->first();

        if (! $subscription) {
            // Fallback to active subscription for company
            $subscription = Subscription::where('company_id', $companyId)->first();
        }

        if (! $subscription) {
            throw new AppException("Subscription '{$subscriptionId}' not found for company.", 404);
        }

        $subscription->update([
            'status' => 'active',
            'starts_at' => now(),
            'ends_at' => now()->addYear(),
            'grace_ends_at' => null,
            'cancelled_at' => null,
        ]);

        $subscription->items()->update(['status' => 'active']);

        SubscriptionEvent::create([
            'id' => (string) Str::uuid(),
            'company_id' => $companyId,
            'subscription_id' => $subscription->id,
            'event_type' => 'subscription_activated',
            'payload' => [
                'payment_reference' => $paymentReference ?? 'PAY-MANUAL-'.Str::upper(Str::random(6)),
                'activated_at' => now()->toIso8601String(),
            ],
            'idempotency_key' => $idempotencyKey,
            'created_at' => now(),
        ]);

        // Update CompanyProvisioning status if exists
        \NexaBiz\Identity\Models\CompanyProvisioning::query()
            ->where('server_company_id', $companyId)
            ->update(['status' => 'SUBSCRIPTION_ACTIVE']);

        $entitlement = $this->resolver->resolveForCompany($companyId);

        return [
            'subscription' => $subscription->fresh(['plan.packages', 'items.package']),
            'entitlement' => $entitlement,
        ];
    }
}
