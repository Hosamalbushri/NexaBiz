<?php

namespace NexaBiz\Synchronization\Http\Controllers;

use NexaBiz\Audit\Contracts\AuditWriter;
use NexaBiz\Identity\Support\AuthContext;
use NexaBiz\Identity\Services\Authorization;
use NexaBiz\Identity\Support\PermissionsCatalog;
use NexaBiz\Core\Exceptions\AppException;
use NexaBiz\Core\Exceptions\ConflictException;
use NexaBiz\Core\Exceptions\ValidationAppException;
use NexaBiz\Core\Http\Controllers\Controller;
use NexaBiz\Synchronization\Contracts\SyncEngine;
use NexaBiz\Synchronization\Http\Requests\PullChangesRequest;
use NexaBiz\Synchronization\Http\Requests\PushBatchRequest;
use NexaBiz\Synchronization\Http\Requests\PushOperationRequest;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SyncController extends Controller
{
    /**
     * Security design note (G9 resolution):
     *
     * NexaBiz is a self-hosted application. Subscription entitlement tiers
     * (free_local, starter, professional) are managed client-side by
     * EntitlementService with a 14-day offline grace period. The Laravel
     * backend does NOT enforce subscription tiers because:
     *
     *  1. The server has no subscription state — company.status ('active')
     *     is the only server-side gate, already enforced in AuthenticateApi.
     *  2. Entitlement enforcement happens at the Flutter sync client level
     *     (SyncManager.hasSyncCapability + hasSyncPermission callbacks).
     *  3. All server-side sync authorization is via RBAC permissions:
     *     SYNC_EXECUTE is required for all push/pull operations and is
     *     checked per-operation in requireSyncOperationPermission().
     *
     * If a future hosted/SaaS tier requires server-side entitlement
     * enforcement, add a SubscriptionService and inject it here.
     */
    public function __construct(
        private readonly SyncEngine $sync,
        private readonly Authorization $authorization,
        private readonly AuditWriter $audit,
    ) {}


    public function push(Request $request): JsonResponse
    {
        $auth = $this->context($request);
        $body = $request->json()->all();
        $op = $this->normalizeOperation($body['operation'] ?? []);
        if ($op['entity_type'] !== ($body['entity_type'] ?? $op['entity_type'])) {
            $op['entity_type'] = $body['entity_type'];
        }
        $companyId = $auth->requireCompanyId();

        // Server-side tenant validation
        if (isset($op['company_id']) && $op['company_id'] !== $companyId) {
            $this->audit->write(
                action: 'sync.tenant_mismatch',
                userId: $auth->userId(),
                companyId: $companyId,
                deviceId: $auth->deviceId,
                entityType: $op['entity_type'],
                entityId: (string) $op['entity_id'],
                metadata: [
                    'client_company_id' => $op['company_id'],
                    'auth_company_id' => $companyId,
                ],
            );
            throw new ValidationAppException('Tenant mismatch: operation company ID does not match session company ID.');
        }

        // Server-side device validation
        if (isset($op['device_id']) && $op['device_id'] !== $auth->deviceId) {
            $this->audit->write(
                action: 'sync.device_mismatch',
                userId: $auth->userId(),
                companyId: $companyId,
                deviceId: $auth->deviceId,
                entityType: $op['entity_type'],
                entityId: (string) $op['entity_id'],
                metadata: [
                    'client_device_id' => $op['device_id'],
                    'auth_device_id' => $auth->deviceId,
                ],
            );
            throw new ValidationAppException('Device mismatch: operation device ID does not match session device ID.');
        }

        try {
            $this->authorization->requireSyncOperationPermission(
                $auth->permissions,
                $op['entity_type'],
                $op['type'],
            );
        } catch (AppException $exc) {
            $this->audit->write(
                action: 'sync.authorization_failure',
                userId: $auth->userId(),
                companyId: $companyId,
                deviceId: $auth->deviceId,
                entityType: $op['entity_type'],
                entityId: (string) $op['entity_id'],
                metadata: [
                    'operation' => $op['type'],
                    'error' => $exc->errorCode,
                    'message' => $exc->getMessage(),
                ],
            );
            throw $exc;
        }

        $ack = DB::transaction(fn () => $this->sync->pushOperation(
            companyId: $companyId,
            userId: $auth->userId(),
            deviceId: $auth->deviceId ?: $auth->userId(),
            op: $op,
        ));

        $res = array_merge((array)$ack, ['server_time' => now()->toIso8601String()]);
        return response()->json($res);
    }

    public function pushBatch(Request $request): JsonResponse
    {
        $auth = $this->context($request);
        $body = $request->json()->all();
        $companyId = $auth->requireCompanyId();
        $results = [];

        $operations = [];
        foreach ($body['operations'] ?? [] as $raw) {
            $operations[] = $this->normalizeOperation($raw);
        }

        $groups = $this->groupOperations($operations);

        foreach ($groups as $indices) {
            $groupOps = [];
            foreach ($indices as $idx) {
                $groupOps[] = $operations[$idx];
            }

            DB::beginTransaction();
            try {
                $groupAcks = [];
                foreach ($groupOps as $op) {
                    $this->authorization->requireSyncOperationPermission(
                        $auth->permissions,
                        $op['entity_type'],
                        $op['type'],
                    );

                    // Server-side tenant validation
                    if (isset($op['company_id']) && $op['company_id'] !== $companyId) {
                        $this->audit->write(
                            action: 'sync.tenant_mismatch',
                            userId: $auth->userId(),
                            companyId: $companyId,
                            deviceId: $auth->deviceId,
                            entityType: $op['entity_type'],
                            entityId: (string) $op['entity_id'],
                            metadata: [
                                'client_company_id' => $op['company_id'],
                                'auth_company_id' => $companyId,
                            ],
                        );
                        throw new ValidationAppException('Tenant mismatch: operation company ID does not match session company ID.');
                    }

                    // Server-side device validation
                    if (isset($op['device_id']) && $op['device_id'] !== $auth->deviceId) {
                        $this->audit->write(
                            action: 'sync.device_mismatch',
                            userId: $auth->userId(),
                            companyId: $companyId,
                            deviceId: $auth->deviceId,
                            entityType: $op['entity_type'],
                            entityId: (string) $op['entity_id'],
                            metadata: [
                                'client_device_id' => $op['device_id'],
                                'auth_device_id' => $auth->deviceId,
                            ],
                        );
                        throw new ValidationAppException('Device mismatch: operation device ID does not match session device ID.');
                    }

                    $ack = $this->sync->pushOperation(
                        companyId: $companyId,
                        userId: $auth->userId(),
                        deviceId: $auth->deviceId ?: $auth->userId(),
                        op: $op,
                    );
                    $groupAcks[$op['operation_id']] = $ack;
                }
                DB::commit();

                foreach ($groupOps as $op) {
                    $results[] = [
                        'operation_id' => (string) $op['operation_id'],
                        'status' => 'success',
                        'ack' => $groupAcks[$op['operation_id']],
                    ];
                }
            } catch (ConflictException $exc) {
                DB::rollBack();
                foreach ($groupOps as $op) {
                    if ($op['operation_id'] === ($exc->details['operation_id'] ?? null)) {
                        $results[] = [
                            'operation_id' => (string) $op['operation_id'],
                            'status' => 'conflict',
                            'conflict' => $exc->details,
                            'error' => ['code' => $exc->errorCode, 'message' => $exc->getMessage()],
                        ];
                    } else {
                        $results[] = [
                            'operation_id' => (string) $op['operation_id'],
                            'status' => 'error',
                            'error' => [
                                'code' => 'dependency_failed',
                                'message' => 'Transaction group rolled back due to conflict in related operation: ' . $exc->getMessage(),
                            ],
                        ];
                    }
                }
            } catch (AppException $exc) {
                DB::rollBack();
                foreach ($groupOps as $op) {
                    $results[] = [
                        'operation_id' => (string) $op['operation_id'],
                        'status' => 'error',
                        'error' => [
                            'code' => $exc->errorCode,
                            'message' => $exc->getMessage(),
                            'details' => $exc->details,
                        ],
                    ];
                }
            } catch (\Throwable $exc) {
                DB::rollBack();
                foreach ($groupOps as $op) {
                    $results[] = [
                        'operation_id' => (string) $op['operation_id'],
                        'status' => 'error',
                        'error' => ['code' => 'server_error', 'message' => $exc->getMessage()],
                    ];
                }
            }
        }

        return response()->json([
            'results' => $results,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    private function groupOperations(array $ops): array
    {
        $n = count($ops);
        $parent = [];
        for ($i = 0; $i < $n; $i++) {
            $parent[$i] = $i;
        }

        $find = function ($i) use (&$parent, &$find) {
            if ($parent[$i] === $i) {
                return $i;
            }
            return $parent[$i] = $find($parent[$i]);
        };

        $union = function ($i, $j) use (&$parent, $find) {
            $rootI = $find($i);
            $rootJ = $find($j);
            if ($rootI !== $rootJ) {
                $parent[$rootI] = $rootJ;
            }
        };

        $entityToIndex = [];
        for ($i = 0; $i < $n; $i++) {
            $entityToIndex[$ops[$i]['entity_id']] = $i;
        }

        for ($i = 0; $i < $n; $i++) {
            $payloadStr = json_encode($ops[$i]['payload'] ?? []);
            foreach ($entityToIndex as $uuid => $idx) {
                if ($i !== $idx && str_contains($payloadStr, $uuid)) {
                    $union($i, $idx);
                }
            }
        }

        $groups = [];
        for ($i = 0; $i < $n; $i++) {
            $root = $find($i);
            $groups[$root][] = $i;
        }

        return array_values($groups);
    }

    private function normalizeOperation(array $op): array
    {
        if (! isset($op['type'])) {
            throw new ValidationAppException('operations must not be empty');
        }

        return [
            'operation_id' => $op['operation_id'] ?? '',
            'entity_type' => $op['entity_type'] ?? '',
            'entity_id' => $op['entity_id'] ?? '',
            'type' => $op['type'],
            'payload' => $op['payload'] ?? [],
            'base_version' => (int) ($op['base_version'] ?? 0),
            'company_id' => $op['company_id'] ?? null,
            'device_id' => $op['device_id'] ?? null,
        ];
    }

    public function pull(PullChangesRequest $request): JsonResponse
    {
        $auth = $this->context($request);
        $this->authorization->requirePermissions(
            $auth->permissions,
            [PermissionsCatalog::SYNC_EXECUTE, PermissionsCatalog::SYNC_VIEW],
            true,
        );
        $validated = $request->validated();
        $since = isset($validated['since'])
            ? CarbonImmutable::parse($validated['since'])->utc()
            : null;
        $limit = $validated['limit'] ?? (int) config('nexabiz.sync_pull_limit');
        [$changes, $nextCursor, $hasMore] = $this->sync->pull(
            companyId: $auth->requireCompanyId(),
            entityType: $validated['entity_type'] ?? null,
            cursor: isset($validated['cursor']) ? (int) $validated['cursor'] : null,
            since: $since,
            limit: (int) $limit,
        );

        return response()->json([
            'changes' => $changes,
            'next_cursor' => $nextCursor,
            'has_more' => $hasMore,
            'server_time' => now()->toIso8601String(),
        ]);
    }

    public function meta(Request $request, string $entityType, string $entityId): JsonResponse
    {
        $auth = $this->context($request);
        $this->authorization->requirePermissions(
            $auth->permissions,
            [PermissionsCatalog::SYNC_EXECUTE, PermissionsCatalog::SYNC_VIEW],
            true,
        );
        $entity = $this->sync->getMeta(
            companyId: $auth->requireCompanyId(),
            entityType: $entityType,
            entityId: $entityId,
        );
        if ($entity === null) {
            return response()->json(null);
        }

        return response()->json([
            'entity_id' => (string) $entity->entity_uuid,
            'version' => (int) $entity->version,
            'updated_at' => $entity->updated_at?->toIso8601String(),
            'payload' => $entity->payload,
        ]);
    }

    private function context(Request $request): AuthContext
    {
        return $request->attributes->get('auth_context');
    }
}
