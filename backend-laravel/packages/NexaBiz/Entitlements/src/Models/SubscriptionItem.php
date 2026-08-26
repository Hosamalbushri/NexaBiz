<?php

namespace NexaBiz\Entitlements\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use NexaBiz\Core\Models\Concerns\HasUuidPrimaryKey;

class SubscriptionItem extends Model
{
    use HasUuidPrimaryKey;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'subscription_id',
        'package_id',
        'status',
        'is_addon',
        'quantity',
        'starts_at',
        'ends_at',
    ];

    protected $casts = [
        'is_addon' => 'boolean',
        'quantity' => 'integer',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
    ];

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class, 'subscription_id');
    }

    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class, 'package_id');
    }
}
