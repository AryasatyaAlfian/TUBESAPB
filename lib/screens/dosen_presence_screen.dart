import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class DosenPresenceScreen extends StatefulWidget {
  const DosenPresenceScreen({super.key});

  @override
  State<DosenPresenceScreen> createState() => _DosenPresenceScreenState();
}

class _DosenPresenceScreenState extends State<DosenPresenceScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  List<dynamic> _matkuls = [];
  List<dynamic> _mahasiswas = [];
  Map<String, dynamic> _presenceMap = {};
  int? _selectedMatkul;
  String _tanggal = DateTime.now().toIso8601String().substring(0, 10);
  final Map<int, String> _statuses = {};

  static const _statusOptions = ['hadir', 'izin', 'sakit', 'alpha'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getDosenPresences(
      matkulId: _selectedMatkul,
      tanggal: _tanggal,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        final data = res['data'] as Map;
        _matkuls = data['matkuls'] ?? [];
        _mahasiswas = data['mahasiswas'] ?? [];
        _selectedMatkul =
            data['selectedMatkulId'] as int? ??
            (_matkuls.isNotEmpty ? _matkuls.first['id'] as int : null);
        _presenceMap = Map<String, dynamic>.from(
          data['presenceMap'] as Map? ?? {},
        );
        _statuses.clear();
        for (final m in _mahasiswas) {
          final id = m['id'] as int;
          final existing = _presenceMap[id.toString()];
          _statuses[id] = existing?['status'] ?? 'alpha';
        }
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal mengambil presensi';
      }
    });
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
          if (_mahasiswas.isEmpty)
            _empty('Belum ada mahasiswa approved di matkul ini')
          else
            ..._mahasiswas.map(_studentTile),
        ],
      ),
    );
  }

  Widget _studentTile(dynamic mahasiswa) {
    final id = mahasiswa['id'] as int;
    final user = mahasiswa['user'] ?? {};
    final name = user['name'] ?? mahasiswa['nim'] ?? 'Mahasiswa';
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
                Text(
                  'NIM: ${mahasiswa['nim'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _statuses[id] ?? 'alpha',
            underline: const SizedBox.shrink(),
            items: _statusOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(_label(s))))
                .toList(),
            onChanged: (v) => setState(() => _statuses[id] = v ?? 'alpha'),
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
