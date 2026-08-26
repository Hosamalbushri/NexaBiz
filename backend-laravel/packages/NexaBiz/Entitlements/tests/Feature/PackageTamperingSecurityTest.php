<?php

namespace NexaBiz\Entitlements\Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Entitlements\Services\UsageLimitService;
use NexaBiz\Identity\Models\AuthSession;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\User;
use NexaBiz\Identity\Services\JwtTokenService;
use Tests\TestCase;

class PackageTamperingSecurityTest extends TestCase
{
    use RefreshDatabase;

    private User $user;
    private Company $companyFree;
    private Company $companyOther;
    private string $tokenFree;

    protected function setUp(): void
    {
        parent::setUp();

        (new EntitlementSeeder)->run();

        $this->companyFree = Company::create([
            'id' => (string) Str::uuid(),
            'name' => 'Tamper Test Free Co',
            'code' => 'TMP_FREE_CO',
            'status' => 'active',
        ]);

        $this->companyOther = Company::create([
            'id' => (string) Str::uuid(),
            'name' => 'Tamper Test Other Co',
            'code' => 'TMP_OTHER_CO',
            'status' => 'active',
        ]);

        $this->user = User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Tamper Test User',
            'email' => 'tamper@nexabiz.com',
            'password_hash' => bcrypt('Password!123'),
            'status' => 'active',
        ]);

        $sessionId = (string) Str::uuid();
        AuthSession::create([
            'id' => $sessionId,
            'user_id' => $this->user->id,
            'company_id' => $this->companyFree->id,
            'status' => 'active',
            'family_id' => (string) Str::uuid(),
            'refresh_token_hash' => hash('sha256', 'dummy_token'),
            'expires_at' => now()->addDays(7),
        ]);

        $jwtService = new JwtTokenService;
        $this->tokenFree = $jwtService->createAccessToken($this->user->id, $sessionId, $this->companyFree->id)[0];
    }

    public function test_free_client_cannot_bypass_entitlement_middleware(): void
    {
        // Calling a sync protected route without active subscription must be rejected with 403 Forbidden
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->tokenFree}",
            'X-Company-Id' => $this->companyFree->id,
        ])->getJson('/api/v1/entitlements');

        $response->assertStatus(200);
        $this->assertEquals('free', $response->json('tier'));
        $this->assertNotContains('sync', $response->json('capabilities'));
    }

    public function test_client_header_tenant_mismatch_rejected(): void
    {
        $response = $this->withHeaders([
            'Authorization' => "Bearer {$this->tokenFree}",
            'X-Company-Id' => $this->companyOther->id,
        ])->getJson('/api/v1/entitlements');

        $response->assertStatus(403);
    }
}
