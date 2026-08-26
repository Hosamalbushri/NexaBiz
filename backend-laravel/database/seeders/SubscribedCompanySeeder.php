<?php

namespace Database\Seeders;

use App\Auth\PermissionsCatalog;
use App\Models\Company;
use App\Models\CompanyUser;
use App\Models\Device;
use App\Models\Permission;
use App\Models\Role;
use App\Models\RolePermission;
use App\Models\SyncChange;
use App\Models\SyncSequence;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Models\CompanyEntitlement;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Models\Subscription;

class SubscribedCompanySeeder extends Seeder
{
    /**
     * Run the database seeders for a fully active subscribed company capable of pushing sync updates.
     */
    public function run(): void
    {
        // 1. Ensure Base Plans & Entitlements exist
        $this->call(PlanSeeder::class);

        $now = CarbonImmutable::now('UTC');

        // 2. Create or Update Subscribed Company
        $companyId = 'c0000000-0000-4000-a000-000000000001';
        $company = Company::query()->updateOrCreate(
            ['id' => $companyId],
            [
                'name' => 'شركة الحلول الرقمية المشتركة (Subscribed Commercial Co)',
                'code' => 'COMMERCIAL_SYNC_CO',
                'status' => 'active',
                'updated_at' => $now,
            ]
        );

        // Initialize Sync Sequence for Company
        SyncSequence::query()->firstOrCreate(
            ['company_id' => $companyId],
            ['next_value' => 100]
        );

        // 3. Attach Active Commercial Business Subscription
        $businessPlan = Plan::query()->where('code', 'business')->first()
            ?? Plan::query()->where('code', 'starter')->first();

        $subscription = Subscription::query()->where('company_id', $companyId)->first();
        if (! $subscription) {
            $subscription = Subscription::query()->create([
                'id' => (string) Str::uuid(),
                'company_id' => $companyId,
                'plan_id' => $businessPlan?->id,
                'status' => 'active',
                'starts_at' => $now->subMonth(),
                'ends_at' => $now->addYear(),
                'trial_ends_at' => null,
                'grace_ends_at' => null,
                'cancelled_at' => null,
            ]);
        } else {
            $subscription->plan_id = $businessPlan?->id;
            $subscription->status = 'active';
            $subscription->starts_at = $now->subMonth();
            $subscription->ends_at = $now->addYear();
            $subscription->save();
        }

        // 4. Create Active Company Entitlement Record
        $entitlementSnapshot = [
            'edition' => 'commercial_active',
            'tier' => 'business',
            'status' => 'active',
            'capabilities' => [
                'sync',
                'multiDevice',
                'multiBranch',
                'cloudBackup',
                'advancedReports',
                'exportImport',
            ],
            'limits' => [
                'max_devices' => 25,
                'max_users' => 10,
                'max_branches' => 5,
            ],
            'issued_at' => $now->toIso8601String(),
            'expires_at' => $now->addYear()->toIso8601String(),
        ];

        $entitlement = CompanyEntitlement::query()->where('company_id', $companyId)->first();
        if (! $entitlement) {
            CompanyEntitlement::query()->create([
                'id' => (string) Str::uuid(),
                'company_id' => $companyId,
                'subscription_id' => $subscription->id,
                'snapshot_data' => $entitlementSnapshot,
                'checksum' => hash('sha256', json_encode($entitlementSnapshot)),
                'verified_at' => $now,
                'expires_at' => $now->addYear(),
            ]);
        } else {
            $entitlement->subscription_id = $subscription->id;
            $entitlement->snapshot_data = $entitlementSnapshot;
            $entitlement->checksum = hash('sha256', json_encode($entitlementSnapshot));
            $entitlement->verified_at = $now;
            $entitlement->expires_at = $now->addYear();
            $entitlement->save();
        }

        // 5. Create System & Company Roles
        $adminRole = Role::query()->firstOrCreate(
            ['company_id' => $companyId, 'name' => 'Company Admin'],
            [
                'id' => (string) Str::uuid(),
                'description' => 'Full Administrative Access for Subscribed Company',
                'system_role' => true,
            ]
        );

        // Assign All Permissions to Admin Role
        foreach (PermissionsCatalog::allPermissions() as [$code, $description]) {
            $perm = Permission::query()->firstOrCreate(
                ['code' => $code],
                ['id' => (string) Str::uuid(), 'description' => $description, 'created_at' => $now]
            );
            RolePermission::query()->firstOrCreate([
                'role_id' => $adminRole->id,
                'permission_id' => $perm->id,
            ]);
        }

        // 6. Create Primary Subscribed Super Admin User
        $adminUser = User::query()->where('email', 'subscribed_admin@nexabiz.com')->first();
        if (! $adminUser) {
            $adminUser = User::query()->create([
                'id' => (string) Str::uuid(),
                'name' => 'مدير الشركة المشتركة',
                'email' => 'subscribed_admin@nexabiz.com',
                'password_hash' => Hash::make('SubscribedAdmin!123'),
                'status' => 'active',
                'is_super_admin' => true,
            ]);
        } else {
            $adminUser->name = 'مدير الشركة المشتركة';
            $adminUser->password_hash = Hash::make('SubscribedAdmin!123');
            $adminUser->status = 'active';
            $adminUser->is_super_admin = true;
            $adminUser->save();
        }

        CompanyUser::query()->updateOrCreate(
            ['company_id' => $companyId, 'user_id' => $adminUser->id],
            [
                'id' => (string) Str::uuid(),
                'role_id' => $adminRole->id,
                'status' => 'active',
            ]
        );

        // Create Sales Accountant User
        $salesUser = User::query()->where('email', 'subscribed_sales@nexabiz.com')->first();
        if (! $salesUser) {
            $salesUser = User::query()->create([
                'id' => (string) Str::uuid(),
                'name' => 'محاسب المبيعات التجاري',
                'email' => 'subscribed_sales@nexabiz.com',
                'password_hash' => Hash::make('SubscribedSales!123'),
                'status' => 'active',
                'is_super_admin' => false,
            ]);
        } else {
            $salesUser->name = 'محاسب المبيعات التجاري';
            $salesUser->password_hash = Hash::make('SubscribedSales!123');
            $salesUser->status = 'active';
            $salesUser->save();
        }

        CompanyUser::query()->updateOrCreate(
            ['company_id' => $companyId, 'user_id' => $salesUser->id],
            [
                'id' => (string) Str::uuid(),
                'role_id' => $adminRole->id,
                'status' => 'active',
            ]
        );

        // 7. Register Approved Devices for Sync Push
        Device::query()->updateOrCreate(
            ['company_id' => $companyId, 'device_identifier' => 'dev_pos_subscribed_01'],
            [
                'id' => 'd0000000-0000-4000-a000-000000000001',
                'user_id' => $adminUser->id,
                'device_name' => 'جهاز الكاشير التجاري (Terminal 01)',
                'platform' => 'android',
                'app_version' => '1.0.0',
                'status' => 'approved',
                'last_seen_at' => $now,
            ]
        );

        // 8. Seed Initial Commercial Sync Changes (Sample Pushed Catalog Data)
        $samplePayloads = [
            [
                'entity_type' => 'category',
                'entity_id' => 'cat-electronics-01',
                'operation' => 'create',
                'payload' => [
                    'id' => 'cat-electronics-01',
                    'name_ar' => 'الأجهزة الإلكترونية',
                    'name_en' => 'Electronics',
                    'code' => 'CAT-ELEC',
                ],
            ],
            [
                'entity_type' => 'product',
                'entity_id' => 'prod-pos-terminal-01',
                'operation' => 'create',
                'payload' => [
                    'id' => 'prod-pos-terminal-01',
                    'category_id' => 'cat-electronics-01',
                    'name_ar' => 'جهاز كاشير الذكي NexaTouch',
                    'name_en' => 'NexaTouch Smart POS',
                    'sku' => 'NEXA-POS-100',
                    'price' => 1250.00,
                    'cost' => 850.00,
                    'stock_quantity' => 50,
                ],
            ],
            [
                'entity_type' => 'customer',
                'entity_id' => 'cust-vip-01',
                'operation' => 'create',
                'payload' => [
                    'id' => 'cust-vip-01',
                    'name' => 'مؤسسة الأفق للتجارة (VIP)',
                    'phone' => '+966500000001',
                    'tax_number' => '300000000000003',
                ],
            ],
        ];

        $sequence = 1;
        foreach ($samplePayloads as $item) {
            SyncChange::query()->updateOrCreate(
                [
                    'company_id' => $companyId,
                    'entity_type' => $item['entity_type'],
                    'entity_uuid' => $item['entity_id'],
                ],
                [
                    'sequence' => $sequence++,
                    'operation' => $item['operation'],
                    'version' => 1,
                    'payload' => $item['payload'],
                    'deleted' => false,
                    'created_at' => $now,
                ]
            );
        }

        $this->command?->info(' Subscribed Commercial Company Seeding Completed Successfully!');
        $this->command?->info(' Company ID: ' . $companyId);
        $this->command?->info(' Admin Email: subscribed_admin@nexabiz.com');
        $this->command?->info(' Admin Password: SubscribedAdmin!123');
        $this->command?->info(' Device Identifier: dev_pos_subscribed_01');
    }
}
