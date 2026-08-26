<?php

namespace NexaBiz\Entitlements\Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Entitlements\Models\CompanyEntitlement;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Services\EntitlementResolver;
use NexaBiz\Entitlements\Services\SubscriptionService;
use NexaBiz\Identity\Models\AuthSession;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\User;
use NexaBiz\Identity\Services\JwtTokenService;
use Tests\TestCase;

class EntitlementsTest extends TestCase
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
            'name' => 'Test Entitlement Co',
            'code' => 'ENT_CO_01',
            'status' => 'active',
        ]);

        $this->user = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Test User',
            'email' => 'test@nexabiz.com',
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

    public function test_plans_endpoint_returns_available_plans(): void
    {
        $response = $this->getJson('/api/v1/plans');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'data' => [
                '*' => ['id', 'name', 'code', 'is_free'],
            ],
        ]);
    }

    public function test_entitlements_endpoint_resolves_company_snapshot(): void
    {
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
        ])->getJson('/api/v1/entitlements');

        $response->assertStatus(200);
        $response->assertJsonFragment([
            'company_id' => $this->company->id,
            'tier' => 'free',
            'status' => 'active',
        ]);
    }

    public function test_subscription_change_upgrades_to_starter_plan(): void
    {
        $starterPlan = Plan::where('code', 'starter')->firstOrFail();

        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
        ])->postJson('/api/v1/subscription/change', [
            'plan_id' => $starterPlan->id,
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('entitlement.tier', 'premium');
        $response->assertJsonPath('entitlement.status', 'active');
        $this->assertContains('sync', $response->json('entitlement.capabilities'));
    }

    public function test_subscription_cancel_updates_status(): void
    {
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->token}",
            'X-Company-Id' => $this->company->id,
        ])->postJson('/api/v1/subscription/cancel');

        $response->assertStatus(200);
        $response->assertJsonPath('entitlement.status', 'cancelled');
    }
}
