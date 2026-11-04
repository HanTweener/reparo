<?php

namespace Database\Seeders;

use App\Models\DeviceCategory;
use App\Models\Diagnosis;
use App\Models\EstimateRevision;
use App\Models\Invoice;
use App\Models\OrderStatusHistory;
use App\Models\QcCheck;
use App\Models\RepairOrder;
use App\Models\User;
use App\Models\WorkNote;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $defaultPassword = Hash::make('Password123!');

        // 1. Synthetic demo accounts
        $customer = User::updateOrCreate(
            ['email' => 'customer@reparo.test'],
            [
                'name' => 'Budi Santoso',
                'password' => $defaultPassword,
                'role_code' => 'CUSTOMER',
                'email_verified_at' => now(),
                'is_active' => true,
            ]
        );

        $technician = User::updateOrCreate(
            ['email' => 'technician@reparo.test'],
            [
                'name' => 'Agus Pratama (Teknisi)',
                'password' => $defaultPassword,
                'role_code' => 'TECHNICIAN',
                'email_verified_at' => now(),
                'is_active' => true,
            ]
        );

        $admin = User::updateOrCreate(
            ['email' => 'admin@reparo.test'],
            [
                'name' => 'Siti Nurhaliza (Admin)',
                'password' => $defaultPassword,
                'role_code' => 'ADMIN',
                'email_verified_at' => now(),
                'is_active' => true,
            ]
        );

        $cashier = User::updateOrCreate(
            ['email' => 'cashier@reparo.test'],
            [
                'name' => 'Dewi Lestari (Kasir)',
                'password' => $defaultPassword,
                'role_code' => 'CASHIER',
                'email_verified_at' => now(),
                'is_active' => true,
            ]
        );

        // 2. Standard device categories
        $catLaptop = DeviceCategory::firstOrCreate(['name' => 'Laptop'], ['is_active' => true]);
        $catPhone = DeviceCategory::firstOrCreate(['name' => 'Smartphone'], ['is_active' => true]);
        DeviceCategory::firstOrCreate(['name' => 'PC Desktop'], ['is_active' => true]);

        // 3. Order 1: BOOKED (Global Pool, no technician assigned)
        $order1 = RepairOrder::updateOrCreate(
            ['public_reference' => 'REP-2026-0001'],
            [
                'customer_id' => $customer->id,
                'device_name' => 'ASUS ROG Zephyrus G14',
                'category_id' => $catLaptop->id,
                'service_code' => 'MAINTENANCE',
                'issue_description' => 'Pembersihan debu heatsink dan penggantian thermal paste pendingin.',
                'preferred_arrival_date' => now()->addDays(2)->toDateString(),
                'status' => 'BOOKED',
                'current_technician_id' => null,
                'created_by_user_id' => $customer->id,
                'lock_version' => 1,
            ]
        );
        OrderStatusHistory::firstOrCreate(
            ['order_id' => $order1->id, 'new_status' => 'BOOKED'],
            ['changed_by_user_id' => $customer->id, 'reason' => 'Pemesanan baru dibuat oleh Pelanggan.', 'created_at' => now()->subHours(5)]
        );

        // 4. Order 2: DIAGNOSING (Assigned to technician)
        $order2 = RepairOrder::updateOrCreate(
            ['public_reference' => 'REP-2026-0002'],
            [
                'customer_id' => $customer->id,
                'device_name' => 'MacBook Pro M2 14"',
                'category_id' => $catLaptop->id,
                'service_code' => 'MAINTENANCE',
                'issue_description' => 'Baterai cepat drop dan kipas berbunyi keras saat rendering video.',
                'preferred_arrival_date' => now()->addDay()->toDateString(),
                'confirmed_arrival_date' => now()->addDay()->toDateString(),
                'status' => 'DIAGNOSING',
                'current_technician_id' => $technician->id,
                'created_by_user_id' => $customer->id,
                'lock_version' => 2,
            ]
        );
        OrderStatusHistory::firstOrCreate(
            ['order_id' => $order2->id, 'new_status' => 'DIAGNOSING'],
            ['previous_status' => 'BOOKED', 'changed_by_user_id' => $technician->id, 'reason' => 'Pengecekan fisik dan sensor suhu dimulai.', 'created_at' => now()->subHours(2)]
        );

        // 5. Order 3: READY (QC Passed, Invoice Issued OPEN)
        $order3 = RepairOrder::updateOrCreate(
            ['public_reference' => 'REP-2026-0003'],
            [
                'customer_id' => $customer->id,
                'device_name' => 'Samsung Galaxy S23 Ultra',
                'category_id' => $catPhone->id,
                'service_code' => 'MAINTENANCE',
                'issue_description' => 'Perawatan rutin: pembersihan port pengisian daya dan speaker grill.',
                'preferred_arrival_date' => now()->toDateString(),
                'confirmed_arrival_date' => now()->toDateString(),
                'status' => 'READY',
                'current_technician_id' => $technician->id,
                'created_by_user_id' => $customer->id,
                'lock_version' => 4,
            ]
        );
        Diagnosis::updateOrCreate(
            ['order_id' => $order3->id],
            ['technician_id' => $technician->id, 'customer_safe_summary' => 'Port pengisian Type-C tersumbat serat kain. Speaker membran dalam kondisi prima.']
        );
        WorkNote::firstOrCreate(
            ['order_id' => $order3->id, 'note_text' => 'INTERNAL: Dibersihkan menggunakan larutan kontak cleaner non-korosif dan vacuum mini.'],
            ['author_user_id' => $technician->id, 'created_at' => now()->subHours(4)]
        );
        EstimateRevision::updateOrCreate(
            ['order_id' => $order3->id, 'revision_number' => 1],
            ['amount' => 250000.00, 'currency_code' => 'IDR', 'reason' => null, 'created_by_user_id' => $technician->id]
        );
        QcCheck::firstOrCreate(
            ['order_id' => $order3->id, 'result' => 'PASS'],
            ['technician_id' => $technician->id, 'note' => 'Arus charging stabil 25W super fast charge. Audio jernih.', 'created_at' => now()->subHours(1)]
        );
        Invoice::updateOrCreate(
            ['order_id' => $order3->id],
            [
                'invoice_number' => 'INV-20261103-0003',
                'current_amount' => 250000.00,
                'currency_code' => 'IDR',
                'status' => 'OPEN',
                'issued_at' => now()->subHours(1),
            ]
        );
    }
}
