import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as mobile_scanner;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi Kampus',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan kata sandi harus diisi.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (_emailController.text == 'admin@kampus.com' &&
        _passwordController.text == '123456') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau kata sandi salah.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 88, color: Colors.indigo),
              const SizedBox(height: 16),
              Text('Sistem Absensi Kampus',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Masuk untuk memulai pengelolaan absensi mahasiswa dan dosen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Kata Sandi',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Masuk'),
                  onPressed: _isLoading ? null : _login,
                ),
              ),
              const SizedBox(height: 14),
              const Text('Gunakan admin@kampus.com / 123456 untuk demo.'),
            ],
          ),
        ),
      ),
    );
  }
}

enum AppSection { dashboard, mahasiswa, dosen, profile }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppSection _selectedSection = AppSection.dashboard;

  final List<Map<String, String>> _mahasiswaAbsensi = [];
  final List<Map<String, String>> _dosenAbsensi = [];

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, AppSection section) {
    final bool selected = _selectedSection == section;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.indigo : null),
      title: Text(title),
      selected: selected,
      onTap: () {
        setState(() {
          _selectedSection = section;
        });
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sectionTitle()),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    CircleAvatar(
                      radius: 28,
                      child: Icon(Icons.people, size: 32),
                    ),
                    SizedBox(height: 12),
                    Text('Admin Kampus', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 4),
                    Text('admin@kampus.com', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.dashboard, 'Dashboard', AppSection.dashboard),
              _buildDrawerItem(Icons.school, 'Absensi Mahasiswa', AppSection.mahasiswa),
              _buildDrawerItem(Icons.person, 'Absensi Dosen', AppSection.dosen),
              const Divider(),
              _buildDrawerItem(Icons.account_circle, 'Profil', AppSection.profile),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Keluar'),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSection(),
      ),
    );
  }

  String _sectionTitle() {
    switch (_selectedSection) {
      case AppSection.dashboard:
        return 'Dashboard Absensi';
      case AppSection.mahasiswa:
        return 'Absensi Mahasiswa';
      case AppSection.dosen:
        return 'Absensi Dosen';
      case AppSection.profile:
        return 'Profil Pengguna';
    }
  }

  Widget _buildSection() {
    switch (_selectedSection) {
      case AppSection.dashboard:
        return DashboardView(
          mahasiswaCount: _mahasiswaAbsensi.length,
          dosenCount: _dosenAbsensi.length,
          latestMahasiswa: _mahasiswaAbsensi,
          latestDosen: _dosenAbsensi,
        );
      case AppSection.mahasiswa:
        return MahasiswaAbsensiView(
          records: _mahasiswaAbsensi,
          onSubmit: (record) {
            setState(() {
              _mahasiswaAbsensi.insert(0, record);
            });
          },
        );
      case AppSection.dosen:
        return DosenAbsensiView(
          records: _dosenAbsensi,
          onSubmit: (record) {
            setState(() {
              _dosenAbsensi.insert(0, record);
            });
          },
        );
      case AppSection.profile:
        return ProfileView(onLogout: _logout);
    }
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.mahasiswaCount,
    required this.dosenCount,
    required this.latestMahasiswa,
    required this.latestDosen,
  });

  final int mahasiswaCount;
  final int dosenCount;
  final List<Map<String, String>> latestMahasiswa;
  final List<Map<String, String>> latestDosen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ringkasan Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _infoTile(context, 'Mahasiswa', mahasiswaCount)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoTile(context, 'Dosen', dosenCount)),
                  ],
                ),
              ],
            ),
          ),
        ),
        _activityCard('Absensi Mahasiswa Terbaru', latestMahasiswa, context, isMahasiswa: true),
        const SizedBox(height: 12),
        _activityCard('Absensi Dosen Terbaru', latestDosen, context, isMahasiswa: false),
      ],
    );
  }

  Widget _infoTile(BuildContext context, String label, int value) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _activityCard(String title, List<Map<String, String>> records, BuildContext context,
      {required bool isMahasiswa}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (records.isEmpty)
              const Text('Belum ada absensi.', style: TextStyle(color: Colors.grey))
            else
              Column(
                children: records.take(3).map((record) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(record['nama'] ?? '-'),
                    subtitle: Text(isMahasiswa
                        ? '${record['nim']} • ${record['matkul']} • ${record['keterangan']}'
                        : '${record['nip']} • ${record['matkul']} • ${record['status']}'),
                    trailing: Text(record['waktu'] ?? '-'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class MahasiswaAbsensiView extends StatefulWidget {
  const MahasiswaAbsensiView({
    super.key,
    required this.records,
    required this.onSubmit,
  });

  final List<Map<String, String>> records;
  final void Function(Map<String, String>) onSubmit;

  @override
  State<MahasiswaAbsensiView> createState() => _MahasiswaAbsensiViewState();
}

class _MahasiswaAbsensiViewState extends State<MahasiswaAbsensiView> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _matkulController = TextEditingController();
  String _keterangan = 'Hadir';

  void _scanQR() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan QR Code'),
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on),
                onPressed: () {
                  // Toggle flash if needed, but for simplicity, skip
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
              ),
              mobile_scanner.MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                    try {
                      final data = jsonDecode(barcodes.first.rawValue!);
                      if (data is Map && data.containsKey('matkul')) {
                        setState(() {
                          _matkulController.text = data['matkul'] ?? '';
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR berhasil di-scan! Mata kuliah terisi otomatis.')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('QR code tidak mengandung data mata kuliah.')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR code tidak valid atau rusak.')),
                      );
                    }
                  }
                },
              ),
              // Overlay untuk area scan
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Arahkan QR Code ke dalam kotak ini',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              // Petak-petak di sudut
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 125 - 20,
                left: MediaQuery.of(context).size.width / 2 - 125 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.red, width: 4),
                      left: BorderSide(color: Colors.red, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 125 - 20,
                right: MediaQuery.of(context).size.width / 2 - 125 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.red, width: 4),
                      right: BorderSide(color: Colors.red, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height / 2 - 125 - 20,
                left: MediaQuery.of(context).size.width / 2 - 125 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.red, width: 4),
                      left: BorderSide(color: Colors.red, width: 4),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).size.height / 2 - 125 - 20,
                right: MediaQuery.of(context).size.width / 2 - 125 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.red, width: 4),
                      right: BorderSide(color: Colors.red, width: 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_namaController.text.isEmpty || _nimController.text.isEmpty || _matkulController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data mahasiswa.')),
      );
      return;
    }

    widget.onSubmit({
      'nama': _namaController.text,
      'nim': _nimController.text,
      'matkul': _matkulController.text,
      'keterangan': _keterangan,
      'waktu': DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    });

    _namaController.clear();
    _nimController.clear();
    _matkulController.clear();
    setState(() {
      _keterangan = 'Hadir';
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _matkulController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Form Absensi Mahasiswa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _namaController,
          decoration: const InputDecoration(labelText: 'Nama Mahasiswa', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nimController,
          decoration: const InputDecoration(labelText: 'NIM', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _matkulController,
          decoration: const InputDecoration(labelText: 'Mata Kuliah', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _keterangan,
          decoration: const InputDecoration(labelText: 'Keterangan', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
            DropdownMenuItem(value: 'Izin', child: Text('Izin')),
            DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
            DropdownMenuItem(value: 'Alfa', child: Text('Alfa')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _keterangan = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR untuk Mata Kuliah'),
          onPressed: _scanQR,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Simpan Absensi'),
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        const Text('Daftar Absensi Mahasiswa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.records.isEmpty)
          const Text('Belum ada data absensi mahasiswa.', style: TextStyle(color: Colors.grey))
        else
          ...widget.records.map((record) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(record['nama'] ?? '-'),
                subtitle: Text('${record['nim']} • ${record['matkul']} • ${record['keterangan']}'),
                trailing: Text(record['waktu'] ?? '-'),
              ),
            );
          }),
      ],
    );
  }
}

class DosenAbsensiView extends StatefulWidget {
  const DosenAbsensiView({
    super.key,
    required this.records,
    required this.onSubmit,
  });

  final List<Map<String, String>> records;
  final void Function(Map<String, String>) onSubmit;

  @override
  State<DosenAbsensiView> createState() => _DosenAbsensiViewState();
}

class _DosenAbsensiViewState extends State<DosenAbsensiView> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _matkulController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  String _status = 'Masuk';

  void _submit() {
    if (_namaController.text.isEmpty || _nipController.text.isEmpty || _matkulController.text.isEmpty || _kelasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data dosen.')),
      );
      return;
    }

    widget.onSubmit({
      'nama': _namaController.text,
      'nip': _nipController.text,
      'matkul': _matkulController.text,
      'kelas': _kelasController.text,
      'status': _status,
      'waktu': DateFormat('dd MMM yyyy HH:mm').format(DateTime.now()),
    });

    _namaController.clear();
    _nipController.clear();
    _matkulController.clear();
    _kelasController.clear();
    setState(() {
      _status = 'Masuk';
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nipController.dispose();
    _matkulController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Form Absensi Dosen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        TextField(
          controller: _namaController,
          decoration: const InputDecoration(labelText: 'Nama Dosen', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nipController,
          decoration: const InputDecoration(labelText: 'NIP', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _matkulController,
          decoration: const InputDecoration(labelText: 'Mata Kuliah', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _kelasController,
          decoration: const InputDecoration(labelText: 'Kelas / Pertemuan', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'Masuk', child: Text('Masuk')),
            DropdownMenuItem(value: 'Dinas Luar', child: Text('Dinas Luar')),
            DropdownMenuItem(value: 'Online', child: Text('Online')),
            DropdownMenuItem(value: 'Tidak Hadir', child: Text('Tidak Hadir')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _status = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Simpan Absensi'),
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          icon: const Icon(Icons.qr_code),
          label: const Text('Generate QR untuk Mahasiswa'),
          onPressed: () {
            if (_matkulController.text.isEmpty || _kelasController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mohon isi mata kuliah dan kelas terlebih dahulu.')),
              );
              return;
            }
            final qrData = jsonEncode({
              'matkul': _matkulController.text,
              'kelas': _kelasController.text,
              'waktu': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
            });
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('QR Code Absensi'),
                content: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Daftar Absensi Dosen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.records.isEmpty)
          const Text('Belum ada data absensi dosen.', style: TextStyle(color: Colors.grey))
        else
          ...widget.records.map((record) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(record['nama'] ?? '-'),
                subtitle: Text('${record['nip']} • ${record['matkul']} • ${record['kelas']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(record['status'] ?? '-'),
                    const SizedBox(height: 4),
                    Text(record['waktu'] ?? '-', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Profil Pengguna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('Nama: Admin Kampus'),
                SizedBox(height: 4),
                Text('Email: admin@kampus.com'),
                SizedBox(height: 4),
                Text('Peran: Administrator Sistem Absensi'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Tentang Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Aplikasi ini dirancang untuk membantu pengelolaan absensi kampus dengan cara yang mudah, modern, dan profesional. '
          'Pengguna dapat mencatat kehadiran mahasiswa serta data absensi dosen secara cepat dan rapi.',
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          onPressed: onLogout,
        ),
      ],
    );
  }
}
