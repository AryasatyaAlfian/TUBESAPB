import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
    setState(() => _isLoading = true);
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2D43),
      highlightColor: const Color(0xFF3B3E5C),
      child: ListView(
        children: [
          Container(height: 24, width: 150, margin: const EdgeInsets.only(bottom: 16, right: 200), color: Colors.white),
          Row(
            children: [
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
            ],
          ),
          const SizedBox(height: 32),
          Container(height: 24, width: 200, margin: const EdgeInsets.only(bottom: 16, right: 150), color: Colors.white),
          Container(height: 80, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          Container(height: 80, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Error: $_error', style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDashboard, 
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
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
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('Ringkasan Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          children: [
            Expanded(child: _infoTile(context, 'Total Mahasiswa', totalMahasiswa, Icons.people, const Color(0xFF475569))),
            const SizedBox(width: 16),
            Expanded(child: _infoTile(context, 'Total Kelas', matkuls.length, Icons.class_, const Color(0xFF334155))),
          ],
        ),
        
        const Padding(
          padding: EdgeInsets.only(top: 32, bottom: 16),
          child: Text('Jadwal Mengajar Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (todaysMatkuls.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0), 
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Tidak ada jadwal mengajar hari ini.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
        else
          ...todaysMatkuls.map((m) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: Color(0xFF00B8D9), width: 6)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8D9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.class_, color: Color(0xFF00B8D9)),
                  ),
                  title: Text(m['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.room, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${m['ruangan'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${m['jam_mulai'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.white),
                      onPressed: () {
                        // Navigate to generate QR (would be another screen)
                      },
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _infoTile(BuildContext context, String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
