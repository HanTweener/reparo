<?php

namespace Tests\Feature;

use App\Models\DeviceCategory;
use App\Models\RepairOrder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceAndOrderTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private User $technician;
    private User $admin;
    private User $cashier;
    private DeviceCategory $category;

    protected function setUp(): void
    {
        parent::setUp();

        $this->customer = User::create([
            'name' => 'Customer Satu',
            'email' => 'customer1@reparo.test',
            'password' => bcrypt('Password123!'),
            'role_code' => 'CUSTOMER',
            'is_active' => true,
        ]);

        $this->technician = User::create([
            'name' => 'Teknisi Satu',
            'email' => 'technician1@reparo.test',
            'password' => bcrypt('Password123!'),
            'role_code' => 'TECHNICIAN',
            'is_active' => true,
        ]);

        $this->admin = User::create([
            'name' => 'Admin Satu',
            'email' => 'admin1@reparo.test',
            'password' => bcrypt('Password123!'),
            'role_code' => 'ADMIN',
            'is_active' => true,
        ]);

        $this->cashier = User::create([
            'name' => 'Kasir Satu',
            'email' => 'cashier1@reparo.test',
            'password' => bcrypt('Password123!'),
            'role_code' => 'CASHIER',
            'is_active' => true,
        ]);

        $this->category = DeviceCategory::create([
            'name' => 'Laptop',
            'is_active' => true,
        ]);
    }

    public function test_customer_can_book_order_with_manual_device_name(): void
    {
        $response = $this->actingAs($this->customer)->postJson('/api/v1/customer/orders', [
            'device_name' => 'Lenovo ThinkPad T14',
            'category_id' => $this->category->id,
            'service_code' => 'MAINTENANCE',
            'issue_description' => 'Pembersihan debu heatsink dan thermal paste.',
            'preferred_arrival_date' => now()->addDays(2)->format('Y-m-d'),
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'BOOKED')
            ->assertJsonPath('data.device_name', 'Lenovo ThinkPad T14');

        $this->assertDatabaseHas('repair_orders', [
            'customer_id' => $this->customer->id,
            'device_name' => 'Lenovo ThinkPad T14',
            'status' => 'BOOKED',
            'current_technician_id' => null,
        ]);
    }

    public function test_technician_can_claim_order_from_global_pool(): void
    {
        $order = RepairOrder::create([
            'public_reference' => 'REP-2026-CLAIM-01',
            'customer_id' => $this->customer->id,
            'device_name' => 'MacBook Air M1',
            'category_id' => $this->category->id,
            'service_code' => 'DIAGNOSIS',
            'issue_description' => 'Mati total setelah terkena tumpahan air.',
            'preferred_arrival_date' => now()->toDateString(),
            'status' => 'BOOKED',
            'current_technician_id' => null,
            'created_by_user_id' => $this->customer->id,
        ]);

        // Available scope shows unassigned order
        $respList = $this->actingAs($this->technician)->getJson('/api/v1/technician/orders?scope=available');
        $respList->assertStatus(200)
            ->assertJsonFragment(['public_reference' => 'REP-2026-CLAIM-01']);

        // Technician claims order
        $respClaim = $this->actingAs($this->technician)->postJson('/api/v1/technician/orders/' . $order->id . '/claim');
        $respClaim->assertStatus(200);

        $this->assertEquals($this->technician->id, $order->fresh()->current_technician_id);

        // Subsequent claim by another technician fails with conflict
        $otherTech = User::create([
            'name' => 'Teknisi Dua',
            'email' => 'technician2@reparo.test',
            'password' => bcrypt('Password123!'),
            'role_code' => 'TECHNICIAN',
            'is_active' => true,
        ]);
        $respConflict = $this->actingAs($otherTech)->postJson('/api/v1/technician/orders/' . $order->id . '/claim');
        $respConflict->assertStatus(409);
    }

    public function test_admin_and_cashier_can_create_walkin_and_view_statistics(): void
    {
        // 1. Cashier creates walk-in booking via dedicated cashier endpoint
        $respWalkin = $this->actingAs($this->cashier)->postJson('/api/v1/cashier/orders', [
            'customer_name' => 'Walkin Budi',
            'customer_email' => 'budi_walkin@example.com',
            'device_name' => 'Asus Vivobook 14',
            'category_id' => $this->category->id,
            'service_code' => 'REPAIR',
            'issue_description' => 'Keyboard tombol enter tidak berfungsi.',
            'arrival_date' => now()->toDateString(),
        ]);
        $respWalkin->assertStatus(201)
            ->assertJsonPath('data.status', 'BOOKED');

        // 2. Both Admin and Cashier can view statistics on their respective endpoints
        $respStatsAdmin = $this->actingAs($this->admin)->getJson('/api/v1/admin/orders/statistics?period=day');
        $respStatsAdmin->assertStatus(200)->assertJsonStructure(['data' => ['period', 'incoming', 'total']]);

        $respStatsCashier = $this->actingAs($this->cashier)->getJson('/api/v1/cashier/orders/statistics?period=day');
        $respStatsCashier->assertStatus(200);
    }

    public function test_cashier_cannot_manage_staff_or_categories(): void
    {
        // Cashier cannot list staff
        $respStaff = $this->actingAs($this->cashier)->getJson('/api/v1/admin/staff');
        $respStaff->assertStatus(403);

        // Cashier cannot create categories
        $respCat = $this->actingAs($this->cashier)->postJson('/api/v1/admin/device-categories', [
            'name' => 'Drone',
        ]);
        $respCat->assertStatus(403);

        // Admin CAN manage staff and categories
        $respStaffAdmin = $this->actingAs($this->admin)->getJson('/api/v1/admin/staff');
        $respStaffAdmin->assertStatus(200);

        $respCatAdmin = $this->actingAs($this->admin)->postJson('/api/v1/admin/device-categories', [
            'name' => 'Drone',
        ]);
        $respCatAdmin->assertStatus(201);

        $respServAdmin = $this->actingAs($this->admin)->postJson('/api/v1/admin/service-categories', [
            'name' => 'Refurbish Fan',
            'base_price' => 75000,
        ]);
        $respServAdmin->assertStatus(201);
    }

    public function test_cancellation_flow(): void
    {
        $order = RepairOrder::create([
            'public_reference' => 'REP-2026-CANCEL',
            'customer_id' => $this->customer->id,
            'device_name' => 'HP Pavilion 15',
            'category_id' => $this->category->id,
            'service_code' => 'MAINTENANCE',
            'issue_description' => 'Port USB-C longgar.',
            'preferred_arrival_date' => now()->toDateString(),
            'status' => 'BOOKED',
            'created_by_user_id' => $this->customer->id,
        ]);

        $respCancel = $this->actingAs($this->customer)->postJson('/api/v1/customer/orders/' . $order->id . '/cancellation-requests', [
            'reason' => 'Perangkat sudah normal kembali.',
        ]);
        $respCancel->assertStatus(201);

        $respDecision = $this->actingAs($this->admin)->postJson('/api/v1/admin/orders/' . $order->id . '/cancellation-decision', [
            'decision' => 'CONFIRMED',
            'reason' => 'Disetujui.',
        ]);
        $respDecision->assertStatus(200);
        $this->assertEquals('CANCELLED', $order->fresh()->status);
    }

    public function test_shared_global_queue_accessible_by_staff_roles_and_forbidden_for_customer(): void
    {
        $order = RepairOrder::create([
            'public_reference' => 'REP-2026-GLOBAL-TEST',
            'customer_id' => $this->customer->id,
            'device_name' => 'MacBook Pro M2',
            'category_id' => $this->category->id,
            'service_code' => 'MAINTENANCE',
            'issue_description' => 'Thermal paste repaste.',
            'preferred_arrival_date' => now()->toDateString(),
            'status' => 'BOOKED',
            'current_technician_id' => null,
            'created_by_user_id' => $this->customer->id,
        ]);

        // Unauthenticated is rejected (401)
        $this->getJson('/api/v1/orders/global-queue')
            ->assertStatus(401);

        // Customer is forbidden (403)
        $this->actingAs($this->customer)->getJson('/api/v1/orders/global-queue')
            ->assertStatus(403);

        // Staff roles are allowed (200)
        $this->actingAs($this->admin)->getJson('/api/v1/orders/global-queue')
            ->assertStatus(200)->assertJsonPath('data.0.id', (string) $order->id);

        $this->actingAs($this->cashier)->getJson('/api/v1/orders/global-queue')
            ->assertStatus(200)->assertJsonPath('data.0.id', (string) $order->id);

        $this->actingAs($this->technician)->getJson('/api/v1/orders/global-queue')
            ->assertStatus(200)->assertJsonPath('data.0.id', (string) $order->id);
    }

    public function test_cashier_has_order_authority_on_admin_endpoints_but_forbidden_from_staff_and_categories(): void
    {
        // Cashier can read admin orders queue and statistics
        $this->actingAs($this->cashier)->getJson('/api/v1/admin/orders')
            ->assertStatus(200);

        $this->actingAs($this->cashier)->getJson('/api/v1/admin/orders/statistics?period=all')
            ->assertStatus(200);

        // Cashier can create order on admin endpoint
        $this->actingAs($this->cashier)->postJson('/api/v1/admin/orders', [
            'customer_name' => 'Budi Walkin',
            'device_name' => 'Acer Swift 3',
            'issue_description' => 'Ganti keyboard laptop.',
            'preferred_arrival_date' => now()->toDateString(),
        ])->assertStatus(201);

        // Cashier is strictly forbidden from master categories & staff management
        $this->actingAs($this->cashier)->postJson('/api/v1/admin/device-categories', ['name' => 'Tablet'])
            ->assertStatus(403);

        $this->actingAs($this->cashier)->getJson('/api/v1/admin/staff')
            ->assertStatus(403);
    }
}
