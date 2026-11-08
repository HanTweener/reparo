<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class RepairOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'public_reference',
        'customer_id',
        'device_name',
        'category_id',
        'service_code',
        'issue_description',
        'preferred_arrival_date',
        'confirmed_arrival_date',
        'status',
        'current_technician_id',
        'created_by_user_id',
        'lock_version',
    ];

    protected function casts(): array
    {
        return [
            'preferred_arrival_date' => 'date',
            'confirmed_arrival_date' => 'date',
            'lock_version' => 'integer',
        ];
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(DeviceCategory::class, 'category_id');
    }

    public function getDeviceAttribute(): array
    {
        return [
            'id' => '',
            'brand' => '',
            'model' => $this->device_name,
            'category_name' => $this->category?->name ?? 'Perangkat',
        ];
    }

    public function technician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'current_technician_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_user_id');
    }

    public function statusHistory(): HasMany
    {
        return $this->hasMany(OrderStatusHistory::class, 'order_id')->orderBy('created_at', 'asc');
    }

    public function assignmentEvents(): HasMany
    {
        return $this->hasMany(OrderAssignmentEvent::class, 'order_id')->orderBy('created_at', 'asc');
    }

    public function cancellationRequests(): HasMany
    {
        return $this->hasMany(CancellationRequest::class, 'order_id')->orderBy('created_at', 'desc');
    }

    public function diagnosis(): HasOne
    {
        return $this->hasOne(Diagnosis::class, 'order_id');
    }

    public function workNotes(): HasMany
    {
        return $this->hasMany(WorkNote::class, 'order_id')->orderBy('created_at', 'asc');
    }

    public function estimateRevisions(): HasMany
    {
        return $this->hasMany(EstimateRevision::class, 'order_id')->orderBy('revision_number', 'asc');
    }

    public function qcChecks(): HasMany
    {
        return $this->hasMany(QcCheck::class, 'order_id')->orderBy('created_at', 'asc');
    }

    public function invoice(): HasOne
    {
        return $this->hasOne(Invoice::class, 'order_id');
    }

    /**
     * Generate guaranteed unique public reference (e.g. REP-2026-0035).
     */
    public static function generateUniqueReference(): string
    {
        $year = date('Y');
        $maxId = (int) (static::max('id') ?? 0);
        $counter = 1;

        do {
            $num = $maxId + $counter;
            $ref = sprintf('REP-%s-%04d', $year, $num);
            if (! static::where('public_reference', $ref)->exists()) {
                return $ref;
            }
            $counter++;
            if ($counter > 50) {
                $ref = sprintf('REP-%s-%s', date('Ymd'), strtoupper(\Illuminate\Support\Str::random(4)));
                if (! static::where('public_reference', $ref)->exists()) {
                    return $ref;
                }
            }
        } while (true);
    }
}
