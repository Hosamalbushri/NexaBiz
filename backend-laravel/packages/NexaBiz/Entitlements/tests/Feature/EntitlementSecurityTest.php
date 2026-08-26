<?php

namespace NexaBiz\Entitlements\Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use NexaBiz\Core\Exceptions\AppException;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Entitlements\Services\UsageLimitService;
use NexaBiz\Identity\Models\AuthSession;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\User;
use NexaBiz\Identity\Services\JwtTokenService;
use Tests\TestCase;

class EntitlementSecurityTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Company $companyA;
    private Company $companyB;
    private string $tokenA;

    protected function setUp(): void
    {
        parent::setUp();

        (new EntitlementSeeder)->run();

        $this->companyA = Company::create([
            'id' => (string) Str::uuid(),
            'name' => 'Security Co A',
            'code' => 'SEC_CO_A',
            'status' => 'active',
        ]);

        $this->companyB = Company::create([
            'id' => (string) Str::uuid(),
            'name' => 'Security Co B',
            'code' => 'SEC_CO_B',
            'status' => 'active',
        ]);

        $this->user = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Security User',
            'email' => 'sec@nexabiz.com',
            'password_hash' => bcrypt('Password!123'),
            'status' => 'active',
        ]);

        $sessionId = (string) Str::uuid();
        AuthSession::create([
            'id' => $sessionId,
            'user_id' => $this->user->id,
            'company_id' => $this->companyA->id,
            'status' => 'active',
            'family_id' => (string) Str::uuid(),
            'refresh_token_hash' => hash('sha256', 'dummy_token'),
            'expires_at' => now()->addDays(7),
        ]);

        $jwtService = new JwtTokenService;
        $this->tokenA = $jwtService->createAccessToken($this->user->id, $sessionId, $this->companyA->id)[0];
    }

    public function test_tenant_subscription_isolation(): void
    {
        // Token for Company A querying Company B entitlements must be rejected with 403 Forbidden
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->tokenA}",
            'X-Company-Id' => $this->companyB->id,
        ])->getJson('/api/v1/entitlements');

        $response->assertStatus(403);
    }

    public function test_usage_quota_overrun_throws_payment_required(): void
    {
        $limitService = app(UsageLimitService::class);
        $meter = $limitService->recordUsage($this->companyA->id, 'max_devices', 1);
        $meter->update(['max_limit' => 1]);

        try {
            $limitService->checkQuota($this->companyA->id, 'max_devices', 1);
            $this->fail('Expected AppException 402 was not thrown');
        } catch (AppException $e) {
            $this->assertEquals(402, $e->statusCode);
            $this->assertEquals('quota_exceeded', $e->errorCode);
        }
    }
}
