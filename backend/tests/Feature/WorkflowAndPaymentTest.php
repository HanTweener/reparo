<?php

namespace Tests\Feature;

use App\Models\CustomerDevice;
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

        $this->customer = User::factory()->create([
            'email' => 'cust@reparo.test',
            'role_code' => 'CUSTOMER',
        ]);

        $this->tech1 = User::factory()->create([
            'email' => 'tech1@reparo.test',
            'role_code' => 'TECHNICIAN',
        ]);

        $this->tech2 = User::factory()->create([
            'email' => 'tech2@reparo.test',
            'role_code' => 'TECHNICIAN',
        ]);

        $this->admin = User::factory()->create([
            'email' => 'adm@reparo.test',
            'role_code' => 'ADMIN',
        ]);

        $cat = DeviceCategory::create(['name' => 'Laptop', 'is_active' => true]);
        $device = CustomerDevice::create([
            'customer_id' => $this->customer->id,
            'category_id' => $cat->id,
            'brand' => 'Dell',
            'model' => 'XPS 15',
        ]);

        $this->order = RepairOrder::create([
            'public_reference' => 'REP-2026-0001',
            'customer_id' => $this->customer->id,
            'device_id' => $device->id,
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
        // Unassigned technician tech2 gets 403
        $resForbidden = $this->actingAs($this->tech2)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start");
        $resForbidden->assertStatus(403);

        // Assigned technician tech1 starts diagnosis
        $resSuccess = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start");
        $resSuccess->assertStatus(200);
        $this->assertEquals('DIAGNOSING', $this->order->fresh()->status);
    }

    public function test_concurrent_stale_update_rejected_with_409_state_conflict(): void
    {
        // Stale update sends mismatched expected_version -> 409
        $resConflict = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start", [
                'expected_version' => 999,
            ]);
        $resConflict->assertStatus(409)
            ->assertJsonPath('error.code', 'STATE_CONFLICT');

        // Matching expected_version succeeds and advances lock_version
        $resOk = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/diagnosis/start", [
                'expected_version' => 1,
            ]);
        $resOk->assertStatus(200);
        $this->assertEquals(2, $this->order->fresh()->lock_version);
    }

    public function test_diagnosis_and_estimate_revisions_with_reason_and_safe_projections(): void
    {
        $this->order->update(['status' => 'DIAGNOSING']);

        // 1. Save diagnosis
        $diagRes = $this->actingAs($this->tech1)
            ->putJson("/api/v1/technician/orders/{$this->order->id}/diagnosis", [
                'customer_safe_summary' => 'Debu tebal pada heatsink dan thermal paste mengering.',
            ]);
        $diagRes->assertStatus(200);

        // 2. Add internal work note (staff only)
        $noteRes = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/work-notes", [
                'note_text' => 'INTERNAL: Screws on bottom case slightly stripped by previous shop.',
            ]);
        $noteRes->assertStatus(201);

        // 3. First estimate: no reason required
        $est1Res = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", [
                'amount' => 350000,
                'currency_code' => 'IDR',
            ]);
        $est1Res->assertStatus(201);

        // 4. Second estimate without reason fails with 422
        $est2Fail = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", [
                'amount' => 450000,
            ]);
        $est2Fail->assertStatus(422)
            ->assertJsonPath('error.code', 'VALIDATION_ERROR')
            ->assertJsonPath('error.fields.reason.0', 'The reason field is required.');

        // 5. Second estimate with reason succeeds
        $est2Success = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", [
                'amount' => 450000,
                'reason' => 'Perlu penggantian thermal pad GPU khusus selain pembersihan fan.',
            ]);
        $est2Success->assertStatus(201);

        // 6. Customer GET order: sees customer_safe_summary & estimates, but NO work notes
        $custRes = $this->actingAs($this->customer)
            ->getJson("/api/v1/customer/orders/{$this->order->id}");
        $custRes->assertStatus(200);
        $custRes->assertJsonPath('data.diagnosis.customer_safe_summary', 'Debu tebal pada heatsink dan thermal paste mengering.');
        $custRes->assertJsonCount(2, 'data.estimate_revisions');
        $custRes->assertJsonMissing(['INTERNAL: Screws on bottom case slightly stripped by previous shop.']);
    }

    public function test_qc_loop_fail_stays_in_qc_pass_moves_to_ready_and_issues_invoice(): void
    {
        $this->order->update(['status' => 'IN_REPAIR']);

        // Tech records initial estimate
        $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/estimates", [
                'amount' => 500000,
                'currency_code' => 'IDR',
            ]);

        // Start QC
        $startQc = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/qc/start");
        $startQc->assertStatus(200);
        $this->assertEquals('QC', $this->order->fresh()->status);

        // Submit QC FAIL -> Order remains in QC
        $qcFail = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/qc-checks", [
                'result' => 'FAIL',
                'note' => 'Suhu CPU masih 85C di idle, cek pemasangan cooler ulang',
            ]);
        $qcFail->assertStatus(200);
        $this->assertEquals('QC', $this->order->fresh()->status);
        $this->assertNull($this->order->fresh()->invoice);

        // Submit QC PASS -> Order moves to READY and issues invoice atomically
        $qcPass = $this->actingAs($this->tech1)
            ->postJson("/api/v1/technician/orders/{$this->order->id}/qc-checks", [
                'result' => 'PASS',
                'note' => 'Suhu normal 42C idle, 68C stress test passed',
            ]);
        $qcPass->assertStatus(200);
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

        // 1. Admin corrects invoice
        $corrRes = $this->actingAs($this->admin)
            ->postJson("/api/v1/admin/invoices/{$invoice->id}/corrections", [
                'new_amount' => 480000.00,
                'reason' => 'Diskon loyalty pelanggan tetap.',
            ]);
        $corrRes->assertStatus(200);
        $this->assertEquals('480000.00', $invoice->fresh()->current_amount);

        // 2. Customer creates payment attempt
        $attemptRes = $this->actingAs($this->customer)
            ->postJson("/api/v1/customer/invoices/{$invoice->id}/payment-attempts");
        $attemptRes->assertStatus(201);
        $providerRef = $attemptRes->json('payment_attempt.provider_reference');

        // 3. Webhook with invalid signature rejected with 401
        $badHook = $this->postJson('/api/v1/webhooks/midtrans', [
            'order_id' => $providerRef,
            'status_code' => '200',
            'gross_amount' => '480000.00',
            'signature_key' => 'invalid-signature-hash',
            'transaction_status' => 'settlement',
        ]);
        $badHook->assertStatus(401);

        // 4. Webhook with valid signature succeeds and marks invoice PAID
        $serverKey = config('services.midtrans.server_key');
        $validSig = hash('sha512', $providerRef . '200' . '480000.00' . $serverKey);

        $goodHook = $this->postJson('/api/v1/webhooks/midtrans', [
            'order_id' => $providerRef,
            'status_code' => '200',
            'gross_amount' => '480000.00',
            'signature_key' => $validSig,
            'transaction_status' => 'settlement',
            'transaction_id' => 'tx-123456',
        ]);
        $goodHook->assertStatus(200);
        $this->assertEquals('PAID', $invoice->fresh()->status);

        // 5. Duplicate webhook idempotent response
        $dupWebhook = $this->postJson('/api/v1/webhooks/midtrans', [
            'order_id' => $providerRef,
            'status_code' => '200',
            'gross_amount' => '480000.00',
            'signature_key' => $validSig,
            'transaction_status' => 'settlement',
            'transaction_id' => 'tx-123456',
        ]);
        $dupWebhook->assertStatus(200);
    }

    public function test_handover_requires_ready_state_and_paid_invoice(): void
    {
        $this->order->update(['status' => 'READY']);
        $invoice = Invoice::create([
            'order_id' => $this->order->id,
            'invoice_number' => 'INV-20261103-0002',
            'current_amount' => 400000.00,
            'currency_code' => 'IDR',
            'status' => 'OPEN', // Not paid yet!
            'issued_at' => now(),
        ]);

        // Handover fails because invoice is not paid
        $failHandover = $this->actingAs($this->tech1)
            ->postJson("/api/v1/orders/{$this->order->id}/handover");
        $failHandover->assertStatus(422)
            ->assertJsonPath('error.code', 'PAYMENT_REQUIRED');

        // Mark invoice PAID
        $invoice->update(['status' => 'PAID', 'paid_at' => now()]);

        // Handover succeeds and marks order COMPLETED
        $successHandover = $this->actingAs($this->tech1)
            ->postJson("/api/v1/orders/{$this->order->id}/handover");
        $successHandover->assertStatus(200);
        $this->assertEquals('COMPLETED', $this->order->fresh()->status);
    }
}
