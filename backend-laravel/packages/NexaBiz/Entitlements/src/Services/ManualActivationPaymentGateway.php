<?php

namespace NexaBiz\Entitlements\Services;

use Illuminate\Support\Str;
use NexaBiz\Entitlements\Contracts\PaymentGateway;
use NexaBiz\Entitlements\Data\CheckoutSession;
use NexaBiz\Entitlements\Data\PaymentVerificationResult;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Models\Subscription;
use NexaBiz\Identity\Models\Company;

class ManualActivationPaymentGateway implements PaymentGateway
{
    public function createCheckout(
        Company $company,
        Plan $plan,
        array $packages,
        string $idempotencyKey
    ): CheckoutSession {
        $sessionId = 'manual_chk_'.Str::random(16);
        $totalAmount = (float) ($plan->price ?? 0.0);

        return new CheckoutSession(
            sessionId: $sessionId,
            companyId: $company->id,
            planId: $plan->id,
            packages: $packages,
            amount: $totalAmount,
            currency: $plan->currency ?? 'USD',
            status: 'completed',
            checkoutUrl: null,
        );
    }

    public function verifyPayment(string $sessionId, array $payload): PaymentVerificationResult
    {
        return new PaymentVerificationResult(
            isSuccessful: true,
            sessionId: $sessionId,
            companyId: $payload['company_id'] ?? '',
            planId: $payload['plan_id'] ?? '',
            packages: $payload['packages'] ?? [],
            transactionRef: 'manual_tx_'.Str::random(12),
        );
    }

    public function cancelSubscription(Subscription $subscription): bool
    {
        return true;
    }
}
