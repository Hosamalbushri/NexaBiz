<?php

use Illuminate\Support\Facades\Route;
use NexaBiz\Entitlements\Http\Controllers\EntitlementController;
use NexaBiz\Entitlements\Http\Controllers\SubscriptionController;
use NexaBiz\Identity\Http\Middleware\AuthenticateApi;

Route::prefix('api/v1')->group(function (): void {
    Route::get('/plans', [EntitlementController::class, 'plans']);
    Route::get('/plans/{plan}', [EntitlementController::class, 'showPlan']);
    Route::get('/packages', [EntitlementController::class, 'packages']);
    Route::get('/packages/{package}', [EntitlementController::class, 'showPackage']);

    Route::middleware(AuthenticateApi::class)->group(function (): void {
        Route::get('/entitlements', [EntitlementController::class, 'show']);
        Route::get('/subscription', [SubscriptionController::class, 'show']);
        Route::post('/subscription/change', [SubscriptionController::class, 'change']);
        Route::post('/subscription/cancel', [SubscriptionController::class, 'cancel']);
        Route::get('/usage', [SubscriptionController::class, 'usage']);

        Route::get('/companies/{company}/subscription', [SubscriptionController::class, 'show']);
        Route::get('/companies/{company}/entitlements', [EntitlementController::class, 'show']);
        Route::post('/companies/{company}/subscription/checkout', [SubscriptionController::class, 'checkout']);
        Route::post('/companies/{company}/subscription/activate', [SubscriptionController::class, 'activate']);
    });
});
