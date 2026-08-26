<?php

namespace NexaBiz\Entitlements\Contracts;

use NexaBiz\Entitlements\Data\CheckoutSession;
use NexaBiz\Entitlements\Data\PaymentVerificationResult;
use NexaBiz\Entitlements\Models\Plan;
use NexaBiz\Entitlements\Models\Subscription;
use NexaBiz\Identity\Models\Company;

interface PaymentGateway
{
    public function createCheckout(
        Company $company,
        Plan $plan,
        array $packages,
        string $idempotencyKey
    ): CheckoutSession;

    public function verifyPayment(string $sessionId, array $payload): PaymentVerificationResult;

    public function cancelSubscription(Subscription $subscription): bool;
}
