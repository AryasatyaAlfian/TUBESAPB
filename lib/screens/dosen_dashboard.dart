import 'package:flutter/material.dart';
import '../api_service.dart';

class DosenDashboardView extends StatefulWidget {
  const DosenDashboardView({super.key});

  @override
  State<DosenDashboardView> createState() => _DosenDashboardViewState();
}

class _DosenDashboardViewState extends State<DosenDashboardView> {
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
    final result = await _apiService.getDosenDashboard();
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
    final totalMahasiswa = _dashboardData['totalMahasiswa'] ?? 0;
    final todaysMatkuls = _dashboardData['todaysMatkuls'] as List? ?? [];
    final matkuls = _dashboardData['matkuls'] as List? ?? [];

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
                    Expanded(child: _infoTile(context, 'Total Mahasiswa', totalMahasiswa)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoTile(context, 'Total Kelas', matkuls.length)),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const Text('Jadwal Mengajar Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (todaysMatkuls.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Tidak ada jadwal mengajar hari ini.')))
        else
          ...todaysMatkuls.map((m) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.class_),
                title: Text(m['nama'] ?? '-'),
                subtitle: Text('Ruang: ${m['ruangan'] ?? '-'} | Mulai: ${m['jam_mulai'] ?? '-'}'),
                trailing: const Icon(Icons.qr_code),
                onTap: () {
                  // Navigate to generate QR (would be another screen)
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _infoTile(BuildContext context, String label, int value) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
}
