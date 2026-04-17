import 'package:flutter/material.dart';
import '../api_service.dart';

class MahasiswaDashboardView extends StatefulWidget {
  const MahasiswaDashboardView({super.key});

  @override
  State<MahasiswaDashboardView> createState() => _MahasiswaDashboardViewState();
}

class _MahasiswaDashboardViewState extends State<MahasiswaDashboardView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _dashboardData = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final result = await _apiService.getMahasiswaDashboard();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _dashboardData = result['data'];
        } else {
          _error = result['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _loadDashboard, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    // Ekstrak data
    final mahasiswa = _dashboardData['mahasiswa'] ?? {};
    final selectedData = _dashboardData['selectedData'];
    final todaysMatkuls = _dashboardData['todaysMatkuls'] as List? ?? [];

    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang, ${mahasiswa['nama'] ?? 'Mahasiswa'}!', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('NIM: ${mahasiswa['nim'] ?? '-'}'),
                Text('Program Studi: ${mahasiswa['jurusan'] ?? '-'}'),
              ],
            ),
          ),
        ),
        
        const Text('Statistik Presensi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (selectedData != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mata Kuliah: ${selectedData['matkul']['nama']}'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('Hadir', selectedData['hadir'], Colors.greenAccent),
                      _statItem('Izin', selectedData['izin'], Colors.blueAccent),
                      _statItem('Sakit', selectedData['sakit'], Colors.orangeAccent),
                      _statItem('Alfa', selectedData['alpha'], Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: (selectedData['percentage'] ?? 0) / 100,
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 8),
                  Text('Tingkat Kehadiran: ${selectedData['percentage']}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          )
        ] else ...[
          const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Belum ada data presensi kelas.'))),
        ],

        const SizedBox(height: 24),
        const Text('Jadwal Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (todaysMatkuls.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Tidak ada jadwal kuliah hari ini.')))
        else
          ...todaysMatkuls.map((m) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.book),
                title: Text(m['nama'] ?? '-'),
                subtitle: Text('Ruang: ${m['ruangan'] ?? '-'} | Mulai: ${m['jam_mulai'] ?? '-'}'),
              ),
            );
          }),
      ],
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label),
      ],
    );
  }
}
