<?php

namespace Database\Seeders;

use App\Models\DeviceCategory;
use App\Models\Diagnosis;
use App\Models\EstimateRevision;
use App\Models\Invoice;
use App\Models\OrderHandover;
use App\Models\OrderStatusHistory;
use App\Models\QcCheck;
use App\Models\RepairOrder;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Models\WorkNote;
use Carbon\Carbon;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $pwd = Hash::make('Password123!');

        // 1. Core & Staff Accounts
        $custDemo = User::updateOrCreate(['email' => 'customer@reparo.test'], [
            'name' => 'Budi Santoso', 'password' => $pwd, 'role_code' => 'CUSTOMER', 'is_active' => true, 'email_verified_at' => now(),
        ]);
        $techAgus = User::updateOrCreate(['email' => 'technician@reparo.test'], [
            'name' => 'Agus Pratama (Teknisi Senior)', 'password' => $pwd, 'role_code' => 'TECHNICIAN', 'is_active' => true, 'email_verified_at' => now(),
        ]);
        $adminSiti = User::updateOrCreate(['email' => 'admin@reparo.test'], [
            'name' => 'Siti Nurhaliza (Admin Ops)', 'password' => $pwd, 'role_code' => 'ADMIN', 'is_active' => true, 'email_verified_at' => now(),
        ]);
        $cashierDewi = User::updateOrCreate(['email' => 'cashier@reparo.test'], [
            'name' => 'Dewi Lestari (Kasir Utama)', 'password' => $pwd, 'role_code' => 'CASHIER', 'is_active' => true, 'email_verified_at' => now(),
        ]);

        $techRizky = User::updateOrCreate(['email' => 'rizky@reparo.test'], [
            'name' => 'Rizky Ramadhan (Teknisi Display)', 'password' => $pwd, 'role_code' => 'TECHNICIAN', 'is_active' => true, 'email_verified_at' => now(),
        ]);
        $techDonny = User::updateOrCreate(['email' => 'donny@reparo.test'], [
            'name' => 'Donny Kurniawan (Teknisi IC Board)', 'password' => $pwd, 'role_code' => 'TECHNICIAN', 'is_active' => true, 'email_verified_at' => now(),
        ]);
        $cashierAnisa = User::updateOrCreate(['email' => 'anisa@reparo.test'], [
            'name' => 'Anisa Putri (Kasir)', 'password' => $pwd, 'role_code' => 'CASHIER', 'is_active' => true, 'email_verified_at' => now(),
        ]);
        $adminHendra = User::updateOrCreate(['email' => 'hendra@reparo.test'], [
            'name' => 'Hendra Wijaya (Admin Gudang)', 'password' => $pwd, 'role_code' => 'ADMIN', 'is_active' => true, 'email_verified_at' => now(),
        ]);

        // Customer pool
        $customers = [
            $custDemo,
            User::firstOrCreate(['email' => 'rian@reparo.customer'], ['name' => 'Rian Hidayat', 'password' => $pwd, 'role_code' => 'CUSTOMER', 'is_active' => true]),
            User::firstOrCreate(['email' => 'maya@reparo.customer'], ['name' => 'Maya Anggraini', 'password' => $pwd, 'role_code' => 'CUSTOMER', 'is_active' => true]),
            User::firstOrCreate(['email' => 'eko@reparo.customer'], ['name' => 'Eko Prasetyo', 'password' => $pwd, 'role_code' => 'CUSTOMER', 'is_active' => true]),
            User::firstOrCreate(['email' => 'lina@reparo.customer'], ['name' => 'Lina Marlina', 'password' => $pwd, 'role_code' => 'CUSTOMER', 'is_active' => true]),
            User::firstOrCreate(['email' => 'sarah@reparo.customer'], ['name' => 'Sarah Jessica', 'password' => $pwd, 'role_code' => 'CUSTOMER', 'is_active' => true]),
        ];

        // 2. Master Device Categories
        $catLaptop = DeviceCategory::firstOrCreate(['name' => 'Laptop'], ['is_active' => true]);
        $catPhone = DeviceCategory::firstOrCreate(['name' => 'Smartphone'], ['is_active' => true]);
        $catPc = DeviceCategory::firstOrCreate(['name' => 'PC Desktop'], ['is_active' => true]);
        $catTablet = DeviceCategory::firstOrCreate(['name' => 'Tablet'], ['is_active' => true]);
        $catConsole = DeviceCategory::firstOrCreate(['name' => 'Konsol Game'], ['is_active' => true]);
        $devCats = [$catLaptop, $catPhone, $catPc, $catTablet, $catConsole];

        // 3. Master Service Categories
        ServiceCategory::firstOrCreate(['code' => 'MAINTENANCE'], [
            'name' => 'Pembersihan & Repaste Thermal', 'base_price' => 150000, 'description' => 'Deep cleaning debu heatsink dan pasta termal grade tinggi.', 'is_active' => true,
        ]);
        ServiceCategory::firstOrCreate(['code' => 'SCREEN_REPAIR'], [
            'name' => 'Ganti Layar / LCD Display', 'base_price' => 450000, 'description' => 'Penggantian panel display pecah, bergaris, atau blank.', 'is_active' => true,
        ]);
        ServiceCategory::firstOrCreate(['code' => 'BATTERY_REPLACEMENT'], [
            'name' => 'Ganti Baterai Original', 'base_price' => 250000, 'description' => 'Solusi baterai kembung, drop, atau tidak mau charging.', 'is_active' => true,
        ]);
        ServiceCategory::firstOrCreate(['code' => 'STORAGE_UPGRADE'], [
            'name' => 'Upgrade SSD & RAM', 'base_price' => 350000, 'description' => 'Peningkatan kapasitas NVMe PCIe dan memori DDR4/DDR5.', 'is_active' => true,
        ]);
        ServiceCategory::firstOrCreate(['code' => 'OS_INSTALLATION'], [
            'name' => 'Install Ulang OS & Optimasi', 'base_price' => 120000, 'description' => 'Pemasangan sistem operasi bersih lengkap driver resmi.', 'is_active' => true,
        ]);
        ServiceCategory::firstOrCreate(['code' => 'MOTHERBOARD_REPAIR'], [
            'name' => 'Perbaikan Jalur Motherboard / IC', 'base_price' => 650000, 'description' => 'Micro-soldering korslet power supply dan IC pengisian.', 'is_active' => true,
        ]);

        // 4. Multi-period realistic seed records (30+ orders)
        $orderData = [
            // Global Pool (BOOKED, current_technician_id: null) - available to claim
            ['ASUS ROG Zephyrus G14', $catLaptop->id, 'MAINTENANCE', 'Suhu panas tembus 95C saat gaming, kipas berisik.', 'BOOKED', null, 2, 'today'],
            ['Lenovo ThinkPad T14', $catLaptop->id, 'BATTERY_REPLACEMENT', 'Baterai drop dari 80% langsung mati mendadak.', 'BOOKED', null, 5, 'today'],
            ['iPhone 13 Pro', $catPhone->id, 'SCREEN_REPAIR', 'Kaca depan retak seribu akibat jatuh dari meja.', 'BOOKED', null, 1, 'this_week'],
            ['PlayStation 5 Disc Edition', $catConsole->id, 'MAINTENANCE', 'Pembersihan debu heatsink dan liquid metal overheat.', 'BOOKED', null, 3, 'this_week'],
            ['iPad Air 5 M1', $catTablet->id, 'BATTERY_REPLACEMENT', 'Port USB-C longgar dan baterai tidak terisi.', 'BOOKED', null, 4, 'this_week'],
            ['PC Custom Ryzen 7', $catPc->id, 'STORAGE_UPGRADE', 'Tambah SSD M.2 1TB dan migrasi data OS.', 'BOOKED', null, 6, 'this_month'],

            // In Progress: DIAGNOSING (assigned to technicians)
            ['MacBook Pro 16 2021', $catLaptop->id, 'MOTHERBOARD_REPAIR', 'Tidak mau menyala sama sekali setelah terkena air teh.', 'DIAGNOSING', $techDonny->id, 8, 'today'],
            ['Samsung Galaxy S22', $catPhone->id, 'BATTERY_REPLACEMENT', 'Back cover terangkat karena baterai mengembang.', 'DIAGNOSING', $techRizky->id, 12, 'this_week'],
            ['Dell XPS 15 9500', $catLaptop->id, 'MAINTENANCE', 'Fan kiri berbunyi kasar dan sering throttling.', 'DIAGNOSING', $techAgus->id, 15, 'this_week'],

            // In Progress: IN_REPAIR
            ['Acer Predator Helios 300', $catLaptop->id, 'MOTHERBOARD_REPAIR', 'Mati total jalur 19V short to ground pada VRM.', 'IN_REPAIR', $techDonny->id, 10, 'this_week'],
            ['Xiaomi 12 Pro', $catPhone->id, 'SCREEN_REPAIR', 'Layar bergaris hijau vertikal di tengah panel.', 'IN_REPAIR', $techRizky->id, 14, 'today'],
            ['HP Envy x360', $catLaptop->id, 'STORAGE_UPGRADE', 'Upgrade RAM ke 32GB dan pasang thermal pad baru.', 'IN_REPAIR', $techAgus->id, 18, 'this_week'],

            // In Progress: QC
            ['MacBook Air M1', $catLaptop->id, 'BATTERY_REPLACEMENT', 'Siklus baterai 1400, health 62% butuh ganti cell.', 'QC', $techAgus->id, 20, 'today'],
            ['Nintendo Switch OLED', $catConsole->id, 'SCREEN_REPAIR', 'Joycon drift dan touchscreen tidak responsif sebagian.', 'QC', $techRizky->id, 22, 'this_week'],

            // READY (Awaiting customer payment / pickup)
            ['iPhone 14 Pro Max', $catPhone->id, 'SCREEN_REPAIR', 'Ganti LCD OLED original, True Tone sudah ditransfer.', 'READY', $techRizky->id, 25, 'today'],
            ['Lenovo Legion 5', $catLaptop->id, 'MAINTENANCE', 'Repaste PTM7950 dan pembersihan fan selesai.', 'READY', $techAgus->id, 28, 'this_week'],

            // COMPLETED (Handed over, gives staff completed tasks score)
            ['MacBook Pro 14 M2', $catLaptop->id, 'MAINTENANCE', 'Cleaning debu dan ganti thermal paste.', 'COMPLETED', $techAgus->id, 30, 'today'],
            ['ThinkPad X1 Carbon Gen 9', $catLaptop->id, 'BATTERY_REPLACEMENT', 'Baterai baru 57Wh terpasang dan kalibrasi.', 'COMPLETED', $techAgus->id, 32, 'today'],
            ['ASUS TUF Gaming A15', $catLaptop->id, 'STORAGE_UPGRADE', 'Tambah SSD Kingston 1TB NVMe.', 'COMPLETED', $techAgus->id, 34, 'this_week'],
            ['PC Gaming RTX 4070', $catPc->id, 'MAINTENANCE', 'Cable management & deep cleaning komplit.', 'COMPLETED', $techAgus->id, 36, 'this_week'],
            ['MacBook Air M2 2022', $catLaptop->id, 'OS_INSTALLATION', 'Restore macOS Sonoma dan backup data aman.', 'COMPLETED', $techAgus->id, 38, 'this_month'],
            ['HP Pavilion 14', $catLaptop->id, 'MAINTENANCE', 'Thermal paste diganti, suhu turun 18 derajat.', 'COMPLETED', $techAgus->id, 40, 'this_month'],

            ['Samsung Galaxy Z Fold 4', $catPhone->id, 'SCREEN_REPAIR', 'Ganti layar fleksibel dalam dan engsel bersih.', 'COMPLETED', $techRizky->id, 42, 'today'],
            ['iPhone 12 Mini', $catPhone->id, 'BATTERY_REPLACEMENT', 'Health 100% baterai OEM garansi 6 bulan.', 'COMPLETED', $techRizky->id, 44, 'this_week'],
            ['Google Pixel 7', $catPhone->id, 'SCREEN_REPAIR', 'Layar OLED 90Hz ganti baru responsif.', 'COMPLETED', $techRizky->id, 46, 'this_week'],
            ['iPad Pro 11 M1', $catTablet->id, 'BATTERY_REPLACEMENT', 'Baterai original iPad terpasang rapi.', 'COMPLETED', $techRizky->id, 48, 'this_month'],
            ['Xiaomi Pad 5', $catTablet->id, 'SCREEN_REPAIR', 'Digitizer kaca depan baru mulus.', 'COMPLETED', $techRizky->id, 50, 'this_month'],

            ['ASUS ROG Strix Scar 17', $catLaptop->id, 'MOTHERBOARD_REPAIR', 'Reballing IC VRAM dan ganti kapasitor SMD.', 'COMPLETED', $techDonny->id, 52, 'today'],
            ['MSI Stealth 15M', $catLaptop->id, 'MOTHERBOARD_REPAIR', 'Perbaikan jalur bios chip flash ulang.', 'COMPLETED', $techDonny->id, 54, 'this_week'],
            ['Xbox Series X', $catConsole->id, 'MOTHERBOARD_REPAIR', 'Ganti port HDMI retak dan retimer chip IC.', 'COMPLETED', $techDonny->id, 56, 'this_month'],
            ['Gigabyte Aorus 15', $catLaptop->id, 'MOTHERBOARD_REPAIR', 'Korslet charging port DC jack disolder ulang.', 'COMPLETED', $techDonny->id, 58, 'this_month'],

            // CANCELLED
            ['Oppo Reno 8', $catPhone->id, 'SCREEN_REPAIR', 'Pelanggan membatalkan servis karena membeli unit baru.', 'CANCELLED', null, 60, 'this_week'],
            ['Dell Inspiron 14', $catLaptop->id, 'MOTHERBOARD_REPAIR', 'Biaya perbaikan melebihi estimasi anggaran customer.', 'CANCELLED', $techDonny->id, 62, 'this_month'],
        ];

        foreach ($orderData as $i => $item) {
            $ref = sprintf('REP-2026-%04d', $item[6]);
            $cust = $customers[$i % count($customers)];
            $cDate = match ($item[7]) {
                'today' => Carbon::now()->subHours(rand(1, 10)),
                'this_week' => Carbon::now()->subDays(rand(1, 4)),
                'this_month' => Carbon::now()->subDays(rand(8, 25)),
                default => Carbon::now()->subDays(35),
            };

            $order = RepairOrder::updateOrCreate(['public_reference' => $ref], [
                'customer_id' => $cust->id,
                'device_name' => $item[0],
                'category_id' => $item[1],
                'service_code' => $item[2],
                'issue_description' => $item[3],
                'preferred_arrival_date' => $cDate->toDateString(),
                'confirmed_arrival_date' => $cDate->toDateString(),
                'status' => $item[4],
                'current_technician_id' => $item[5],
                'created_by_user_id' => ($i % 3 === 0) ? $cashierDewi->id : $cust->id,
                'lock_version' => 1,
                'created_at' => $cDate,
                'updated_at' => $cDate,
            ]);

            OrderStatusHistory::firstOrCreate(['order_id' => $order->id, 'new_status' => $item[4]], [
                'previous_status' => null,
                'changed_by_user_id' => $item[5] ?? $cust->id,
                'reason' => 'Perubahan status pengerjaan sesuai workflow operasional.',
                'created_at' => $cDate,
            ]);

            if (in_array($item[4], ['DIAGNOSING', 'IN_REPAIR', 'QC', 'READY', 'COMPLETED'])) {
                Diagnosis::updateOrCreate(['order_id' => $order->id], [
                    'technician_id' => $item[5] ?? $techAgus->id,
                    'customer_safe_summary' => 'Hasil diagnosis awal: terdeteksi kebutuhan penanganan komponen terkait.',
                    'created_at' => $cDate,
                ]);
                WorkNote::firstOrCreate(['order_id' => $order->id, 'note_text' => 'Catatan teknisi: pengecekan kelistrikan dan tegangan awal stabil.'], [
                    'author_user_id' => $item[5] ?? $techAgus->id, 'created_at' => $cDate,
                ]);
                EstimateRevision::firstOrCreate(['order_id' => $order->id, 'revision_number' => 1], [
                    'created_by_user_id' => $item[5] ?? $techAgus->id,
                    'amount' => 250000 + ($i * 15000),
                    'currency_code' => 'IDR',
                    'reason' => 'Estimasi biaya suku cadang dan jasa perbaikan.',
                    'created_at' => $cDate,
                ]);
            }

            if (in_array($item[4], ['READY', 'COMPLETED'])) {
                $inv = Invoice::updateOrCreate(['order_id' => $order->id], [
                    'invoice_number' => sprintf('INV-2026%02d-%04d', $cDate->month, $item[6]),
                    'current_amount' => 350000 + ($i * 20000),
                    'currency_code' => 'IDR',
                    'status' => ($item[4] === 'COMPLETED') ? 'PAID' : 'OPEN',
                    'issued_at' => $cDate,
                    'paid_at' => ($item[4] === 'COMPLETED') ? $cDate->addHours(2) : null,
                ]);
            }
        }
    }
}
