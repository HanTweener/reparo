<?php

namespace Tests\Feature;

use App\Models\DeviceCategory;
use App\Models\Invoice;
use App\Models\RepairOrder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WorkflowAndPaymentTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private User $tech1;
    private User $tech2;
    private User $admin;
    private RepairOrder $order;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::factory()->create(['email' => 'cust@reparo.test', 'role_code' => 'CUSTOMER']);
        $this->tech1 = User::factory()->create(['email' => 'tech1@reparo.test', 'role_code' => 'TECHNICIAN']);
        $this->tech2 = User::factory()->create(['email' => 'tech2@reparo.test', 'role_code' => 'TECHNICIAN']);
        $this->admin = User::factory()->create(['email' => 'adm@reparo.test', 'role_code' => 'ADMIN']);
        $cat = DeviceCategory::create(['name' => 'Laptop', 'is_active' => true]);

        $this->order = RepairOrder::create([
            'public_reference' => 'REP-2026-0001',
            'customer_id' => $this->customer->id,
            'device_name' => 'Dell XPS 15',
            'category_id' => $cat->id,
            'service_code' => 'MAINTENANCE',
            'issue_description' => 'Fan noise and overheating',
            'preferred_arrival_date' => now()->addDays(2)->toDateString(),
            'status' => 'BOOKED',
            'current_technician_id' => $this->tech1->id,
            'created_by_user_id' => $this->customer->id,
            'lock_version' => 1,
        ]);
    }

    public function test_only_assigned_technician_can_start_diagnosis_and_mutate_workflow(): void
    {
        $this->actingAs($this->tech2)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start")
            ->assertStatus(403);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start")
            ->assertStatus(200);
        $this->assertEquals('DIAGNOSING', $this->order->fresh()->status);
    }

    public function test_concurrent_stale_update_rejected_with_409_state_conflict(): void
    {
        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start", ['expected_version' => 999])
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'STATE_CONFLICT');

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start", ['expected_version' => 1])
            ->assertStatus(200);
        $this->assertEquals(2, $this->order->fresh()->lock_version);
    }

    public function test_diagnosis_and_estimate_revisions_with_reason_and_safe_projections(): void
    {
        $this->order->update(['status' => 'DIAGNOSING']);

        $this->actingAs($this->tech1)
            ->putJson("/api/v1/technician/orders/{$this->order->id}/diagnosis", [
                'customer_safe_summary' => 'Debu tebal pada heatsink dan thermal paste mengering.',
            ])->assertStatus(200);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/work-notes", [
                'note_text' => 'INTERNAL: Screws on bottom case slightly stripped by previous shop.',
            ])->assertStatus(201);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", [
                'amount' => 350000,
                'currency_code' => 'IDR',
            ])->assertStatus(201);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", ['amount' => 450000])
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_ERROR');

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", [
                'amount' => 450000,
                'reason' => 'Perlu penggantian thermal pad GPU khusus selain pembersihan fan.',
            ])->assertStatus(201);

        $custRes = $this->actingAs($this->customer)
            ->getJson("/api/v1/customer/orders/{$this->order->id}");
        $custRes->assertStatus(200)
            ->assertJsonPath('data.diagnosis.customer_safe_summary', 'Debu tebal pada heatsink dan thermal paste mengering.')
            ->assertJsonCount(2, 'data.estimate_revisions')
            ->assertJsonMissing(['INTERNAL: Screws on bottom case slightly stripped by previous shop.']);
    }

    public function test_qc_loop_fail_stays_in_qc_pass_moves_to_ready_and_issues_invoice(): void
    {
        $this->order->update(['status' => 'IN_REPAIR']);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", ['amount' => 500000, 'currency_code' => 'IDR'])
            ->assertStatus(201);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/qc/start")
            ->assertStatus(200);
        $this->assertEquals('QC', $this->order->fresh()->status);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/qc-checks", [
                'result' => 'FAIL',
                'note' => 'Suhu CPU masih 85C di idle',
            ])->assertStatus(200);
        $this->assertEquals('QC', $this->order->fresh()->status);
        $this->assertNull($this->order->fresh()->invoice);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/qc-checks", [
                'result' => 'PASS',
                'note' => 'Suhu normal 42C idle',
            ])->assertStatus(200);
        $this->assertEquals('READY', $this->order->fresh()->status);

        $invoice = $this->order->fresh()->invoice;
        $this->assertNotNull($invoice);
        $this->assertEquals('500000.00', $invoice->current_amount);
        $this->assertEquals('OPEN', $invoice->status);
    }

    public function test_admin_invoice_correction_and_midtrans_webhook_payment(): void
    {
        $this->order->update(['status' => 'READY']);
        $invoice = Invoice::create([
            'order_id' => $this->order->id,
            'invoice_number' => 'INV-20261103-0001',
            'current_amount' => 500000.00,
            'currency_code' => 'IDR',
            'status' => 'OPEN',
            'issued_at' => now(),
        ]);

        $this->actingAs($this->admin)
            ->postJson("/api/v1/admin/invoices/{$invoice->id}/corrections", [
                'new_amount' => 480000.00,
                'reason' => 'Diskon loyalty.',
            ])->assertStatus(200);
        $this->assertEquals('480000.00', $invoice->fresh()->current_amount);

        $attemptRes = $this->actingAs($this->customer)
            ->postJson("/api/v1/customer/invoices/{$invoice->id}/payment-attempts");
        $attemptRes->assertStatus(201);
        $providerRef = $attemptRes->json('payment_attempt.provider_reference');

        $this->postJson('/api/v1/webhooks/midtrans', [
            'order_id' => $providerRef,
            'status_code' => '200',
            'gross_amount' => '480000.00',
            'signature_key' => 'invalid-hash',
            'transaction_status' => 'settlement',
        ])->assertStatus(401);

        $serverKey = config('services.midtrans.server_key');
        $validSig = hash('sha512', $providerRef . '200' . '480000.00' . $serverKey);

        $webhookPayload = [
            'order_id' => $providerRef,
            'status_code' => '200',
            'gross_amount' => '480000.00',
            'signature_key' => $validSig,
            'transaction_status' => 'settlement',
            'transaction_id' => 'tx-123456',
        ];

        $this->postJson('/api/v1/webhooks/midtrans', $webhookPayload)->assertStatus(200);
        $this->assertEquals('PAID', $invoice->fresh()->status);

        $this->postJson('/api/v1/webhooks/midtrans', $webhookPayload)->assertStatus(200);
    }

    public function test_handover_requires_ready_state_and_paid_invoice(): void
    {
        $this->order->update(['status' => 'READY']);
        $invoice = Invoice::create([
            'order_id' => $this->order->id,
            'invoice_number' => 'INV-20261103-0002',
            'current_amount' => 400000.00,
            'currency_code' => 'IDR',
            'status' => 'OPEN',
            'issued_at' => now(),
        ]);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/orders/{$this->order->id}/handover")
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'PAYMENT_REQUIRED');

        $invoice->update(['status' => 'PAID', 'paid_at' => now()]);

        $this->actingAs($this->tech1)
            ->postJson("/api/v1/orders/{$this->order->id}/handover", [
                'recipient_name' => 'Budi Santoso',
                'notes' => 'Unit diambil lengkap bersama charger ori',
            ])->assertStatus(200);

        $freshOrder = $this->order->fresh();
        $this->assertEquals('COMPLETED', $freshOrder->status);
        $this->assertStringContainsString('Budi Santoso', $freshOrder->statusHistory->last()->reason);
    }

    public function test_customer_invoice_access_and_corrections_visibility(): void
    {
        $otherCustomer = User::factory()->create(['email' => 'other@reparo.test', 'role_code' => 'CUSTOMER']);

        $this->order->update(['status' => 'READY']);
        $invoice = Invoice::create([
            'order_id' => $this->order->id,
            'invoice_number' => 'INV-20261103-0003',
            'current_amount' => 600000.00,
            'currency_code' => 'IDR',
            'status' => 'OPEN',
            'issued_at' => now(),
        ]);

        $this->actingAs($otherCustomer)
            ->getJson("/api/v1/orders/{$this->order->id}/invoice")
            ->assertStatus(403);

        $this->actingAs($this->admin)
            ->postJson("/api/v1/admin/invoices/{$invoice->id}/corrections", [
                'new_amount' => 550000.00,
                'reason' => 'Diskon promo akhir pekan.',
            ])->assertStatus(200);

        $this->actingAs($this->customer)
            ->getJson("/api/v1/customer/orders/{$this->order->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.invoice.amount', '550000.00')
            ->assertJsonPath('data.invoice.corrections.0.reason', 'Diskon promo akhir pekan.')
            ->assertJsonPath('data.invoice.corrections.0.previous_amount', '600000.00')
            ->assertJsonPath('data.invoice.corrections.0.new_amount', '550000.00');

        $this->actingAs($this->customer)
            ->postJson("/api/v1/invoices/{$invoice->id}/simulate-midtrans")
            ->assertStatus(200);
        $this->assertEquals('PAID', $invoice->fresh()->status);
    }
}
