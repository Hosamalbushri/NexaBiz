<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Models\Subscription;
use NexaBiz\Identity\Database\Seeders\IdentitySeeder;
use NexaBiz\Identity\Models\AuthSession;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\Device;
use NexaBiz\Identity\Models\User;
use NexaBiz\Identity\Services\JwtTokenService;
use Tests\TestCase;

class EntitlementBackendSecurityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(IdentitySeeder::class);
        $this->seed(EntitlementSeeder::class);
    }

    private function createHeaders(bool $isEntitled = false): array
    {
        $company = Company::create([
            'id' => (string) Str::uuid(),
            'name' => $isEntitled ? 'Entitled Co' : 'Free Co',
            'code' => $isEntitled ? 'ENT01' : 'FREE01',
            'status' => 'active',
        ]);

        if ($isEntitled) {
            $starterPlan = Plan::where('code', 'starter')->first();
            Subscription::create([
                'id' => (string) Str::uuid(),
                'company_id' => $company->id,
                'plan_id' => $starterPlan->id,
                'status' => 'active',
                'starts_at' => now(),
                'ends_at' => now()->addYear(),
            ]);
        }

        $user = User::query()->first() ?? User::create([
            'id' => (string) Str::uuid(),
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password_hash' => 'hash',
            'status' => 'active',
            'is_super_admin' => true,
        ]);

        $device = Device::create([
            'id' => (string) Str::uuid(),
            'company_id' => $company->id,
            'user_id' => $user->id,
            'device_name' => 'Test Device',
            'device_identifier' => 'test-device-' . Str::random(8),
            'status' => 'active',
        ]);

        $session = AuthSession::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'company_id' => $company->id,
            'device_id' => $device->id,
            'family_id' => (string) Str::uuid(),
            'refresh_token_hash' => hash('sha256', Str::random(32)),
            'status' => 'active',
            'expires_at' => now()->addDays(1),
        ]);

        $jwt = app(JwtTokenService::class);
        [$token] = $jwt->createAccessToken($user->id, $session->id, $company->id, $device->id);

        return [
            'Authorization' => 'Bearer ' . $token,
            'X-Company-Id' => $company->id,
            'X-Device-Id' => $device->id,
        ];
    }

    public function test_unentitled_company_sync_push_returns_403_forbidden(): void
    {
        $headers = $this->createHeaders(isEntitled: false);

        $response = $this->json('POST', '/api/v1/sync/push', [
            'entity_type' => 'customer',
            'operation' => [
                'operation_id' => (string) Str::uuid(),
                'entity_type' => 'customer',
                'entity_id' => (string) Str::uuid(),
                'type' => 'create',
                'base_version' => 0,
                'payload' => ['name' => 'Unentitled Customer'],
            ],
        ], $headers);

        $response->assertStatus(403);
    }

    public function test_entitled_company_sync_push_allowed(): void
    {
        $headers = $this->createHeaders(isEntitled: true);

        $response = $this->json('POST', '/api/v1/sync/push', [
            'entity_type' => 'customer',
            'operation' => [
                'operation_id' => (string) Str::uuid(),
                'entity_type' => 'customer',
                'entity_id' => (string) Str::uuid(),
                'type' => 'create',
                'base_version' => 0,
                'payload' => ['name' => 'Entitled Customer'],
            ],
        ], $headers);

        $response->assertStatus(200);
    }

    public function test_unentitled_company_sync_pull_returns_403_forbidden(): void
    {
        $headers = $this->createHeaders(isEntitled: false);

        $response = $this->json('GET', '/api/v1/sync/pull', [], $headers);

        $response->assertStatus(403);
    }

    public function test_entitled_company_sync_pull_allowed(): void
    {
        $headers = $this->createHeaders(isEntitled: true);

        $response = $this->json('GET', '/api/v1/sync/pull', [], $headers);

        $response->assertStatus(200);
    }
}
