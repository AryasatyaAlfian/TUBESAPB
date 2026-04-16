import 'package:flutter/material.dart';
import '../api_service.dart';

class MahasiswaIzinView extends StatefulWidget {
  const MahasiswaIzinView({super.key});

  @override
  State<MahasiswaIzinView> createState() => _MahasiswaIzinViewState();
}

class _MahasiswaIzinViewState extends State<MahasiswaIzinView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _matkuls = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _apiService.getMahasiswaIzin();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _matkuls = result['data']['matkuls'] ?? [];
        } else {
          _error = result['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text('Error: $_error'));
    
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Ajukan Izin'),
              Tab(text: 'Riwayat'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAjukanForm(),
                const Center(child: Text('Riwayat izin akan muncul di sini (Belum digabungkan di API)')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAjukanForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Pilih Mata Kuliah'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          items: _matkuls.map<DropdownMenuItem<int>>((m) {
            return DropdownMenuItem<int>(
              value: m['id'],
              child: Text(m['nama']),
            );
          }).toList(),
          onChanged: (val) {},
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(labelText: 'Tanggal (YYYY-MM-DD)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(labelText: 'Alasan', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // File picker skip for simple form
        FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mengirim izin... (Fitur M-part ini masih pakai form statis untuk upload file)')));
          },
          child: const Text('Kirim Pengajuan'),
        )
      ],
    );
  }
}
