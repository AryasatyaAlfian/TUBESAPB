import 'package:flutter/material.dart';
import '../api_service.dart';

class DosenEnrollmentView extends StatefulWidget {
  const DosenEnrollmentView({super.key});

  @override
  State<DosenEnrollmentView> createState() => _DosenEnrollmentViewState();
}

class _DosenEnrollmentViewState extends State<DosenEnrollmentView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });
    final result = await _apiService.getDosenEnrollmentRequests();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _requests = result['data']['enrollmentRequests'] ?? [];
        } else {
          _error = result['message'] ?? 'Unknown error';
        }
      });
    }
  }

  Future<void> _updateStatus(int id, bool approve) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final result = await _apiService.setEnrollmentStatus(id, approve);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? 'Sukses' : 'Gagal')),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _loadRequests();
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
            ElevatedButton(onPressed: _loadRequests, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(child: Text('Tidak ada permintaan validasi mahasiswa.'));
    }

    return ListView.builder(
      itemCount: _requests.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final req = _requests[index];
        final mahasiswaUser = req['mahasiswa']?['user'] ?? {};
        final mahasiswaName = mahasiswaUser['name'] ?? 'Mahasiswa';
        final matkulName = req['matkul']?['nama'] ?? 'Mata Kuliah';
        final nim = req['mahasiswa']?['nim'] ?? '-';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mahasiswaName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('NIM: $nim'),
                Text('Mengajukan: $matkulName'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _updateStatus(req['id'], false),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Tolak', style: TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _updateStatus(req['id'], true),
                      icon: const Icon(Icons.check),
                      label: const Text('Terima'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
