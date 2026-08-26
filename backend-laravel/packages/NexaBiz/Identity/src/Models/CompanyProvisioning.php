<?php

namespace NexaBiz\Identity\Models;

use NexaBiz\Core\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CompanyProvisioning extends Model
{
    use HasUuidPrimaryKey;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'local_company_id',
        'server_company_id',
        'user_id',
        'status',
        'idempotency_key',
        'error_message',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(Company::class, 'server_company_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
