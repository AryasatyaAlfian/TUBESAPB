import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
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
    setState(() => _isLoading = true);
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

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2D43),
      highlightColor: const Color(0xFF3B3E5C),
      child: ListView(
        children: [
          Container(height: 120, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          Container(height: 24, width: 150, margin: const EdgeInsets.only(bottom: 12, right: 200), color: Colors.white),
          Container(height: 200, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          Container(height: 24, width: 150, margin: const EdgeInsets.only(bottom: 12, right: 200), color: Colors.white),
          Container(height: 80, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          Container(height: 80, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
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
    final mahasiswa = _dashboardData['mahasiswa'] ?? {};
    final selectedData = _dashboardData['selectedData'];
    final todaysMatkuls = _dashboardData['todaysMatkuls'] as List? ?? [];

    return ListView(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selamat Datang,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      Text('${mahasiswa['nama'] ?? 'Mahasiswa'}', 
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${mahasiswa['nim'] ?? '-'} • ${mahasiswa['jurusan'] ?? '-'}', 
                          style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Statistik Presensi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        if (selectedData != null) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.class_, color: Color(0xFF6C5CE7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${selectedData['matkul']['nama']}', 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _statGridItem('Hadir', selectedData['hadir'], Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _statGridItem('Izin', selectedData['izin'], Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _statGridItem('Sakit', selectedData['sakit'], Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _statGridItem('Alfa', selectedData['alpha'], Colors.redAccent)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tingkat Kehadiran', style: TextStyle(color: Colors.grey)),
                      Text('${selectedData['percentage']}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (selectedData['percentage'] ?? 0) / 100,
                      minHeight: 12,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            ),
          )
        ] else ...[
          const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(24.0), 
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.insert_chart_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Belum ada data presensi kelas.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        ],

        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 12),
          child: Text('Jadwal Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    Text('Tidak ada jadwal kuliah hari ini.', style: TextStyle(color: Colors.grey)),
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
                  border: Border(left: BorderSide(color: Color(0xFF6C5CE7), width: 6)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.book, color: Color(0xFF6C5CE7)),
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
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _statGridItem(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
