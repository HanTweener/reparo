<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderAssignmentEvent extends Model
{
    use HasFactory;

    public $timestamps = false;
    protected $table = 'order_assignment_events';

    protected $fillable = [
        'order_id',
        'previous_technician_id',
        'new_technician_id',
        'changed_by_user_id',
        'reason',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'created_at' => 'datetime',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(RepairOrder::class, 'order_id');
    }

    public function previousTechnician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'previous_technician_id');
    }

    public function newTechnician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'new_technician_id');
    }

    public function changedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'changed_by_user_id');
    }
}

