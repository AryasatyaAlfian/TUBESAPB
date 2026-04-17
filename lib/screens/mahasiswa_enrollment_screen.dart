import 'package:flutter/material.dart';
import '../api_service.dart';

class MahasiswaEnrollmentView extends StatefulWidget {
  const MahasiswaEnrollmentView({super.key});

  @override
  State<MahasiswaEnrollmentView> createState() => _MahasiswaEnrollmentViewState();
}

class _MahasiswaEnrollmentViewState extends State<MahasiswaEnrollmentView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _availableMatkuls = [];
  List<dynamic> _enrollments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _apiService.getMahasiswaEnrollments();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _availableMatkuls = result['data']['availableMatkuls'] ?? [];
          _enrollments = result['data']['enrollments'] ?? [];
        } else {
          _error = result['message'] ?? 'Unknown error';
        }
      });
    }
  }

  Future<void> _requestEnrollment(int matkulId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _apiService.requestEnrollment(matkulId);
    
    if (mounted) {
      Navigator.of(context).pop(); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? 'Berhasil' : 'Gagal')),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        _loadData();
      }
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
            ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Tersedia'),
              Tab(text: 'Pengajuan Saya'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableMatkuls(),
                _buildMyEnrollments(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableMatkuls() {
    if (_availableMatkuls.isEmpty) {
      return const Center(child: Text('Tidak ada mata kuliah tersedia.'));
    }

    return ListView.builder(
      itemCount: _availableMatkuls.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final matkul = _availableMatkuls[index];
        final isEnrolled = _enrollments.any((e) => e['matkul_id'] == matkul['id']);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(matkul['nama'] ?? '-'),
            subtitle: Text('Ruangan: ${matkul['ruangan'] ?? '-'} | SKS: ${matkul['sks'] ?? '-'} \nHari: ${matkul['hari'] ?? '-'} Jam: ${matkul['jam_mulai'] ?? '-'}'),
            isThreeLine: true,
            trailing: isEnrolled
                ? const Chip(label: Text('Sudah Diajukan'), backgroundColor: Colors.grey)
                : FilledButton(
                    onPressed: () => _requestEnrollment(matkul['id']),
                    child: const Text('Ambil'),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMyEnrollments() {
    if (_enrollments.isEmpty) {
      return const Center(child: Text('Belum ada pengajuan.'));
    }

    return ListView.builder(
      itemCount: _enrollments.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final enrollment = _enrollments[index];
        final matkul = enrollment['matkul'] ?? {};
        final status = enrollment['status'];

        Color statusColor = Colors.grey;
        if (status == 'approved') statusColor = Colors.green;
        if (status == 'rejected') statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(matkul['nama'] ?? '-'),
            subtitle: Text('Status: ${status.toString().toUpperCase()}'),
            trailing: Chip(
              label: Text(status.toString().toUpperCase(), style: const TextStyle(color: Colors.white)),
              backgroundColor: statusColor,
            ),
          ),
        );
      },
    );
  }
}
