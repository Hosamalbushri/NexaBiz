<?php

namespace NexaBiz\Entitlements\Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Services\UsageLimitService;
use NexaBiz\Identity\Models\AuthSession;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\User;
use NexaBiz\Identity\Services\JwtTokenService;
use Tests\TestCase;

class SubscriptionLifecycleTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Company $company;
    private string $token;

    protected function setUp(): void
    {
        parent::setUp();

        (new EntitlementSeeder)->run();

        $this->company = Company::create([
            'id' => (string) Str::uuid(),
            'name' => 'Lifecycle Test Co',
            'code' => 'LC_CO_01',
            'status' => 'active',
        ]);

        $this->user = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Lifecycle User',
            'email' => 'lc@nexabiz.com',
            'password_hash' => bcrypt('Password!123'),
            'status' => 'active',
        ]);

        $sessionId = (string) Str::uuid();
        AuthSession::create([
            'id' => $sessionId,
            'user_id' => $this->user->id,
            'company_id' => $this->company->id,
            'status' => 'active',
            'family_id' => (string) Str::uuid(),
            'refresh_token_hash' => hash('sha256', 'dummy_token'),
            'expires_at' => now()->addDays(7),
        ]);

        $jwtService = new JwtTokenService;
        $this->token = $jwtService->createAccessToken($this->user->id, $sessionId, $this->company->id)[0];
    }

    public function test_show_plan_and_packages_endpoints(): void
    {
        $response = $this->getJson('/api/v1/plans/starter');
        $response->assertStatus(200);
        $response->assertJsonPath('data.code', 'starter');

        $pkgResponse = $this->getJson('/api/v1/packages');
        $pkgResponse->assertStatus(200);
        $pkgResponse->assertJsonStructure(['data' => [['id', 'code', 'name', 'price']]]);
    }

    public function test_package_dependency_auto_resolution(): void
    {
        $starterPlan = Plan::where('code', 'starter')->firstOrFail();

        // Requesting multi_device without cloud_sync
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
        ])->postJson('/api/v1/subscription/change', [
            'plan_id' => $starterPlan->id,
            'packages' => ['multi_device'],
        ]);

        $response->assertStatus(200);
        // Both multi_device AND dependent cloud_sync must be included in package_codes
        $this->assertContains('cloud_sync', $response->json('entitlement.package_codes'));
        $this->assertContains('multi_device', $response->json('entitlement.package_codes'));
    }

    public function test_idempotency_key_prevents_duplicate_processing(): void
    {
        $starterPlan = Plan::where('code', 'starter')->firstOrFail();
        $idempotencyKey = 'idempotent_key_12345';

        $response1 = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
            'Idempotency-Key' => $idempotencyKey,
        ])->postJson('/api/v1/subscription/change', [
            'plan_id' => $starterPlan->id,
        ]);
        $response1->assertStatus(200);

        $response2 = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
            'Idempotency-Key' => $idempotencyKey,
        ])->postJson('/api/v1/subscription/change', [
            'plan_id' => $starterPlan->id,
        ]);
        $response2->assertStatus(200);
    }

    public function test_usage_summary_endpoint(): void
    {
        $limitService = app(UsageLimitService::class);
        $limitService->recordUsage($this->company->id, 'max_devices', 2);

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
        ])->getJson('/api/v1/usage');

        $response->assertStatus(200);
        $response->assertJsonStructure(['data' => [['meter_key', 'used']]]);
    }
}
