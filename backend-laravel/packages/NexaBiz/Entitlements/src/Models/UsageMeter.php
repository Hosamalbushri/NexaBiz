<?php

namespace NexaBiz\Entitlements\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use NexaBiz\Core\Models\Concerns\HasUuidPrimaryKey;
use NexaBiz\Identity\Models\Company;

class UsageMeter extends Model
{
    use HasUuidPrimaryKey;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'company_id',
        'meter_key',
        'current_value',
        'max_limit',
        'reset_period',
        'last_reset_at',
    ];

    protected $casts = [
        'current_value' => 'integer',
        'max_limit' => 'integer',
        'last_reset_at' => 'datetime',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'company_id');
    }
}
