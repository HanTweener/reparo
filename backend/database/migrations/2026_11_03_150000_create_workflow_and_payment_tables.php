<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Diagnoses
        Schema::create('diagnoses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->unique()->constrained('repair_orders')->cascadeOnDelete();
            $table->foreignId('technician_id')->constrained('users');
            $table->text('customer_safe_summary');
            $table->timestamps();
        });

        // 2. Internal Work Notes (Staff only)
        Schema::create('work_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('repair_orders')->cascadeOnDelete();
            $table->foreignId('author_user_id')->constrained('users');
            $table->text('note_text');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['order_id', 'created_at']);
        });

        // 3. Estimate Revisions
        Schema::create('estimate_revisions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('repair_orders')->cascadeOnDelete();
            $table->unsignedInteger('revision_number');
            $table->decimal('amount', 12, 2);
            $table->string('currency_code', 3)->default('IDR');
            $table->string('reason')->nullable();
            $table->foreignId('created_by_user_id')->constrained('users');
            $table->timestamp('created_at')->useCurrent();

            $table->unique(['order_id', 'revision_number']);
            $table->index(['order_id', 'created_at']);
        });

        // 4. QC Checks
        Schema::create('qc_checks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('repair_orders')->cascadeOnDelete();
            $table->foreignId('technician_id')->constrained('users');
            $table->string('result', 10); // PASS or FAIL
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['order_id', 'created_at']);
        });

        // 5. Invoices
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->unique()->constrained('repair_orders')->cascadeOnDelete();
            $table->string('invoice_number', 64)->unique();
            $table->decimal('current_amount', 12, 2);
            $table->string('currency_code', 3)->default('IDR');
            $table->string('status', 32)->default('OPEN'); // OPEN or PAID
            $table->timestamp('issued_at')->useCurrent();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });

        // 6. Invoice Corrections (Admin audits)
        Schema::create('invoice_corrections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('invoice_id')->constrained('invoices')->cascadeOnDelete();
            $table->decimal('previous_amount', 12, 2);
            $table->decimal('new_amount', 12, 2);
            $table->string('reason');
            $table->foreignId('changed_by_user_id')->constrained('users');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['invoice_id', 'created_at']);
        });

        // 7. Payment Attempts
        Schema::create('payment_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('invoice_id')->constrained('invoices')->cascadeOnDelete();
            $table->string('provider', 32)->default('MIDTRANS');
            $table->string('provider_reference', 128)->nullable();
            $table->decimal('amount', 12, 2);
            $table->string('currency_code', 3)->default('IDR');
            $table->string('status', 32)->default('PENDING'); // PENDING, PAID, FAILED, EXPIRED
            $table->string('snap_token')->nullable();
            $table->string('redirect_url')->nullable();
            $table->timestamps();

            $table->index(['invoice_id', 'status']);
        });

        // 8. Payment Webhook Events (Deduplication)
        Schema::create('payment_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_attempt_id')->nullable()->constrained('payment_attempts')->nullOnDelete();
            $table->string('deduplication_key', 128)->unique();
            $table->string('provider_status', 64);
            $table->boolean('signature_valid');
            $table->string('processing_outcome', 64);
            $table->timestamp('received_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_webhook_events');
        Schema::dropIfExists('payment_attempts');
        Schema::dropIfExists('invoice_corrections');
        Schema::dropIfExists('invoices');
        Schema::dropIfExists('qc_checks');
        Schema::dropIfExists('estimate_revisions');
        Schema::dropIfExists('work_notes');
        Schema::dropIfExists('diagnoses');
    }
};

