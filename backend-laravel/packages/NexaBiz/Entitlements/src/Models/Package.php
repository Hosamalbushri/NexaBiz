<?php

namespace NexaBiz\Entitlements\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use NexaBiz\Core\Models\Concerns\HasUuidPrimaryKey;

class Package extends Model
{
    use HasUuidPrimaryKey;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'id',
        'name',
        'code',
        'category',
        'description',
        'price',
        'currency',
        'billing_interval',
        'is_addon',
        'is_active',
    ];

    protected $casts = [
        'price' => 'float',
        'is_addon' => 'boolean',
        'is_active' => 'boolean',
    ];

    public function features(): HasMany
    {
        return $this->hasMany(Feature::class, 'package_id');
    }

    public function limits(): HasMany
    {
        return $this->hasMany(PackageLimit::class, 'package_id');
    }

    public function plans(): BelongsToMany
    {
        return $this->belongsToMany(Plan::class, 'plan_packages', 'package_id', 'plan_id')
            ->withPivot('is_included')
            ->withTimestamps();
    }

    public function dependencies(): BelongsToMany
    {
        return $this->belongsToMany(Package::class, 'package_dependencies', 'package_id', 'depends_on_package_id');
    }
}
