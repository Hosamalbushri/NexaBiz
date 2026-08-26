<?php

namespace NexaBiz\Entitlements\Data;

class CheckoutSession
{
    public function __construct(
        public readonly string $sessionId,
        public readonly string $companyId,
        public readonly string $planId,
        public readonly array $packages,
        public readonly float $amount,
        public readonly string $currency,
        public readonly string $status,
        public readonly ?string $checkoutUrl = null,
    ) {}

    public function toArray(): array
    {
        return [
            'session_id' => $this->sessionId,
            'company_id' => $this->companyId,
            'plan_id' => $this->planId,
            'packages' => $this->packages,
            'amount' => $this->amount,
            'currency' => $this->currency,
            'status' => $this->status,
            'checkout_url' => $this->checkoutUrl,
        ];
    }
}
