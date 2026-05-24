import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class DosenIzinView extends StatefulWidget {
  const DosenIzinView({super.key});
  @override
  State<DosenIzinView> createState() => _DosenIzinViewState();
}

class _DosenIzinViewState extends State<DosenIzinView> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _izins = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getDosenIzin();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _izins = res['data']['izins'] ?? [];
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal';
      }
    });
  }

  Future<void> _handle(int id, bool approve) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final res = await _api.setIzinStatus(id, approve);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ?? (res['success'] == true ? 'Berhasil' : 'Gagal'),
        ),
        backgroundColor: res['success'] == true
            ? AppColors.success
            : AppColors.error,
      ),
    );
    if (res['success'] == true) _load();
  }

  void _showBukti(dynamic iz) {
    final url = iz['bukti_url']?.toString();
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti izin tidak tersedia.')),
      );
      return;
    }
    final isImage = RegExp(
      r'\.(jpg|jpeg|png)(\?|$)',
      caseSensitive: false,
    ).hasMatch(url);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bukti Izin'),
        content: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              )
            : SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'approved' => AppColors.success,
    'rejected' => AppColors.error,
    _ => AppColors.warning,
  };
  Color _statusBg(String status) => switch (status) {
    'approved' => AppColors.successLight,
    'rejected' => AppColors.errorLight,
    _ => AppColors.warningLight,
  };
  String _statusLabel(String status) => switch (status) {
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    _ => 'Menunggu',
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_izins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Pengajuan Izin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Semua pengajuan izin sudah diproses.',
              style: TextStyle(color: AppColors.neutral),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _izins.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final iz = _izins[i];
          final user = iz['mahasiswa']?['user'] ?? {};
          final matkul = iz['matkul'] ?? {};
          final status = iz['status'] ?? 'pending';
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          (user['name'] ?? 'M').toString().isNotEmpty
                              ? user['name'].toString()[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'Mahasiswa',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${matkul['nama'] ?? '-'} • ${iz['tanggal'] ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.neutral,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _statusBg(status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (iz['alasan'] != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      iz['alasan'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.neutral,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showBukti(iz),
                      icon: const Icon(Icons.attachment_rounded, size: 18),
                      label: const Text('Lihat Bukti'),
                    ),
                  ),
                ),
                if (status == 'pending')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _handle(iz['id'], false),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Tolak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _handle(iz['id'], true),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Setujui'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
