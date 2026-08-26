<?php

namespace NexaBiz\Entitlements\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Models\Feature;
use NexaBiz\Entitlements\Models\Package;
use NexaBiz\Entitlements\Models\PackageLimit;
use NexaBiz\Entitlements\Models\Plan;

class PlanSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Base Commercial Packages
        $syncPkg = Package::firstOrCreate(
            ['code' => 'cloud_sync'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Cloud Sync & Backup Package',
                'category' => 'core',
                'description' => 'Real-time multi-device cloud data synchronization and automated cloud snapshots.',
                'price' => 29.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'is_addon' => false,
                'is_active' => true,
            ]
        );

        Feature::firstOrCreate(
            ['code' => 'feat_sync'],
            [
                'id' => (string) Str::uuid(),
                'package_id' => $syncPkg->id,
                'name' => 'Cloud Data Sync',
                'capability_code' => 'sync',
                'description' => 'Enable cloud data queue synchronization',
            ]
        );

        Feature::firstOrCreate(
            ['code' => 'feat_cloud_backup'],
            [
                'id' => (string) Str::uuid(),
                'package_id' => $syncPkg->id,
                'name' => 'Cloud Backup',
                'capability_code' => 'cloudBackup',
                'description' => 'Automated cloud snapshot backup',
            ]
        );

        $multiDevicePkg = Package::firstOrCreate(
            ['code' => 'multi_device'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Multi-Device Package',
                'category' => 'add_on',
                'description' => 'Connect and synchronize multiple active terminal devices.',
                'price' => 15.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'is_addon' => true,
                'is_active' => true,
            ]
        );

        Feature::firstOrCreate(
            ['code' => 'feat_multi_device'],
            [
                'id' => (string) Str::uuid(),
                'package_id' => $multiDevicePkg->id,
                'name' => 'Multi-Device Terminal Sync',
                'capability_code' => 'multiDevice',
                'description' => 'Sync across multiple POS terminals and mobile devices',
            ]
        );

        $multiBranchPkg = Package::firstOrCreate(
            ['code' => 'multi_branch'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Multi-Branch Package',
                'category' => 'add_on',
                'description' => 'Manage multiple physical business branches and consolidated financial reports.',
                'price' => 49.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'is_addon' => true,
                'is_active' => true,
            ]
        );

        Feature::firstOrCreate(
            ['code' => 'feat_multi_branch'],
            [
                'id' => (string) Str::uuid(),
                'package_id' => $multiBranchPkg->id,
                'name' => 'Multi-Branch Management',
                'capability_code' => 'multiBranch',
                'description' => 'Branch operations, transfers, and consolidated reporting',
            ]
        );

        // Package Dependencies
        $multiDevicePkg->dependencies()->syncWithoutDetaching([$syncPkg->id]);
        $multiBranchPkg->dependencies()->syncWithoutDetaching([$syncPkg->id]);

        // Limits
        PackageLimit::firstOrCreate(
            ['package_id' => $syncPkg->id, 'limit_key' => 'max_devices'],
            [
                'id' => (string) Str::uuid(),
                'default_value' => 5,
                'period' => 'unlimited',
            ]
        );

        PackageLimit::firstOrCreate(
            ['package_id' => $syncPkg->id, 'limit_key' => 'max_users'],
            [
                'id' => (string) Str::uuid(),
                'default_value' => 3,
                'period' => 'unlimited',
            ]
        );

        // 2. Create Commercial Subscription Plans
        $plans = [
            [
                'code' => 'free',
                'name' => 'Free Local Plan',
                'description' => 'Full local accounting, sales, inventory, and point-of-sale operations (100% offline).',
                'price' => 0.00,
                'currency' => 'USD',
                'billing_interval' => 'forever',
                'sort_order' => 1,
                'is_active' => true,
                'is_free' => true,
                'default_trial_days' => 0,
                'packages' => [],
            ],
            [
                'code' => 'starter',
                'name' => 'Starter Plan',
                'description' => 'Essential cloud synchronization, automated backup, and multi-device support.',
                'price' => 29.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'sort_order' => 2,
                'is_active' => true,
                'is_free' => false,
                'default_trial_days' => 14,
                'packages' => [$syncPkg->id, $multiDevicePkg->id],
            ],
            [
                'code' => 'business',
                'name' => 'Business Plan',
                'description' => 'Full cloud suite with multi-branch management, team users, and advanced analytics.',
                'price' => 79.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'sort_order' => 3,
                'is_active' => true,
                'is_free' => false,
                'default_trial_days' => 14,
                'packages' => [$syncPkg->id, $multiDevicePkg->id, $multiBranchPkg->id],
            ],
            [
                'code' => 'enterprise',
                'name' => 'Enterprise Plan',
                'description' => 'Custom enterprise solution, dedicated cloud infrastructure, priority 24/7 support, and unlimited scale.',
                'price' => 199.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'sort_order' => 4,
                'is_active' => true,
                'is_free' => false,
                'default_trial_days' => 30,
                'packages' => [$syncPkg->id, $multiDevicePkg->id, $multiBranchPkg->id],
            ],
        ];

        foreach ($plans as $planData) {
            $packageIds = $planData['packages'];
            unset($planData['packages']);

            $plan = Plan::firstOrCreate(
                ['code' => $planData['code']],
                array_merge(['id' => (string) Str::uuid()], $planData)
            );

            // Update plan properties if already exists
            $plan->update($planData);

            if (! empty($packageIds)) {
                $plan->packages()->syncWithoutDetaching($packageIds);
            }
        }
    }
}
