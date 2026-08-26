<?php

namespace NexaBiz\Identity\Services;

use NexaBiz\Audit\Contracts\AuditWriter;
use NexaBiz\Core\Exceptions\ForbiddenException;
use NexaBiz\Core\Exceptions\NotFoundException;
use NexaBiz\Core\Exceptions\UnauthorizedException;
use NexaBiz\Core\Exceptions\ValidationAppException;
use NexaBiz\Identity\Events\CompanyProvisioned;
use NexaBiz\Identity\Models\Company;
use NexaBiz\Identity\Models\CompanyProvisioning;
use NexaBiz\Identity\Models\CompanyUser;
use NexaBiz\Identity\Models\Role;
use NexaBiz\Identity\Models\User;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class CompanyProvisioningService
{
    public function __construct(
        private readonly AuditWriter $audit,
    ) {}

    /**
     * Idempotently provision a new cloud company and link the authenticated user as administrator.
     */
    public function provisionCompany(
        string $userId,
        string $localCompanyId,
        string $companyName,
        ?string $companyCode = null,
        ?string $idempotencyKey = null
    ): CompanyProvisioning {
        if (trim($localCompanyId) === '') {
            throw new ValidationAppException('local_company_id is required for provisioning.');
        }

        if (trim($companyName) === '') {
            throw new ValidationAppException('company_name is required for provisioning.');
        }

        // Check idempotency key first if provided
        if ($idempotencyKey !== null && trim($idempotencyKey) !== '') {
            $existing = CompanyProvisioning::query()
                ->where('idempotency_key', trim($idempotencyKey))
                ->first();
            if ($existing !== null) {
                return $existing;
            }
        }

        // Check if an existing provisioning record already exists for this (user_id, local_company_id)
        $existingRecord = CompanyProvisioning::query()
            ->where('user_id', $userId)
            ->where('local_company_id', $localCompanyId)
            ->whereIn('status', ['CLOUD_COMPANY_CREATED', 'CLOUD_ADMIN_LINKED', 'SUBSCRIPTION_PENDING', 'SUBSCRIPTION_ACTIVE', 'LINKED', 'CLOUD_READY'])
            ->first();

        if ($existingRecord !== null) {
            return $existingRecord;
        }

        $code = strtoupper(trim($companyCode ?? 'COMP-' . Str::upper(Str::random(6))));

        // Prevent duplicate company code
        if (Company::query()->where('code', $code)->exists()) {
            $code = strtoupper('COMP-' . Str::upper(Str::random(8)));
        }

        return DB::transaction(function () use ($userId, $localCompanyId, $companyName, $code, $idempotencyKey) {
            // 1. Create Server Company
            $serverCompany = Company::query()->create([
                'id' => (string) Str::uuid(),
                'name' => trim($companyName),
                'code' => $code,
                'status' => 'active',
            ]);

            // 2. Link User as Admin CompanyUser
            $adminRole = Role::query()->where('name', 'Admin')->first();
            CompanyUser::query()->create([
                'id' => (string) Str::uuid(),
                'company_id' => $serverCompany->id,
                'user_id' => $userId,
                'role_id' => $adminRole?->id,
                'status' => 'active',
            ]);

            // 3. Create Durable Provisioning Record
            $provisioning = CompanyProvisioning::query()->create([
                'id' => (string) Str::uuid(),
                'local_company_id' => $localCompanyId,
                'server_company_id' => $serverCompany->id,
                'user_id' => $userId,
                'status' => 'CLOUD_ADMIN_LINKED',
                'idempotency_key' => $idempotencyKey,
            ]);

            Event::dispatch(new CompanyProvisioned((string) $serverCompany->id));

            $this->audit->write(
                action: 'company.provisioned',
                userId: $userId,
                companyId: $serverCompany->id,
                entityType: 'company',
                entityId: (string) $serverCompany->id,
                metadata: [
                    'local_company_id' => $localCompanyId,
                    'provisioning_id' => $provisioning->id,
                ]
            );

            return $provisioning;
        });
    }

    /**
     * Get provisioning status for a given local company ID or provisioning ID.
     */
    public function getProvisioningStatus(string $userId, string $identifier): ?CompanyProvisioning
    {
        return CompanyProvisioning::query()
            ->where(function ($query) use ($identifier) {
                $query->where('id', $identifier)
                    ->orWhere('local_company_id', $identifier)
                    ->orWhere('server_company_id', $identifier);
            })
            ->where('user_id', $userId)
            ->first();
    }

    /**
     * Link an existing server company using admin credentials.
     */
    public function linkExistingCompany(
        string $localCompanyId,
        string $email,
        string $password,
        ?string $companyCode = null,
        ?string $idempotencyKey = null
    ): array {
        if (trim($localCompanyId) === '') {
            throw new ValidationAppException('local_company_id is required.');
        }

        if (trim($email) === '' || trim($password) === '') {
            throw new ValidationAppException('Admin email and password are required.');
        }

        $user = User::query()->where('email', strtolower(trim($email)))->first();
        if ($user === null || ! Hash::check($password, $user->password_hash)) {
            throw new UnauthorizedException('Invalid admin email or password.');
        }

        if ($user->status !== 'active') {
            throw new UnauthorizedException('User account is inactive or suspended.');
        }

        // Find server company
        $query = Company::query()->where('status', 'active');
        if ($companyCode !== null && trim($companyCode) !== '') {
            $query->where('code', strtoupper(trim($companyCode)));
        } else {
            $memberships = CompanyUser::query()
                ->where('user_id', $user->id)
                ->where('status', 'active')
                ->pluck('company_id');
            if ($memberships->isEmpty() && ! $user->is_super_admin) {
                throw new ValidationAppException('User does not belong to any active server company.');
            }
            if ($memberships->isNotEmpty()) {
                $query->whereIn('id', $memberships);
            }
        }

        $serverCompany = $query->first();
        if ($serverCompany === null) {
            throw new NotFoundException('Target server company not found or not active.');
        }

        // Verify user has admin rights for this server company
        if (! $user->is_super_admin) {
            $membership = CompanyUser::query()
                ->where('company_id', $serverCompany->id)
                ->where('user_id', $user->id)
                ->where('status', 'active')
                ->first();

            if ($membership === null) {
                throw new ForbiddenException('User is not a member of the target company.');
            }

            $adminRole = Role::query()->where('name', 'Admin')->first();
            if ($adminRole !== null && $membership->role_id !== $adminRole->id) {
                throw new ForbiddenException('User does not have Admin privileges in this company.');
            }
        }

        // Link company in DB transaction
        $provisioning = DB::transaction(function () use ($user, $localCompanyId, $serverCompany, $idempotencyKey) {
            $provisioning = CompanyProvisioning::query()->updateOrCreate(
                [
                    'local_company_id' => $localCompanyId,
                    'user_id' => $user->id,
                ],
                [
                    'server_company_id' => $serverCompany->id,
                    'status' => 'LINKED',
                    'idempotency_key' => $idempotencyKey,
                ]
            );

            $this->audit->write(
                action: 'company.linked_existing',
                userId: $user->id,
                companyId: $serverCompany->id,
                entityType: 'company',
                entityId: (string) $serverCompany->id,
                metadata: [
                    'local_company_id' => $localCompanyId,
                    'provisioning_id' => $provisioning->id,
                ]
            );

            return $provisioning;
        });

        $token = 'BearerToken_' . Str::random(40);

        return [
            'provisioning' => $provisioning,
            'server_company' => $serverCompany,
            'user' => $user,
            'token' => $token,
        ];
    }
}
