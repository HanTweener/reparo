<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Device Categories
        Schema::create('device_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 1b. Service Categories (Master Layanan)
        Schema::create('service_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('code', 64)->unique();
            $table->decimal('base_price', 12, 2)->default(0);
            $table->string('description', 500)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 2. Repair Orders (Direct device input without customer_devices)
        Schema::create('repair_orders', function (Blueprint $table) {
            $table->id();
            $table->string('public_reference', 64)->unique();
            $table->foreignId('customer_id')->constrained('users');
            $table->string('device_name', 255);
            $table->foreignId('category_id')->nullable()->constrained('device_categories')->nullOnDelete();
            $table->string('service_code', 32)->default('MAINTENANCE');
            $table->text('issue_description');
            $table->date('preferred_arrival_date');
            $table->date('confirmed_arrival_date')->nullable();
            $table->string('status', 32)->default('BOOKED')->index();
            $table->foreignId('current_technician_id')->nullable()->constrained('users');
            $table->foreignId('created_by_user_id')->constrained('users');
            $table->unsignedInteger('lock_version')->default(1);
            $table->timestamps();

            $table->index(['customer_id', 'created_at']);
            $table->index(['current_technician_id', 'status', 'created_at']);
        });

        // 4. Order Status History (Append-only)
        Schema::create('order_status_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('repair_orders')->cascadeOnDelete();
            $table->string('previous_status', 32)->nullable();
            $table->string('new_status', 32);
            $table->foreignId('changed_by_user_id')->constrained('users');
            $table->string('reason')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['order_id', 'created_at']);
        });

        // 5. Order Assignment Events (Append-only)
        Schema::create('order_assignment_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('repair_orders')->cascadeOnDelete();
            $table->foreignId('previous_technician_id')->nullable()->constrained('users');
            $table->foreignId('new_technician_id')->constrained('users');
            $table->foreignId('changed_by_user_id')->constrained('users');
            $table->string('reason')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['order_id', 'created_at']);
        });

        // 6. Cancellation Requests
        Schema::create('cancellation_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained('repair_orders')->cascadeOnDelete();
            $table->foreignId('requested_by_user_id')->constrained('users');
            $table->text('reason')->nullable();
            $table->string('decision', 32)->default('PENDING'); // PENDING, CONFIRMED, DENIED
            $table->foreignId('decided_by_user_id')->nullable()->constrained('users');
            $table->text('decision_reason')->nullable();
            $table->timestamp('decided_at')->nullable();
            $table->timestamps();

            $table->index(['order_id', 'decision']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('cancellation_requests');
        Schema::dropIfExists('order_assignment_events');
        Schema::dropIfExists('order_status_history');
        Schema::dropIfExists('repair_orders');
        Schema::dropIfExists('customer_devices');
        Schema::dropIfExists('service_categories');
        Schema::dropIfExists('device_categories');
    }
};
