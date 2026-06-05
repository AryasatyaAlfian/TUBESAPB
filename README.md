# Sistem Presensi Mahasiswa — dengan Asisten AI

Aplikasi presensi mahasiswa berbasis **QR Code** yang terdiri dari dua bagian:
backend **Laravel** (REST API + web admin) dan frontend **Flutter** (aplikasi
mobile). Dilengkapi **asisten AI mengambang (chatbox)** yang dapat menjawab
pertanyaan seputar kehadiran dan izin secara real-time, dengan jawaban yang
menyesuaikan peran pengguna (dosen / mahasiswa).

> Tugas Besar — Analisis & Perancangan Bisnis (APB) Lanjutan.

---

## 📂 Struktur Project

Repository ini berisi **dua folder utama**:

| Folder | Peran | Teknologi |
|--------|-------|-----------|
| [`laravelwebapp/`](laravelwebapp) | **Backend** — REST API, autentikasi, database, panel web, dan "otak" Asisten AI | Laravel 11, PHP 8.2+, MySQL, Sanctum |
| [`TUBESAPB/`](TUBESAPB) | **Frontend** — aplikasi mobile yang dipakai dosen & mahasiswa | Flutter 3.11+, Dart |

### `laravelwebapp/` — Backend (Otak Sistem)

Menyediakan seluruh logika bisnis dan data. Bagian penting:

- **REST API** (`routes/api.php`) — endpoint untuk login, register, dashboard,
  scan QR, izin, enrollment, laporan, notifikasi, analitik, dan chat AI.
  Diamankan dengan **Laravel Sanctum** (token Bearer).
- **Asisten AI** (`app/Services/ChatAgentService.php` + `app/Http/Controllers/ChatController.php`) —
  endpoint `POST /api/chat`. Menggunakan **Google Gemini** dengan *function calling*.
  Peran pengguna dibaca dari **token autentikasi (server-side)**, sehingga jawaban
  otomatis menyesuaikan:
  - **Mahasiswa** → tools `get_my_attendance`, `get_my_izin` (terkunci ke akun yang login).
  - **Dosen** → tool `get_class_attendance` (hanya kelas yang ia ampu).
  - Query database dikunci per-user demi keamanan (tidak bisa melihat data orang lain).
- **Panel web** (`resources/views/`) — tampilan web untuk dosen/mahasiswa (Blade).
- **Database** (`database/migrations`, `database/seeders`) — skema dan data dummy.

### `TUBESAPB/` — Frontend (Aplikasi Mobile)

Aplikasi yang digunakan langsung oleh pengguna. Bagian penting:

- `lib/api_service.dart` — satu pintu seluruh komunikasi ke backend (HTTP).
  Token disimpan aman lewat `flutter_secure_storage`.
- `lib/main.dart` — entry point + auto-login (restore sesi tersimpan).
- `lib/screens/` — semua layar: login, register, dashboard dosen & mahasiswa,
  scan QR, izin, enrollment, laporan, analitik, jadwal, profil, notifikasi.
- `lib/widgets/chat_assistant.dart` — **chatbox AI mengambang** yang muncul di
  semua tab untuk kedua peran. Memanggil `POST /api/chat`; salam & saran
  pertanyaan menyesuaikan peran (dosen/mahasiswa). Otomatis aktif untuk setiap
  akun baru (tidak di-hardcode per user).
- `lib/theme/`, `lib/providers/` — tema (light/dark) dan state management (Provider).

---

## ✨ Fitur Utama

- 🔐 Autentikasi dua peran: **Dosen** & **Mahasiswa** (Sanctum token).
- 📷 **Presensi via QR Code** — dosen generate QR, mahasiswa scan.
- 📝 Pengajuan & validasi **izin** (dengan unggah bukti).
- 📚 **Enrollment** mata kuliah (ajukan & approve/reject).
- 📊 **Analitik & laporan** kehadiran (termasuk export PDF).
- 🔔 **Notifikasi** in-app.
- 🤖 **Asisten AI mengambang** — tanya rekap kehadiran / status izin, jawaban
  real-time & menyesuaikan peran.
- 🌗 Mode terang / gelap.

---

## 🚀 Cara Menjalankan

### Prasyarat
- PHP 8.2+ & Composer
- MySQL (atau MariaDB)
- Flutter SDK 3.11+
- Android SDK (untuk menjalankan di HP / emulator)
- **Gemini API Key** (gratis dari [Google AI Studio](https://aistudio.google.com/app/apikey)) — wajib untuk fitur chat AI.

### 1. Backend (`laravelwebapp/`)

```bash
cd laravelwebapp

# Install dependency
composer install

# Siapkan environment
copy .env.example .env        # Windows (atau: cp .env.example .env)
php artisan key:generate

# Edit .env — sesuaikan koneksi database, lalu TAMBAHKAN baris ini:
#   GEMINI_API_KEY=masukkan_api_key_anda_di_sini

# Buat database 'tubes_webpro' di MySQL, lalu migrasi + isi data dummy
php artisan migrate --seed

# Jalankan server
php artisan serve
# Berjalan di http://127.0.0.1:8000
```

> ⚠️ Jika fitur chat error, pastikan `GEMINI_API_KEY` ada di `.env`, lalu jalankan
> `php artisan config:clear` (fungsi `env()` bisa mengembalikan null bila config di-cache).

### 2. Frontend (`TUBESAPB/`)

```bash
cd TUBESAPB

# Install dependency
flutter pub get

# Jalankan ke perangkat
flutter run
```

#### ⚙️ Mengatur alamat server (penting!)

Alamat backend diatur di [`TUBESAPB/lib/api_service.dart`](TUBESAPB/lib/api_service.dart)
pada variabel `baseUrl`. Pilih sesuai cara menjalankan:

| Cara menjalankan | `baseUrl` | Catatan |
|------------------|-----------|---------|
| **HP fisik via USB** | `http://127.0.0.1:8000/api` | Jalankan `adb reverse tcp:8000 tcp:8000` setelah HP tersambung |
| **Emulator Android** | `http://10.0.2.2:8000/api` | `10.0.2.2` = loopback emulator ke PC |
| **HP via Wi-Fi (LAN)** | `http://<IP-PC>:8000/api` | Jalankan server dengan `php artisan serve --host=0.0.0.0` & buka firewall port 8000; HP + PC harus satu jaringan |

**Untuk HP fisik via USB** (paling andal):
```bash
# Terminal 1 (laravelwebapp) — biarkan berjalan
php artisan serve

# Terminal 2 (TUBESAPB)
adb reverse tcp:8000 tcp:8000
flutter run
```
> `adb reverse` perlu diulang setiap kali HP dicabut/dicolok ulang.
> Pastikan **USB debugging** aktif dan centang **"Always allow from this computer"**
> saat dialog otorisasi muncul.

---

## 👤 Akun Dummy (hasil `php artisan migrate --seed`)

| Peran | Email | Password |
|-------|-------|----------|
| Dosen | `dosen@example.com` | `password123` |
| Mahasiswa | `mahasiswa@example.com` | `password123` |
| Mahasiswa lain | `mahasiswa2@example.com` … `mahasiswa10@example.com` | `password123` |

Sudah terisi contoh mata kuliah (Pemrograman Web, Basis Data, Algoritma & Struktur
Data), enrollment, dan riwayat presensi 14 hari terakhir — siap untuk dicoba di chat AI.

---

## 🤖 Mencoba Asisten AI

Setelah login, ikon **robot mengambang** muncul di kanan-bawah. Contoh pertanyaan:

- **Sebagai Mahasiswa:** "Berapa kali saya hadir?", "Apakah saya pernah alpa?",
  "Status izin saya".
- **Sebagai Dosen:** "Rekap kehadiran kelas Basis Data", "Siapa yang sering alpa?".

---

## 🛠️ Teknologi

**Backend:** Laravel · PHP · MySQL · Laravel Sanctum · Google Gemini API
**Frontend:** Flutter · Dart · Provider · http · flutter_secure_storage ·
mobile_scanner · qr_flutter · image_picker

---

## 📌 Catatan Pengembangan

- `php artisan serve` bersifat **single-threaded**. Saat AI memproses pertanyaan
  chat (memanggil Gemini), request lain akan antri sebentar — ini normal, bukan bug.
- File `.env` (backend) berisi rahasia (API key, kredensial DB) dan **tidak**
  ikut di-commit. Gunakan `.env.example` sebagai acuan.
