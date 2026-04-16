import 'package:flutter/material.dart';
import '../api_service.dart';

class DosenIzinView extends StatefulWidget {
  const DosenIzinView({super.key});

  @override
  State<DosenIzinView> createState() => _DosenIzinViewState();
}

class _DosenIzinViewState extends State<DosenIzinView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _izins = [];

  @override
  void initState() {
    super.initState();
    _loadIzin();
  }

  Future<void> _loadIzin() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getDosenIzin();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _izins = result['data']['izins'] ?? [];
        } else {
          _error = result['message'];
        }
      });
    }
  }

  Future<void> _handleIzin(int id, bool approve) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final result = await _apiService.setIzinStatus(id, approve);
    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss loading
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? (result['success'] ? 'Berhasil' : 'Gagal'))),
    );
    if (result['success']) {
      _loadIzin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text('Error: $_error'));
    
    if (_izins.isEmpty) {
      return const Center(child: Text('Tidak ada pengajuan izin saat ini.'));
    }

    return ListView.builder(
      itemCount: _izins.length,
      itemBuilder: (context, index) {
        final izin = _izins[index];
        final mahasiswa = izin['mahasiswa'] ?? {};
        final user = mahasiswa['user'] ?? {};
        final matkul = izin['matkul'] ?? {};
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(user['name'] ?? 'Mahasiswa'),
            subtitle: Text('${matkul['nama']} | Tanggal: ${izin['tanggal']} | Status: ${izin['status']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alasan: ${izin['alasan'] ?? '-'}'),
                    // Bukti file bisa ditambahkan tombol download jika perlu
                    const SizedBox(height: 16),
                    if (izin['status'] == 'pending')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _handleIzin(izin['id'], false),
                            child: const Text('Tolak', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _handleIzin(izin['id'], true),
                            child: const Text('Setujui'),
                          ),
                        ],
                      )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
