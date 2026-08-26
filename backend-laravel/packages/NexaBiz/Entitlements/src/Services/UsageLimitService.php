<?php

namespace NexaBiz\Entitlements\Services;

use NexaBiz\Core\Exceptions\AppException;
use NexaBiz\Entitlements\Models\UsageMeter;

class UsageLimitService
{
    public function checkQuota(string $companyId, string $meterKey, int $requestedIncrement = 1): void
    {
        $meter = UsageMeter::where('company_id', $companyId)
            ->where('meter_key', $meterKey)
            ->first();

        if (! $meter) {
            return; // No limit configured for this meter
        }

        if ($meter->max_limit > 0 && ($meter->current_value + $requestedIncrement) > $meter->max_limit) {
            throw new AppException(
                'quota_exceeded',
                "Usage limit reached for meter '{$meterKey}'. Limit: {$meter->max_limit}, Used: {$meter->current_value}.",
                402
            );
        }
    }

    public function recordUsage(string $companyId, string $meterKey, int $increment = 1): UsageMeter
    {
        $meter = UsageMeter::firstOrCreate(
            ['company_id' => $companyId, 'meter_key' => $meterKey],
            ['current_value' => 0, 'max_limit' => 0]
        );

        $meter->increment('current_value', $increment);

        return $meter->fresh();
    }

    public function getUsageSummary(string $companyId): array
    {
        $meters = UsageMeter::where('company_id', $companyId)->get();
        $summary = [];

        foreach ($meters as $meter) {
            $limit = $meter->max_limit;
            $used = $meter->current_value;
            $remaining = $limit > 0 ? max(0, $limit - $used) : null;

            $summary[] = [
                'meter_key' => $meter->meter_key,
                'limit' => $limit,
                'used' => $used,
                'remaining' => $remaining,
                'reset_period' => $meter->reset_period,
            ];
        }

        return $summary;
    }
}
