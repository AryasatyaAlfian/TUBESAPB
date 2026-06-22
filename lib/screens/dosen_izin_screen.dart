import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_refresh.dart';

class DosenIzinView extends StatefulWidget {
  const DosenIzinView({super.key});
  @override
  State<DosenIzinView> createState() => _DosenIzinViewState();
}

class _DosenIzinViewState extends State<DosenIzinView> with AutoRefreshMixin {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _izins = [];

  // Multi-select state
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  bool _batchProcessing = false;

  @override
  void initState() {
    super.initState();
    _load();
    startAutoRefresh();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  @override
  Future<void> onAutoRefresh() async {
    // Jangan ganggu saat dosen sedang memilih/memproses batch
    if (_selectionMode || _batchProcessing) return;
    await _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _api.getDosenIzin();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _selectionMode = false;
      _selectedIds.clear();
      if (res['success'] == true) {
        _izins = res['data']['izins'] ?? [];
        _error = '';
      } else if (!silent) {
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

  Future<void> _handleBatch(bool approve) async {
    if (_selectedIds.isEmpty) return;
    
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Terima Semua?' : 'Tolak Semua?'),
        content: Text(
          approve
              ? 'Terima $count pengajuan izin?'
              : 'Tolak $count pengajuan izin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.error,
            ),
            child: Text(approve ? 'Terima' : 'Tolak'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    
    setState(() => _batchProcessing = true);
    int successCount = 0;
    
    for (final id in _selectedIds) {
      final res = await _api.setIzinStatus(id, approve);
      if (res['success'] == true) successCount++;
    }
    
    if (!mounted) return;
    setState(() => _batchProcessing = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successCount dari $count berhasil diproses'),
        backgroundColor: successCount == count ? AppColors.success : AppColors.warning,
      ),
    );
    
    if (successCount > 0) _load();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
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
      r'\.(jpg|jpeg|png|webp|gif)(\?|$)',
      caseSensitive: false,
    ).hasMatch(url);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bukti Izin'),
        content: isImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.neutral,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gambar tidak dapat dimuat.\nCoba buka di peramban.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Berkas bukti (PDF/dokumen).\nKetuk "Buka" untuk melihatnya.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () => _openBuktiExternal(url),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: const Text('Buka'),
          ),
        ],
      ),
    );
  }

  /// Membuka URL bukti di peramban/viewer eksternal — bekerja untuk gambar
  /// maupun PDF/dokumen, dan menampilkan pesan bila gagal.
  Future<void> _openBuktiExternal(String url) async {
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka bukti.')),
      );
    }
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

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            // Extra bottom inset when the batch action bar is shown so the
            // last item is never hidden behind it.
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              _selectionMode && _selectedIds.isNotEmpty ? 96 : 20,
            ),
            itemCount: _izins.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final iz = _izins[i];
              final id = iz['id'] as int;
              final isSelected = _selectedIds.contains(id);
              return GestureDetector(
                onLongPress: () {
                  setState(() => _selectionMode = true);
                  _toggleSelection(id);
                },
                child: _buildIzinItem(iz, isSelected),
              );
            },
          ),
        ),
        if (_selectionMode && _selectedIds.isNotEmpty && !_batchProcessing)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBatchActionBar(),
          ),
        if (_batchProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBatchActionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleBatch(false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak Semua'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleBatch(true),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Terima Semua'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                }),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Batal',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIzinItem(dynamic iz, bool isSelected) {
    final user = iz['mahasiswa']?['user'] ?? {};
    final matkul = iz['matkul'] ?? {};
    final status = iz['status'] ?? 'pending';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_selectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(iz['id'] as int),
                  )
                else
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
          if (status == 'pending' && !_selectionMode)
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
  }
}
