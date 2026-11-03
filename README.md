# Reparo — Maintenance & Repair Operations Platform

[![CI/CD Pipeline](https://github.com/HanTweener/reparo/actions/workflows/ci.yml/badge.svg)](https://github.com/HanTweener/reparo/actions/workflows/ci.yml)

Reparo adalah aplikasi web operasional pemeliharaan dan perbaikan perangkat (Maintenance & Repair Operations Web App) berskala produksi. Dibangun menggunakan arsitektur modular **Laravel 11 REST API** pada sisi backend dan **Flutter Web SPA** pada sisi frontend, menerapkan prinsip desain **taste-skill** (*framed-sheet* palette) dan kepatuhan anti-slop.

---

## 🛠️ Tech Stack

- **Backend**: Laravel 11 (PHP 8.2+), Laravel Sanctum, SQLite / MySQL, PHPUnit Feature Tests.
- **Frontend**: Flutter Web (Dart), Material 3, Custom Design System (`IBM Plex Sans` & `IBM Plex Mono`).
- **Payment Gateway**: Midtrans Sandbox (Snap token checkout, SHA-512 webhook signature verification, dan deduplikasi basis data).
- **CI/CD**: GitHub Actions (otomatisasi pengujian backend 21 test suites & build web bundle frontend).
- **Deployment**: Docker, Docker Compose, Nginx Reverse Proxy.

---

## 🔄 Alur Siklus Hidup Pesanan (End-to-End Lifecycle)

```
[BOOKED] ──> [DIAGNOSING] ──> [IN_REPAIR] ──> [QC] ──> [READY] ──> [COMPLETED]
   │                                           │          │
   └──> [CANCELLED] (Persetujuan Admin)        └── FAIL ──┘ (Invoice Lunas + Handover)
```

1. **Pendaftaran Perangkat & Pemesanan (`BOOKED`)**: Pelanggan mendaftarkan perangkat dan memesan jadwal kedatangan untuk layanan `MAINTENANCE`.
2. **Penjadwalan & Penugasan Teknisi (`BOOKED`)**: Admin mengonfirmasi tanggal kedatangan dan menugaskan teknisi perbaikan secara atomis.
3. **Pemeriksaan & Catatan Internal (`DIAGNOSING`)**: Teknisi mencatat ringkasan diagnosis aman pelanggan dan catatan teknis internal staf (dirahasiakan dari pelanggan).
4. **Estimasi Biaya & Pengerjaan (`IN_REPAIR`)**: Teknisi menentukan estimasi biaya (setiap revisi nominal mewajibkan pengisian alasan audit). Pengerjaan dapat langsung berjalan tanpa hambatan birokrasi persetujuan awal.
5. **Uji Kendali Mutu (`QC`)**: Teknisi melakukan uji mandiri. Jika gagal (`FAIL`), status tetap di `QC`. Jika lulus (`PASS`), status atomis berpindah ke `READY` dan menerbitkan `Invoice`.
6. **Pembayaran Midtrans Sandbox (`READY`)**: Pelanggan meninjau invoice dan melakukan pembayaran sandbox dengan verifikasi webhook aman (SHA-512).
7. **Serah Terima Fisik (`COMPLETED`)**: Staf merekam serah terima fisik setelah invoice berstatus lunas (`PAID`).

---

## 👤 Akun Demo Sintetis (Synthetic Demo Accounts)

Semua akun menggunakan kata sandi: `Password123!`

| Peran (Role) | Email | Deskripsi Workbench |
|---|---|---|
| **Pelanggan (Customer)** | `customer@reparo.test` | Portal pemantauan status, riwayat estimasi, invoice & checkout Midtrans Sandbox. |
| **Teknisi (Technician)** | `technician@reparo.test` | Workbench tugas aktif, catatan internal staf, diagnosis, dan kontrol QC. |
| **Admin Operasional** | `admin@reparo.test` | Antrean operasional, penugasan teknisi, konfirmasi jadwal, dan koreksi invoice. |

---

## 🚀 Menjalankan Aplikasi

### Opsi 1: Menjalankan dengan Docker Compose (Rekomendasi)

Jalankan seluruh stack (Backend, Frontend, dan Nginx Reverse Proxy) hanya dengan satu perintah:

```bash
docker compose up -d
```

- Buka frontend web di browser: **`http://localhost`**
- API backend tersedia di: **`http://localhost/api/v1`** atau **`http://localhost:8000/api/v1`**

### Opsi 2: Menjalankan Secara Lokal

#### 1. Backend (Laravel 11)
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --port=8000
```

#### 2. Frontend (Flutter Web)
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=3000
```

---

## 🧪 Eksekusi Pengujian (Automated Tests)

### Pengujian Backend (PHPUnit)
```bash
cd backend
php artisan test
```
*Hasil:* **21 tests, 85 assertions passed (0 failures)** mencakup pengujian otentikasi role, isolasi perangkat pelanggan, state machine workflow teknisi, penolakan catatan internal dari proyeksi publik, loop QC, tanda tangan webhook Midtrans, dan guard serah terima fisik.

### Pengujian Frontend (Flutter Widget Tests)
```bash
cd frontend
flutter test
```
*Hasil:* **4 tests passed** memverifikasi responsivitas antarmuka login, workbench pelanggan, antrean admin, dan workbench teknisi.

---

## 🔒 Keamanan dan Kualitas Kode

- **No-Godfile Standard**: Seluruh file sumber kode PHP dan Dart dipelihara strictly di bawah 300 baris kode (`< 300 LOC`).
- **Otorisasi Sisi Server**: Middleware `EnsureUserRole` memeriksa hak akses dan status aktif akun secara ketat di server.
- **Demarkasi Privasi**: Catatan teknis staf (`work_notes`) disaring secara permanen pada lapisan controller dan tidak pernah diekspos ke respon API pelanggan.
- **Idempotensi Pembayaran**: Callback webhook Midtrans diverifikasi menggunakan hash `SHA-512(order_id + status_code + gross_amount + server_key)` serta dideduplikasi dengan unik kunci basis data.

---

## 📄 Lisensi

Proyek ini dirilis di bawah lisensi [MIT](LICENSE).
