<?php

namespace NexaBiz\Entitlements\Services;

use NexaBiz\Entitlements\Models\CompanyEntitlement;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Models\Subscription;
use NexaBiz\Entitlements\Models\UsageMeter;

class EntitlementResolver
{
    public function resolveForCompany(string $companyId): array
    {
        $subscription = Subscription::with(['plan.packages.features', 'items.package.features'])
            ->where('company_id', $companyId)
            ->first();

        if (! $subscription) {
            $freePlan = Plan::where('is_free', true)->first();
            $planId = $freePlan?->id ?? 'plan_free';
            $tier = 'free';
            $status = 'active';
            $packageCodes = [];
            $capabilities = [];
            $limits = [];
            $graceUntil = null;
        } else {
            $tier = $subscription->plan->is_free ? 'free' : ($subscription->plan->code === 'enterprise' ? 'enterprise' : 'premium');
            $status = $subscription->status;
            $planId = $subscription->plan_id;

            $packageCodes = [];
            $capabilities = [];
            $limits = [];

            // Add plan packages
            if ($subscription->plan) {
                foreach ($subscription->plan->packages as $package) {
                    if (! $package->is_active) {
                        continue;
                    }
                    $packageCodes[] = $package->code;
                    foreach ($package->features as $feature) {
                        $capabilities[] = $feature->capability_code;
                    }
                    foreach ($package->limits as $lim) {
                        $limits[$lim->limit_key] = $lim->default_value;
                    }
                }
            }

            // Add active subscription items (add-ons)
            foreach ($subscription->items as $item) {
                if ($item->status === 'active' && $item->package && $item->package->is_active) {
                    $packageCodes[] = $item->package->code;
                    foreach ($item->package->features as $feature) {
                        $capabilities[] = $feature->capability_code;
                    }
                    foreach ($item->package->limits as $lim) {
                        $limits[$lim->limit_key] = $lim->default_value * $item->quantity;
                    }
                }
            }

            $graceUntil = $subscription->grace_ends_at?->toIso8601String();
        }

        if (config('nexabiz.allow_dev_token') && $companyId === config('nexabiz.default_company_id')) {
            $capabilities[] = 'sync';
            $packageCodes[] = 'cloud_sync';
        }

        $capabilities = array_values(array_unique($capabilities));
        $packageCodes = array_values(array_unique($packageCodes));

        // Fetch usage meters
        $usageMeters = UsageMeter::where('company_id', $companyId)->get();
        $usage = [];
        foreach ($usageMeters as $meter) {
            $usage[$meter->meter_key] = $meter->current_value;
        }

        $snapshot = [
            'company_id' => $companyId,
            'plan_id' => $planId,
            'tier' => $tier,
            'status' => $status,
            'capabilities' => $capabilities,
            'package_codes' => $packageCodes,
            'limits' => $limits,
            'usage' => $usage,
            'verified_at' => now()->utc()->toIso8601String(),
            'grace_until' => $graceUntil,
        ];

        $checksum = hash_hmac('sha256', json_encode($snapshot), config('app.key', 'nexabiz-secret-key'));

        if ($subscription) {
            CompanyEntitlement::updateOrCreate(
                ['company_id' => $companyId],
                [
                    'subscription_id' => $subscription->id,
                    'snapshot_data' => $snapshot,
                    'checksum' => $checksum,
                    'verified_at' => now(),
                    'expires_at' => $subscription->ends_at ?? $subscription->grace_ends_at,
                ]
            );
        }

        return $snapshot;
    }
}
