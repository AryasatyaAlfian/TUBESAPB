import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class DosenEnrollmentView extends StatefulWidget {
  final VoidCallback? onValidationUpdated;
  const DosenEnrollmentView({super.key, this.onValidationUpdated});
  @override
  State<DosenEnrollmentView> createState() => _DosenEnrollmentViewState();
}

class _DosenEnrollmentViewState extends State<DosenEnrollmentView> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _requests = [];
  
  // Multi-select state
  bool _selectionMode = false;
  Set<int> _selectedIds = {};
  bool _batchProcessing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getDosenEnrollmentRequests();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _selectionMode = false;
      _selectedIds.clear();
      if (res['success'] == true) {
        _requests = res['data']['enrollmentRequests'] ?? [];
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal';
      }
    });
    widget.onValidationUpdated?.call();
  }

  Future<void> _update(int id, bool approve) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Terima Mahasiswa?' : 'Tolak Mahasiswa?'),
        content: Text(
          approve
              ? 'Mahasiswa akan diterima di mata kuliah ini.'
              : 'Pengajuan mahasiswa akan ditolak.',
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
    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final res = await _api.setEnrollmentStatus(id, approve);
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
              ? 'Terima $count permintaan mahasiswa?'
              : 'Tolak $count permintaan mahasiswa?',
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
      final res = await _api.setEnrollmentStatus(id, approve);
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

  bool get _allSelected =>
      _requests.isNotEmpty && _selectedIds.length == _requests.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedIds = _requests
            .where((r) => r['id'] is int)
            .map((r) => r['id'] as int)
            .toSet();
      }
    });
  }

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

    if (_requests.isEmpty) {
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
                Icons.how_to_reg_rounded,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Permintaan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Semua permintaan validasi mahasiswa sudah diproses.',
              textAlign: TextAlign.center,
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
            padding: const EdgeInsets.all(20),
            itemCount: _requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final req = _requests[i];
              final id = req['id'] as int;
              final isSelected = _selectedIds.contains(id);
              return GestureDetector(
                onLongPress: () {
                  setState(() => _selectionMode = true);
                  _toggleSelection(id);
                },
                child: _buildEnrollmentItem(req, isSelected),
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
              IconButton(
                onPressed: _toggleSelectAll,
                icon: Icon(
                  _allSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: AppColors.primary,
                ),
                tooltip: _allSelected ? 'Batal pilih semua' : 'Pilih semua',
              ),
              const SizedBox(width: 4),
              Text(
                '${_selectedIds.length}/${_requests.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.neutral : AppColors.neutral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleBatch(false),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Tolak Semua'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildEnrollmentItem(dynamic req, bool isSelected) {
    final user = req['mahasiswa']?['user'] ?? {};
    final name = user['name'] ?? 'Mahasiswa';
    final nim = req['mahasiswa']?['nim'] ?? '-';
    final matkul = req['matkul']?['nama'] ?? 'Mata Kuliah';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_selectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(req['id'] as int),
                  )
                else
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIM: $nim',
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
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.library_books_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      matkul,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!_selectionMode)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _update(req['id'], false),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _update(req['id'], true),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Terima'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}
