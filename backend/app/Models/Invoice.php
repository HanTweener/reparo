<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Invoice extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'invoice_number',
        'current_amount',
        'currency_code',
        'status',
        'issued_at',
        'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'current_amount' => 'decimal:2',
            'issued_at' => 'datetime',
            'paid_at' => 'datetime',
        ];
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(RepairOrder::class, 'order_id');
    }

    public function corrections(): HasMany
    {
        return $this->hasMany(InvoiceCorrection::class, 'invoice_id')->orderBy('created_at', 'desc');
    }

    public function paymentAttempts(): HasMany
    {
        return $this->hasMany(PaymentAttempt::class, 'invoice_id')->orderBy('created_at', 'desc');
    }
}

