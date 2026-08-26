<?php

namespace NexaBiz\Entitlements\Data;

class PaymentVerificationResult
{
    public function __construct(
        public readonly bool $isSuccessful,
        public readonly string $sessionId,
        public readonly string $companyId,
        public readonly string $planId,
        public readonly array $packages,
        public readonly ?string $transactionRef = null,
        public readonly ?string $errorMessage = null,
    ) {}
}
