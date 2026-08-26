<?php

namespace NexaBiz\Identity\Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use NexaBiz\Audit\Contracts\AuditWriter;
use NexaBiz\Entitlements\Database\Seeders\PlanSeeder;
use NexaBiz\Entitlements\Services\EntitlementResolver;
use NexaBiz\Entitlements\Services\PackageResolver;
use NexaBiz\Entitlements\Services\SubscriptionService;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\CompanyUser;
use NexaBiz\Identity\Models\User;
use NexaBiz\Identity\Services\CompanyProvisioningService;
use Tests\TestCase;

class CompanyProvisioningTest extends TestCase
{
    use RefreshDatabase;

    private CompanyProvisioningService $provisioningService;
    private SubscriptionService $subscriptionService;
    private User $adminUser;

    protected function setUp(): void
    {
        parent::setUp();

        // Run PlanSeeder to seed plans & packages
        (new PlanSeeder())->run();

        $auditWriter = $this->createMock(AuditWriter::class);
        $this->provisioningService = new CompanyProvisioningService($auditWriter);

        $resolver = $this->app->make(EntitlementResolver::class);
        $packageResolver = $this->app->make(PackageResolver::class);
        $paymentGateway = $this->app->make(\NexaBiz\Entitlements\Contracts\PaymentGateway::class);
        $this->subscriptionService = new SubscriptionService($resolver, $packageResolver, $paymentGateway);

        $this->adminUser = User::query()->create([
            'id' => (string) Str::uuid(),
            'name' => 'Admin User',
            'email' => 'admin@nexabiz.test',
            'password_hash' => bcrypt('password'),
            'status' => 'active',
        ]);
    }

    public function test_authorized_admin_can_provision_company(): void
    {
        $provisioning = $this->provisioningService->provisionCompany(
            userId: $this->adminUser->id,
            localCompanyId: 'local-comp-101',
            companyName: 'My Local Business',
            companyCode: 'COMP-101',
            idempotencyKey: 'idem-key-101'
        );

        $this->assertEquals('local-comp-101', $provisioning->local_company_id);
        $this->assertEquals('CLOUD_ADMIN_LINKED', $provisioning->status);
        $this->assertNotNull($provisioning->server_company_id);

        // Verify Server Company was created
        $serverCompany = Company::query()->find($provisioning->server_company_id);
        $this->assertNotNull($serverCompany);
        $this->assertEquals('My Local Business', $serverCompany->name);

        // Verify Admin User is linked to Server Company
        $membership = CompanyUser::query()
            ->where('company_id', $serverCompany->id)
            ->where('user_id', $this->adminUser->id)
            ->first();
        $this->assertNotNull($membership);
        $this->assertEquals('active', $membership->status);
    }

    public function test_provisioning_is_idempotent_and_does_not_create_duplicate_companies(): void
    {
        $key = 'idem-unique-123';

        $first = $this->provisioningService->provisionCompany(
            userId: $this->adminUser->id,
            localCompanyId: 'local-comp-102',
            companyName: 'Duplicate Test Business',
            idempotencyKey: $key
        );

        $second = $this->provisioningService->provisionCompany(
            userId: $this->adminUser->id,
            localCompanyId: 'local-comp-102',
            companyName: 'Duplicate Test Business',
            idempotencyKey: $key
        );

        $this->assertEquals($first->id, $second->id);
        $this->assertEquals($first->server_company_id, $second->server_company_id);
        $this->assertEquals(1, Company::query()->where('name', 'Duplicate Test Business')->count());
    }

    public function test_checkout_and_activate_subscription(): void
    {
        $provisioning = $this->provisioningService->provisionCompany(
            userId: $this->adminUser->id,
            localCompanyId: 'local-comp-103',
            companyName: 'Subscribed Company'
        );

        $checkout = $this->subscriptionService->checkoutSubscription(
            companyId: $provisioning->server_company_id,
            planId: 'starter',
            requestedPackageCodes: ['cloud_sync']
        );

        $this->assertEquals('pending_payment', $checkout['status']);
        $this->assertNotNull($checkout['subscription_id']);

        $activation = $this->subscriptionService->activateSubscription(
            companyId: $provisioning->server_company_id,
            subscriptionId: $checkout['subscription_id'],
            paymentReference: 'PAY-REF-999'
        );

        $this->assertEquals('active', $activation['subscription']->status);
        $this->assertNotNull($activation['entitlement']);
    }

    public function test_link_existing_company_with_valid_admin_credentials(): void
    {
        $existingCompany = Company::query()->create([
            'id' => (string) Str::uuid(),
            'name' => 'Existing Enterprise Server Comp',
            'code' => 'ENT-555',
            'status' => 'active',
        ]);

        $adminRole = \NexaBiz\Identity\Models\Role::query()->where('name', 'Admin')->first();
        CompanyUser::query()->create([
            'id' => (string) Str::uuid(),
            'company_id' => $existingCompany->id,
            'user_id' => $this->adminUser->id,
            'role_id' => $adminRole?->id,
            'status' => 'active',
        ]);

        $result = $this->provisioningService->linkExistingCompany(
            localCompanyId: 'local-comp-200',
            email: 'admin@nexabiz.test',
            password: 'password',
            companyCode: 'ENT-555'
        );

        $this->assertNotNull($result['provisioning']);
        $this->assertEquals('local-comp-200', $result['provisioning']->local_company_id);
        $this->assertEquals($existingCompany->id, $result['provisioning']->server_company_id);
        $this->assertEquals('LINKED', $result['provisioning']->status);
    }

    public function test_link_existing_company_http_endpoint(): void
    {
        $existingCompany = Company::query()->create([
            'id' => (string) Str::uuid(),
            'name' => 'HTTP Link Enterprise Comp',
            'code' => 'ENT-888',
            'status' => 'active',
        ]);

        $adminRole = \NexaBiz\Identity\Models\Role::query()->where('name', 'Admin')->first();
        CompanyUser::query()->create([
            'id' => (string) Str::uuid(),
            'company_id' => $existingCompany->id,
            'user_id' => $this->adminUser->id,
            'role_id' => $adminRole?->id,
            'status' => 'active',
        ]);

        $response = $this->postJson('/api/v1/companies/link-existing', [
            'local_company_id' => 'local-comp-888',
            'email' => 'admin@nexabiz.test',
            'password' => 'password',
            'company_code' => 'ENT-888',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('data.local_company_id', 'local-comp-888');
        $response->assertJsonPath('data.server_company_id', (string) $existingCompany->id);
        $response->assertJsonPath('data.status', 'LINKED');
        $this->assertNotNull($response->json('data.token'));
    }
}
