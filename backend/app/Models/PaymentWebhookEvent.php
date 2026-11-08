<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentWebhookEvent extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'payment_attempt_id',
        'deduplication_key',
        'provider_status',
        'signature_valid',
        'processing_outcome',
        'received_at',
    ];

    protected function casts(): array
    {
        return [
            'signature_valid' => 'boolean',
            'received_at' => 'datetime',
        ];
    }

    public function paymentAttempt(): BelongsTo
    {
        return $this->belongsTo(PaymentAttempt::class, 'payment_attempt_id');
    }
}

