import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_refresh.dart';

class DosenPresenceScreen extends StatefulWidget {
  const DosenPresenceScreen({super.key});

  @override
  State<DosenPresenceScreen> createState() => _DosenPresenceScreenState();
}

class _DosenPresenceScreenState extends State<DosenPresenceScreen>
    with AutoRefreshMixin {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  List<dynamic> _matkuls = [];
  List<dynamic> _mahasiswas = [];
  int? _selectedMatkul;
  String _tanggal = DateTime.now().toIso8601String().substring(0, 10);
  final Map<int, String> _statuses = {};
  final Map<int, String> _initialStatuses = {};
  final Set<int> _lockedIds = {};
  String _searchQuery = '';
  String _filterStatus = 'all';

  static const _statusOptions = ['hadir', 'izin', 'sakit', 'alpha'];

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
    // Jangan timpa perubahan status yang belum disimpan oleh dosen.
    if (_saving || _hasChanges) return;
    await _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final res = await _api.getDosenPresences(
      matkulId: _selectedMatkul,
      tanggal: _tanggal,
    );
    if (!mounted) return;

    if (res['success'] != true) {
      if (silent) return; // diam-diam: abaikan error sementara
      setState(() {
        _loading = false;
        _error = res['message'] ?? 'Gagal mengambil presensi';
      });
      return;
    }

    // Olah data DI LUAR setState + bungkus try/catch. Tujuannya: kalau ada
    // error saat parsing (mis. 'presenceMap' bisa berupa array kosong [] ketika
    // belum ada presensi di tanggal itu, bukan objek {}), layar menampilkan
    // state error — BUKAN spinner abadi akibat setState gagal di tengah jalan.
    try {
      final data = res['data'] as Map;
      final matkuls = (data['matkuls'] as List?) ?? [];
      final mahasiswas = (data['mahasiswas'] as List?) ?? [];

      // presenceMap: objek {} bila ada data, atau array kosong [] bila belum ada.
      final pmRaw = data['presenceMap'];
      final presenceMap = pmRaw is Map
          ? Map<String, dynamic>.from(pmRaw)
          : <String, dynamic>{};

      // selectedMatkulId bisa int (saat default dari server) ATAU string "5"
      // (saat dikirim balik dari query param matkul_id). Tangani keduanya
      // supaya ganti matkul/tanggal tidak melempar error cast.
      final selRaw = data['selectedMatkulId'];
      final selectedMatkul =
          (selRaw is int
              ? selRaw
              : (selRaw is String ? int.tryParse(selRaw) : null)) ??
          (matkuls.isNotEmpty ? (matkuls.first['id'] as num).toInt() : null);

      final statuses = <int, String>{};
      final lockedIds = <int>{};
      for (final m in mahasiswas) {
        final id = m['id'] as int;
        final existing = presenceMap[id.toString()];
        final status = existing is Map ? existing['status'] as String? : null;
        statuses[id] = status ?? 'alpha';
        if (existing is Map &&
            (existing['locked'] == true ||
                existing['readonly'] == true ||
                existing['finalized'] == true)) {
          lockedIds.add(id);
        }
      }

      setState(() {
        _loading = false;
        _matkuls = matkuls;
        _mahasiswas = mahasiswas;
        _selectedMatkul = selectedMatkul;
        _statuses
          ..clear()
          ..addAll(statuses);
        _lockedIds
          ..clear()
          ..addAll(lockedIds);
        _initialStatuses
          ..clear()
          ..addAll(statuses);
        _error = '';
      });
    } catch (e) {
      if (silent) return; // diam-diam: jangan tampilkan error saat refresh otomatis
      setState(() {
        _loading = false;
        _error = 'Gagal memproses data presensi. Coba lagi.';
      });
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_tanggal) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 180)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _tanggal = picked.toIso8601String().substring(0, 10));
      await _load();
    }
  }

  bool get _hasChanges {
    if (_statuses.length != _initialStatuses.length) return true;
    for (final entry in _statuses.entries) {
      if (_initialStatuses[entry.key] != entry.value) return true;
    }
    return false;
  }

  void _setAllStatus(String status) {
    setState(() {
      for (final mahasiswa in _mahasiswas) {
        final id = mahasiswa['id'] as int;
        if (_lockedIds.contains(id)) continue;
        _statuses[id] = status;
      }
    });
  }

  void _undoChanges() {
    setState(() {
      _statuses
        ..clear()
        ..addAll(_initialStatuses);
      _searchQuery = '';
      _filterStatus = 'all';
    });
  }

  Widget _buildPresenceToolbar(bool isDark) {
    final changedCount = _statuses.entries
        .where((entry) => _initialStatuses[entry.key] != entry.value)
        .length;
    final lockedCount = _lockedIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Cari nama atau NIM',
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _filterStatus,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.filter_alt_rounded),
                  labelText: 'Filter status',
                ),
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('Semua')),
                  ..._statusOptions.map(
                    (s) => DropdownMenuItem(value: s, child: Text(_label(s))),
                  ),
                ],
                onChanged: (value) => setState(() => _filterStatus = value ?? 'all'),
              ),
            ),
            if (lockedCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      '$lockedCount terkunci',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => _setAllStatus('alpha'),
                child: const Text('Set semua Alpha'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => _setAllStatus('hadir'),
                child: const Text('Set semua Hadir'),
              ),
            ),
          ],
        ),
        if (_hasChanges) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perubahan belum disimpan ($changedCount)',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _undoChanges,
                child: const Text('Undo'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _save() async {
    if (_selectedMatkul == null) return;
    setState(() => _saving = true);
    final rows = _statuses.entries
        .map((e) => {'mahasiswa_id': e.key, 'status': e.value})
        .toList();
    final res = await _api.saveDosenPresences(
      matkulId: _selectedMatkul!,
      tanggal: _tanggal,
      presences: rows,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ?? (res['success'] == true ? 'Tersimpan' : 'Gagal'),
        ),
        backgroundColor: res['success'] == true
            ? AppColors.success
            : AppColors.error,
      ),
    );
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presensi Manual')),
      floatingActionButton: _mahasiswas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Menyimpan' : 'Simpan'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return _errorView();
    if (_matkuls.isEmpty) return _empty('Belum ada mata kuliah');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredMahasiswas = _mahasiswas.where((mahasiswa) {
      final id = mahasiswa['id'] as int;
      final user = mahasiswa['user'] ?? {};
      final name = user['name']?.toString().toLowerCase() ?? '';
      final nim = mahasiswa['nim']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          query.isEmpty || name.contains(query) || nim.contains(query);
      final status = _statuses[id]?.toLowerCase() ?? '';
      final matchesFilter =
          _filterStatus == 'all' || status == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedMatkul,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.class_rounded),
              labelText: 'Mata Kuliah',
            ),
            items: _matkuls
                .map<DropdownMenuItem<int>>(
                  (m) => DropdownMenuItem<int>(
                    value: m['id'] as int,
                    child: Text(m['nama'] ?? '-'),
                  ),
                )
                .toList(),
            onChanged: (v) async {
              setState(() => _selectedMatkul = v);
              await _load();
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.neutral,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _tanggal,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPresenceToolbar(isDark),
          const SizedBox(height: 20),
          if (filteredMahasiswas.isEmpty)
            _empty('Tidak ada mahasiswa yang cocok dengan filter')
          else
            ...filteredMahasiswas.map(_studentTile),
        ],
      ),
    );
  }

  Widget _studentTile(dynamic mahasiswa) {
    final id = mahasiswa['id'] as int;
    final user = mahasiswa['user'] ?? {};
    final name = user['name'] ?? mahasiswa['nim'] ?? 'Mahasiswa';
    final status = _statuses[id] ?? 'alpha';
    final locked = _lockedIds.contains(id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.toString().isNotEmpty
                  ? name.toString()[0].toUpperCase()
                  : 'M',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'NIM: ${mahasiswa['nim'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: status,
            underline: const SizedBox.shrink(),
            items: _statusOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(_label(s))))
                .toList(),
            onChanged: locked
                ? null
                : (v) => setState(() => _statuses[id] = v ?? 'alpha'),
          ),
        ],
      ),
    );
  }

  String _label(String status) => switch (status) {
    'hadir' => 'Hadir',
    'izin' => 'Izin',
    'sakit' => 'Sakit',
    _ => 'Alpha',
  };

  Widget _empty(String text) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.infoLight,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: Text(text, style: const TextStyle(color: AppColors.info)),
    ),
  );

  Widget _errorView() => Center(
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
