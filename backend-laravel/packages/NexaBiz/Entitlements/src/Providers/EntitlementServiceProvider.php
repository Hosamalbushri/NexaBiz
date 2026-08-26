<?php

namespace NexaBiz\Entitlements\Providers;

use Illuminate\Support\Facades\Schema;
use Illuminate\Support\ServiceProvider;
use NexaBiz\Entitlements\Contracts\PaymentGateway;
use NexaBiz\Entitlements\Database\Seeders\EntitlementSeeder;
use NexaBiz\Entitlements\Http\Middleware\CheckEntitlementCapability;
use NexaBiz\Entitlements\Http\Middleware\CheckUsageQuota;
use NexaBiz\Entitlements\Services\EntitlementResolver;
use NexaBiz\Entitlements\Services\ManualActivationPaymentGateway;
use NexaBiz\Entitlements\Services\PackageResolver;
use NexaBiz\Entitlements\Services\SubscriptionService;
use NexaBiz\Entitlements\Services\UsageLimitService;

class EntitlementServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->mergeConfigFrom(__DIR__.'/../Config/entitlements.php', 'nexabiz_entitlements');

        $this->app->singleton(EntitlementResolver::class);
        $this->app->singleton(UsageLimitService::class);
        $this->app->singleton(PackageResolver::class);
        $this->app->singleton(PaymentGateway::class, ManualActivationPaymentGateway::class);
        $this->app->singleton(SubscriptionService::class);
    }

    public function boot(): void
    {
        $this->loadMigrationsFrom(__DIR__.'/../Database/Migrations');
        $this->loadRoutesFrom(__DIR__.'/../Routes/api.php');

        $this->app['router']->aliasMiddleware('entitlement', CheckEntitlementCapability::class);
        $this->app['router']->aliasMiddleware('quota', CheckUsageQuota::class);

        $this->app->booted(fn () => $this->seedOnBoot());
    }

    private function seedOnBoot(): void
    {
        if ($this->app->runningInConsole() || $this->app->environment('testing')) {
            return;
        }

        try {
            if (! Schema::hasTable('plans')) {
                return;
            }
            (new EntitlementSeeder)->run();
        } catch (\Throwable) {
            // Database unavailable during initial boot
        }
    }
}
