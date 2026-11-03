<?php

namespace Tests\Feature;

use App\Models\CustomerDevice;
use App\Models\DeviceCategory;
use App\Models\RepairOrder;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DeviceAndOrderTest extends TestCase
{
    use RefreshDatabase;

    private User $customer;
    private User $otherCustomer;
    private User $technician;
    private User $admin;
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

        $this->otherCustomer = User::create([
            'name' => 'Customer Dua',
            'email' => 'customer2@reparo.test',
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

        $this->category = DeviceCategory::create([
            'name' => 'Laptop',
            'is_active' => true,
        ]);
    }

    public function test_customer_can_register_device(): void
    {
        $response = $this->actingAs($this->customer)->postJson('/api/v1/customer/devices', [
            'category_id' => $this->category->id,
            'brand' => 'Lenovo',
            'model' => 'ThinkPad T14',
            'serial_number' => 'SN-THINK-1234',
            'description' => 'Laptop kerja',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.brand', 'Lenovo')
            ->assertJsonPath('data.model', 'ThinkPad T14');

        $this->assertDatabaseHas('customer_devices', [
            'customer_id' => $this->customer->id,
            'model' => 'ThinkPad T14',
        ]);
    }

    public function test_customer_cannot_use_inactive_category(): void
    {
        $inactiveCat = DeviceCategory::create(['name' => 'Obsolete Device', 'is_active' => false]);

        $response = $this->actingAs($this->customer)->postJson('/api/v1/customer/devices', [
            'category_id' => $inactiveCat->id,
            'brand' => 'OldBrand',
            'model' => 'OldModel',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('error.code', 'INACTIVE_CATEGORY');
    }

    public function test_customer_cannot_view_another_customers_device(): void
    {
        $otherDevice = CustomerDevice::create([
            'customer_id' => $this->otherCustomer->id,
            'category_id' => $this->category->id,
            'brand' => 'Apple',
            'model' => 'MacBook Air M2',
        ]);

        $response = $this->actingAs($this->customer)->getJson('/api/v1/customer/devices/' . $otherDevice->id);

        $response->assertStatus(404)
            ->assertJsonPath('error.code', 'RESOURCE_UNAVAILABLE');
    }

    public function test_customer_can_book_maintenance_order_for_owned_device(): void
    {
        $device = CustomerDevice::create([
            'customer_id' => $this->customer->id,
            'category_id' => $this->category->id,
            'brand' => 'Dell',
            'model' => 'XPS 13',
        ]);

        $response = $this->actingAs($this->customer)->postJson('/api/v1/customer/orders', [
            'device_id' => $device->id,
            'issue_description' => 'Baterai menggelembung dan touchpad keras.',
            'preferred_arrival_date' => now()->addDays(2)->format('Y-m-d'),
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('data.status', 'BOOKED')
            ->assertJsonPath('data.service_code', 'MAINTENANCE');

        $this->assertDatabaseHas('repair_orders', [
            'customer_id' => $this->customer->id,
            'device_id' => $device->id,
            'status' => 'BOOKED',
        ]);

        $this->assertDatabaseHas('order_status_history', [
            'new_status' => 'BOOKED',
            'changed_by_user_id' => $this->customer->id,
        ]);
    }

    public function test_customer_cannot_book_with_foreign_device(): void
    {
        $foreignDevice = CustomerDevice::create([
            'customer_id' => $this->otherCustomer->id,
            'category_id' => $this->category->id,
            'brand' => 'Apple',
            'model' => 'MacBook Pro',
        ]);

        $response = $this->actingAs($this->customer)->postJson('/api/v1/customer/orders', [
            'device_id' => $foreignDevice->id,
            'issue_description' => 'Layar bergaris warna ungu.',
            'preferred_arrival_date' => now()->addDays(2)->format('Y-m-d'),
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('error.code', 'INVALID_DEVICE');
    }

    public function test_admin_can_confirm_schedule_and_assign_technician(): void
    {
        $device = CustomerDevice::create([
            'customer_id' => $this->customer->id,
            'category_id' => $this->category->id,
            'brand' => 'Acer',
            'model' => 'Swift 3',
        ]);

        $order = RepairOrder::create([
            'public_reference' => 'REP-2026-9999',
            'customer_id' => $this->customer->id,
            'device_id' => $device->id,
            'service_code' => 'MAINTENANCE',
            'issue_description' => 'Kipas mati total.',
            'preferred_arrival_date' => now()->addDay()->toDateString(),
            'status' => 'BOOKED',
            'created_by_user_id' => $this->customer->id,
        ]);

        // 1. Confirm schedule
        $respSched = $this->actingAs($this->admin)->patchJson('/api/v1/admin/orders/' . $order->id . '/schedule', [
            'confirmed_arrival_date' => now()->addDay()->toDateString(),
        ]);
        $respSched->assertStatus(200);

        // 2. Assign technician
        $respAssign = $this->actingAs($this->admin)->putJson('/api/v1/admin/orders/' . $order->id . '/assignment', [
            'technician_id' => $this->technician->id,
            'reason' => 'Spesialis modul pendingin.',
        ]);

        $respAssign->assertStatus(200)
            ->assertJsonPath('data.technician.id', (string) $this->technician->id);

        $this->assertDatabaseHas('repair_orders', [
            'id' => $order->id,
            'current_technician_id' => $this->technician->id,
        ]);

        $this->assertDatabaseHas('order_assignment_events', [
            'order_id' => $order->id,
            'new_technician_id' => $this->technician->id,
            'changed_by_user_id' => $this->admin->id,
        ]);
    }

    public function test_cancellation_flow_pre_diagnosis(): void
    {
        $device = CustomerDevice::create([
            'customer_id' => $this->customer->id,
            'category_id' => $this->category->id,
            'brand' => 'HP',
            'model' => 'Envy 13',
        ]);

        $order = RepairOrder::create([
            'public_reference' => 'REP-2026-8888',
            'customer_id' => $this->customer->id,
            'device_id' => $device->id,
            'service_code' => 'MAINTENANCE',
            'issue_description' => 'Port USB-C longgar.',
            'preferred_arrival_date' => now()->addDay()->toDateString(),
            'status' => 'BOOKED',
            'created_by_user_id' => $this->customer->id,
        ]);

        // Customer requests cancel
        $respCancelReq = $this->actingAs($this->customer)->postJson('/api/v1/customer/orders/' . $order->id . '/cancellation-requests', [
            'reason' => 'Perangkat sudah diperbaiki sendiri.',
        ]);
        $respCancelReq->assertStatus(201)
            ->assertJsonPath('data.decision', 'PENDING');

        // Order remains in BOOKED state
        $this->assertEquals('BOOKED', $order->fresh()->status);

        // Admin confirms cancellation
        $respDecision = $this->actingAs($this->admin)->postJson('/api/v1/admin/orders/' . $order->id . '/cancellation-decision', [
            'decision' => 'CONFIRMED',
            'reason' => 'Dibatalkan atas permintaan pelanggan sebelum teknisi bertindak.',
        ]);

        $respDecision->assertStatus(200)
            ->assertJsonPath('data.status', 'CANCELLED');

        $this->assertEquals('CANCELLED', $order->fresh()->status);
        $this->assertDatabaseHas('order_status_history', [
            'order_id' => $order->id,
            'new_status' => 'CANCELLED',
        ]);
    }
}

