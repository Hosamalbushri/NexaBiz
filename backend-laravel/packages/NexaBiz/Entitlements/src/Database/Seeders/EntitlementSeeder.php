<?php

namespace NexaBiz\Entitlements\Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Models\Feature;
use NexaBiz\Entitlements\Models\Package;
use NexaBiz\Entitlements\Models\PackageLimit;
use NexaBiz\Entitlements\Models\Plan;

class EntitlementSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create Core Packages & Features
        $syncPkg = Package::firstOrCreate(
            ['code' => 'cloud_sync'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Cloud Data Synchronization',
                'category' => 'core',
                'description' => 'Real-time multi-device cloud synchronization and offline queue processing.',
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
                'name' => 'Cloud Sync',
                'capability_code' => 'sync',
                'description' => 'Enable cloud data sync pass',
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
                'name' => 'Multi-Device Access',
                'category' => 'add_on',
                'description' => 'Connect multiple active devices to your company catalog.',
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
                'name' => 'Multi-Device Sync',
                'capability_code' => 'multiDevice',
                'description' => 'Sync across multiple terminal devices',
            ]
        );

        $multiBranchPkg = Package::firstOrCreate(
            ['code' => 'multi_branch'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Multi-Branch Management',
                'category' => 'add_on',
                'description' => 'Manage multiple physical branches and consolidated reports.',
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
                'name' => 'Multi-Branch Capability',
                'capability_code' => 'multiBranch',
                'description' => 'Branch level operations and transfers',
            ]
        );

        // Define Package Dependencies: multi_device & multi_branch require cloud_sync
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

        // 2. Create Plans
        $freePlan = Plan::firstOrCreate(
            ['code' => 'free'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Free Plan',
                'description' => 'Full local accounting and POS operations. 100% offline enabled.',
                'price' => 0.00,
                'currency' => 'USD',
                'billing_interval' => 'forever',
                'sort_order' => 1,
                'is_active' => true,
                'is_free' => true,
                'default_trial_days' => 0,
            ]
        );

        $starterPlan = Plan::firstOrCreate(
            ['code' => 'starter'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Starter Plan',
                'description' => 'Cloud sync, multi-device access, and cloud backup.',
                'price' => 49.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'sort_order' => 2,
                'is_active' => true,
                'is_free' => false,
                'default_trial_days' => 14,
            ]
        );

        $businessPlan = Plan::firstOrCreate(
            ['code' => 'business'],
            [
                'id' => (string) Str::uuid(),
                'name' => 'Business Plan',
                'description' => 'Full cloud suite, multi-branch, team users, and advanced reports.',
                'price' => 99.00,
                'currency' => 'USD',
                'billing_interval' => 'monthly',
                'sort_order' => 3,
                'is_active' => true,
                'is_free' => false,
                'default_trial_days' => 14,
            ]
        );

        // Attach Packages to Plans
        $starterPlan->packages()->syncWithoutDetaching([$syncPkg->id, $multiDevicePkg->id]);
        $businessPlan->packages()->syncWithoutDetaching([$syncPkg->id, $multiDevicePkg->id, $multiBranchPkg->id]);
    }
}
