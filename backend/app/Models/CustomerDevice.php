<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CustomerDevice extends Model
{
    use HasFactory;

    protected $fillable = [
        'customer_id',
        'category_id',
        'brand',
        'model',
        'serial_number',
        'description',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(DeviceCategory::class, 'category_id');
    }

    public function repairOrders(): HasMany
    {
        return $this->hasMany(RepairOrder::class, 'device_id');
    }
}

