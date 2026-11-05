# Reparo — Maintenance & Repair Operations Platform

[![Reparo CI/CD Pipeline](https://github.com/HanTweener/reparo/actions/workflows/ci.yml/badge.svg)](https://github.com/HanTweener/reparo/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PHP](https://img.shields.io/badge/PHP-8.4-777BB4?logo=php)](https://php.net)
[![Laravel](https://img.shields.io/badge/Laravel-12-FF2D20?logo=laravel)](https://laravel.com)
[![Flutter](https://img.shields.io/badge/Flutter-Stable-02569B?logo=flutter)](https://flutter.dev)

Reparo adalah platform manajemen operasional servis dan pemeliharaan perangkat (*Maintenance & Repair Operations Web Platform*) berskala produksi. Sistem ini dirancang untuk mendigitalisasi seluruh siklus hidup layanan reparasi secara transparan, akuntabel, dan terstruktur—menghubungkan Pelanggan, Kasir, Teknisi, dan Admin Operasional dalam satu ekosistem terpadu.

Dibangun dengan arsitektur **Laravel 12 REST API** pada sisi backend dan **Flutter Web SPA** responsif pada sisi frontend, menerapkan standar kualitas tanpa kode berlebih (*clean architecture*, `< 300 LOC` per file), serta kepatuhan antarmuka *framed-sheet* berstandar human-friendly.

---

## 🛠️ Tech Stack

### Backend
- **Framework & Runtime**: Laravel 12 pada PHP 8.4 (CLI & Alpine Container).
- **Authentication**: Laravel Sanctum (Token-based API Authentication).
- **Database & Persistence**: SQLite dengan ACID Transaction Safety, Foreign Key Constraints, dan WAL Mode.
- **Payment Gateway**: Midtrans Sandbox (Snap token checkout, verifikasi webhook hash SHA-512, dan perlindungan idempotensi).
- **Testing**: PHPUnit & Laravel Testing Tools (24 Feature Tests, 112 assertions).

### Frontend
- **Framework & SDK**: Flutter Stable (Dart) Web Single Page Application (SPA).
- **Design System**: Material 3 dengan palet tema *framed-sheet* (`IBM Plex Sans` & `IBM Plex Mono`).
- **Responsive Layout**: Adaptif dari mobile view hingga desktop workbench layout dengan navigasi sidebar kontekstual.
- **State Management**: State decoupling berbasis `ChangeNotifier` dengan service layer terisolasi per peran.
- **Testing**: Flutter Widget Test Suite memverifikasi responsivitas flow UI tiap peran.

### Infrastruktur & DevOps
- **Containerization**: Docker multi-stage build & Docker Compose orchestration.
- **Reverse Proxy & Web Server**: Nginx Alpine terintegrasi reverse proxy ke backend API, fallback SPA routing, dan aturan ketat *Cache-Control* (`no-store, no-cache, max-age=0` pada `index.html`, `flutter_service_worker.js`, dan metadata versi) untuk mencegah keusangan aset web.
- **CI/CD Pipeline**: GitHub Actions otomatis yang menjalankan concurrency lock, static analysis Dart, build web bundle, migrasi database dengan seeder riil, eksekusi test suite PHP, serta validasi sintaks konfigurasi Nginx dan Docker Compose.

---

## 👥 Peran & Hak Akses (Role-Based Access Control)

Reparo membagi hak akses ke dalam 4 peran operasional yang terisolasi secara ketat pada middleware sisi server:

| Peran | Deskripsi Tanggung Jawab & Batasan Otoritas |
|---|---|
| **Pelanggan (`CUSTOMER`)** | - Membuat booking jadwal pemeliharaan mandiri secara online (input nama perangkat manual tanpa birokrasi registrasi perangkat bertingkat).<br>- Memantau status pengerjaan pesanan miliknya secara realtime.<br>- Melihat rincian estimasi biaya, histori revisi estimasi, dan ringkasan diagnosis publik.<br>- Melakukan pembayaran tagihan invoice secara digital via Midtrans.<br>- Mengajukan permohonan pembatalan pesanan jika perangkat belum masuk tahap perbaikan fisik. |
| **Teknisi (`TECHNICIAN`)** | - Melihat dan mengambil pesanan dari **Antrean Global** (*Self-Claiming Task*).<br>- Mengelola alur kerja teknis di workbench: memulai diagnosis, menyimpan diagnosis, menerbitkan estimasi biaya (wajib menyertakan alasan perubahan nominal untuk audit).<br>- Menulis catatan teknis internal staf yang **terisolasi permanen dari pelanggan**.<br>- Memulai perbaikan fisik dan menjalankan checklist kendali mutu (*Quality Control / QC*) mandiri.<br>- Memantau daftar tugas aktif miliknya dan riwayat pekerjaan yang telah tuntas (`COMPLETED`). |
| **Kasir (`CASHIER`)** | - Menerima unit pelanggan langsung di tempat (*Penerimaan Unit Walk-in*) dan membuat booking operasional.<br>- Memantau Antrean Kasir dan Antrean Global.<br>- Mengakses statistik operasional toko (antrean masuk, dalam pengerjaan, selesai) dengan filter harian, mingguan, bulanan, atau total.<br>- Mengonfirmasi jadwal kedatangan unit fisik pelanggan.<br>- Melakukan koreksi nominal invoice bila ada penyesuaian di meja kasir.<br>- Menjalankan prosedur serah terima fisik unit (*Physical Handover*) setelah invoice lunas.<br>*(Catatan: Kasir tidak memiliki akses ke Master Kategori dan Manajemen Staf)*. |
| **Admin Operasional (`ADMIN`)** | - Memiliki seluruh otoritas operasional yang dimiliki oleh Kasir.<br>- Mengelola **Master Kategori Perangkat** dan **Master Kategori Layanan** toko.<br>- Mengelola akun staf operasional (**Manajemen Staf & Akun**): mendaftarkan akun Teknisi, Admin, atau Kasir baru.<br>- Mengaktifkan atau menonaktifkan akses staf (`is_active: true/false`).<br>- Memantau statistik kinerja seluruh staf (jumlah tugas yang berhasil diselesaikan per personel).<br>- Memutuskan persetujuan atau penolakan permohonan pembatalan dari pelanggan. |

---

## 🔄 Alur Siklus Proses Bisnis (Business Process Lifecycle)

```
[Booking Dibuat] ───────> [Antrean Global] ───────> [Klaim oleh Teknisi]
 (Pelanggan / Walk-in)     (current_technician_id: null) (current_technician_id terisi)
                                                                 │
                                                                 ▼
[Estimasi & Pengerjaan] <─── [Input Diagnosis] <─────── [Mulai Diagnosis]
 (Revisi biaya + alasan)     (Catatan internal staf)          (DIAGNOSING)
       │
       ▼
[Mulai Perbaikan Fisik] ───> [Pengujian QC] ──────────> [QC Lolos (PASS)]
      (IN_REPAIR)                 (QC)                           │
                                   │                             ▼
                                   └── FAIL (Ulangi QC)   [Invoice Terbit]
                                                             (READY)
                                                                 │
                                                                 ▼
[Pesanan Selesai] <────── [Serah Terima Fisik] <─────── [Pembayaran Lunas]
  (COMPLETED)               (Handover Guard)               (Midtrans / PAID)
```

### Penjelasan Tahapan Alur Kerja:

1. **Inisiasi Booking & Penerimaan Unit (`BOOKED`)**:
   - Pelanggan dapat memesan secara mandiri melalui portal pelanggan, atau datang langsung ke gerai (dicatatkan oleh Kasir/Admin melalui form walk-in).
   - Input nama dan model perangkat dituliskan langsung pada satu field terpadu tanpa mewajibkan registrasi master perangkat pribadi terlebih dahulu.
   - Saat pesanan baru dibuat, kolom `current_technician_id` bernilai kosong (`null`), sehingga pesanan langsung otomatis masuk ke **Antrean Global**.

2. **Pengambilan Antrean Global (*Task Claiming*)**:
   - Seluruh teknisi yang sedang bertugas dapat melihat pesanan di Antrean Global.
   - Teknisi mengambil pesanan yang diinginkan dengan menekan tombol klaim. Kolom `current_technician_id` akan terisi secara atomis, dan pesanan secara instan berpindah dari Antrean Global ke **Tugas Saya** teknisi tersebut.

3. **Pemeriksaan & Catatan Diagnosis (`DIAGNOSING`)**:
   - Teknisi memulai fase diagnosis pada perangkat.
   - Teknisi menuliskan dua jenis data:
     - **Ringkasan Diagnosis**: Informasi kondisi perangkat yang aman dan transparan bagi pelanggan.
     - **Catatan Internal Staf (*Work Notes*)**: Catatan teknis rahasia seputar temuan kerusakan komponen, jalur PCB, atau riwayat hardware yang hanya dapat dilihat oleh staf internal toko dan disaring dari respon publik pelanggan.

4. **Penerbitan Estimasi Biaya & Perbaikan Fisik (`IN_REPAIR`)**:
   - Teknisi menentukan estimasi biaya layanan dan suku cadang. Setiap perubahan atau revisi nominal biaya wajib menyertakan alasan perubahan demi audit finansial yang akuntabel.
   - Teknisi dapat langsung menekan tombol mulai perbaikan fisik untuk memajukan status pesanan ke tahap pengerjaan aktif.

5. **Kendali Mutu Mandiri (*Quality Control / QC*)**:
   - Setelah perbaikan fisik tuntas, teknisi menguji seluruh fungsi perangkat pada tahap QC.
   - Jika hasil uji belum memuaskan (`FAIL`), teknisi mencatat temuan pengujian dan perangkat tetap berada di tahap QC untuk disempurnakan.
   - Jika uji kendali mutu dinyatakan lulus (`PASS`), status pesanan berpindah secara atomis ke `READY` dan sistem secara otomatis menerbitkan **Invoice** pembayaran.

6. **Pembayaran & Verifikasi Digital (`READY`)**:
   - Pelanggan menerima rincian invoice dan dapat melakukan pembayaran langsung melalui gateway Midtrans Sandbox (kartu, transfer bank, virtual account, atau QRIS).
   - Sistem memverifikasi keabsahan pembayaran secara otomatis menggunakan signature hash `SHA-512` melalui webhook, serta mencegah manipulasi nominal transaksi.

7. **Serah Terima Unit Fisik & Penutupan (`COMPLETED`)**:
   - Perangkat yang sudah selesai dapat diambil oleh pelanggan di kasir atau toko.
   - Tombol **Serah Terima Unit Fisik (*Handover*)** memiliki *guard protection* di level backend: penyerahan hanya dapat diproses apabila status invoice telah lunas (`PAID`).
   - Setelah serah terima dikonfirmasi oleh Kasir atau Admin, status pesanan resmi menjadi `COMPLETED` dan menambah skor performa tugas selesai bagi teknisi yang mengerjakannya.

8. **Jalur Pembatalan Pesanan (`CANCELLED`)**:
   - Pelanggan dapat mengajukan permohonan pembatalan selama pesanan belum diproses ke tahap perbaikan fisik.
   - Permohonan pembatalan memerlukan peninjauan dan persetujuan eksplisit dari Admin atau Kasir sebelum status pesanan resmi dibatalkan.

---

## ⚡ Fitur Utama Aplikasi

- **Antrean Global Mandiri (Self-Claiming Global Queue)**: Menghapus ketergantungan penugasan manual oleh atasan. Antrean yang belum memiliki teknisi muncul untuk seluruh teknisi dan dapat diambil secara mandiri.
- **Penerimaan Walk-in Kasir**: Form kasir khusus untuk pelanggan yang datang langsung ke meja gerai, langsung mencatatkan jadwal kedatangan dan data keluhan.
- **Dukungan Role Kasir Independen**: Arsitektur API dan UI kasir dibangun mandiri dan terpisah dari rute admin master, mencegah error hak akses tanpa mengorbankan keamanan.
- **Analitik & Filter Statistik Antrean**: Statistik ringkasan antrean (masuk, dalam pengerjaan, selesai, batal) dengan filter waktu interaktif (harian, mingguan, bulanan, dan total).
- **Manajemen Staf & Performa**: Perekaman skor jumlah tugas yang telah berhasil diselesaikan oleh setiap personel teknisi serta sakelar pengaktifan akses akun.
- **Manajemen Master Kategori Terpadu**: Pengaturan kategori perangkat fisik dan kategori layanan servis toko pada antarmuka admin yang terpadu.
- **Penomoran Referensi Unik Bebas Tabrakan**: Generator referensi pesanan (`REP-YYYY-XXXX`) yang aman terhadap tabrakan data dan *race condition* konkurensi.
- **Keamanan Catatan Staf**: Catatan internal disaring pada lapisan controller dan tidak pernah diekspos ke respon API sisi pelanggan.
- **Pencegahan Cache Usang Nginx**: Header HTTP khusus pada file inti Flutter Web mencegah pengguna menyimpan cache javascript/service worker lama.

---

## 🚀 Panduan Menjalankan Aplikasi

### Cara 1: Menggunakan Docker Compose (Direkomendasikan)

Pastikan Docker Desktop telah terpasang dan berjalan di komputer Anda. Jalankan perintah berikut di direktori utama repositori:

```bash
docker compose up -d
```

Layanan yang otomatis berjalan:
- **Frontend Web**: Buka browser di `http://localhost`
- **Backend API**: Tersedia di `http://localhost/api/v1` atau `http://localhost:8001/api/v1`
- **Cloudflare Tunnels**: Otomatis menghubungkan endpoint publik backend dan frontend bila token terkonfigurasi.

> **Tips Operasional**: Jika Anda mematikan atau me-restart komputer, Anda cukup membuka Docker Desktop dan menekan tombol **Start / Play (▶)** pada grup container `reparo`. Data database dan konfigurasi tersimpan aman pada Docker Volume.

---

### Cara 2: Menjalankan Secara Manual (Development Lokal)

#### 1. Persiapan Backend (Laravel 12 / PHP 8.4)
```bash
cd backend
composer install
cp .env.example .env
touch database/database.sqlite
php artisan key:generate
php artisan migrate --seed
php artisan serve --port=8000
```

#### 2. Persiapan Frontend (Flutter Web)
```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=3000
```

---

## 🧪 Pengujian Otomatis (Automated Testing)

### Pengujian Backend (PHPUnit)
Jalankan seluruh rangkaian pengujian fitur dan unit backend:
```bash
cd backend
php artisan test
```
*Cakupan Pengujian:*
- Otentikasi dan otorisasi role (`CUSTOMER`, `TECHNICIAN`, `CASHIER`, `ADMIN`).
- Validasi booking dengan input nama perangkat langsung.
- Klaim antrean global oleh teknisi dan penguncian antrean bersama.
- State machine siklus kerja teknisi: diagnosis, estimasi bertingkat, pengerjaan, dan loop QC.
- Validasi integrasi pembayaran Midtrans Sandbox dan hash webhook signature.
- Perlindungan serah terima fisik unit (*Handover Guard*).
- Pencegahan tabrakan nomor referensi publik (`public_reference` collision safety).
- Hak akses pesanan kasir dan isolasi dari master kategori/staf.

### Pengujian Frontend (Flutter Widget Tests)
Jalankan pengujian antarmuka dan interaksi komponen Flutter:
```bash
cd frontend
flutter test
```
*Cakupan Pengujian:*
- Rendering form masuk dan toggle pendaftaran akun.
- Alur portal pelanggan dan pembuatan booking baru.
- Antrean operasional dan navigasi portal admin.
- Portal kasir mandiri, filter antrean kasir, dan antrean global.
- Portal teknisi dengan tabs 'Tugas Saya', 'Antrean Global', dan 'Riwayat Selesai'.

---

## 🔒 Standar Kualitas & Kepatuhan Kode

- **No-Godfile Standard**: Setiap file sumber kode PHP dan Dart dipelihara secara ketat di bawah 300 baris kode (`< 300 LOC`) untuk menjamin keterbacaan, keterawatan, dan kemudahan pengujian.
- **Server-Side Enforcement**: Seluruh validasi bisnis, pembatasan hak akses role, serta guard serah terima unit dieksekusi di sisi server melalui middleware dan controller, bukan hanya bergantung pada proteksi antarmuka pengguna.
- **Database Transaction Integrity**: Operasi multi-tabel (pembuatan order, perubahan status history, penugasan teknisi, dan persetujuan pembatalan) dibungkus dalam transaksi database untuk menjamin integritas data (ACID).
- **Anti-Slop Clean Copy & UI**: Teks aplikasi, label navigasi, status antrean, dan dialog konfirmasi menggunakan bahasa operasional yang jelas, ringkas, dan bebas dari placeholder generik.

---

## 📄 Lisensi

Proyek ini dirilis di bawah lisensi resmi [MIT License](LICENSE).
