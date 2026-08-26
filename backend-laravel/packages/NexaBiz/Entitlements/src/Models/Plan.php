<?php

namespace NexaBiz\Entitlements\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use NexaBiz\Core\Models\Concerns\HasUuidPrimaryKey;

class Plan extends Model
{
    use HasUuidPrimaryKey;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'name',
        'code',
        'description',
        'price',
        'currency',
        'billing_interval',
        'sort_order',
        'is_active',
        'is_free',
        'default_trial_days',
    ];

    protected $casts = [
        'price' => 'float',
        'sort_order' => 'integer',
        'is_active' => 'boolean',
        'is_free' => 'boolean',
        'default_trial_days' => 'integer',
    ];

    public function packages(): BelongsToMany
    {
        return $this->belongsToMany(Package::class, 'plan_packages', 'plan_id', 'package_id')
            ->withPivot('is_included')
            ->withTimestamps();
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class, 'plan_id');
    }
}
