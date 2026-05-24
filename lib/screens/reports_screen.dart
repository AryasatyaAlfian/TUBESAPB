import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  final String role;
  const ReportsScreen({super.key, required this.role});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _matkuls = [];
  int? _selectedMatkul;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = widget.role == 'dosen'
        ? await _api.getDosenReportOptions()
        : await _api.getStudentReport();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        final data = res['data'] as Map;
        _matkuls = data['matkuls'] ?? [];
        _selectedMatkul ??=
            data['selectedMatkulId'] as int? ??
            (_matkuls.isNotEmpty ? _matkuls.first['id'] as int : null);
        if (widget.role == 'mahasiswa') {
          _report = Map<String, dynamic>.from(data);
        }
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal mengambil laporan';
      }
    });
    if (widget.role == 'dosen' && _selectedMatkul != null) {
      await _generateDosenReport();
    }
  }

  Future<void> _loadStudentReport() async {
    if (_selectedMatkul == null) return;
    setState(() => _loading = true);
    final res = await _api.getStudentReport(matkulId: _selectedMatkul);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _report = Map<String, dynamic>.from(res['data'] as Map);
      } else {
        _error = res['message'] ?? 'Gagal mengambil laporan';
      }
    });
  }

  Future<void> _generateDosenReport() async {
    if (_selectedMatkul == null) return;
    setState(() => _loading = true);
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final res = await _api.generateDosenReport(
      matkulId: _selectedMatkul!,
      month: month,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _report = Map<String, dynamic>.from(res['data'] as Map);
      } else {
        _error = res['message'] ?? 'Gagal membuat laporan';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Presensi')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _report == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) return _errorView();
    if (_matkuls.isEmpty) return _empty('Belum ada mata kuliah');

    return RefreshIndicator(
      onRefresh: widget.role == 'dosen'
          ? _generateDosenReport
          : _loadStudentReport,
      child: ListView(
        padding: const EdgeInsets.all(20),
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
              if (widget.role == 'dosen') {
                await _generateDosenReport();
              } else {
                await _loadStudentReport();
              }
            },
          ),
          const SizedBox(height: 20),
          if (_loading) const LinearProgressIndicator(),
          if (_report != null) ..._reportWidgets(),
        ],
      ),
    );
  }

  List<Widget> _reportWidgets() {
    if (widget.role == 'dosen') {
      final summary = _report?['summary'] as Map? ?? {};
      final rows = _report?['attendanceData'] as List? ?? [];
      return [
        _summaryGrid(summary),
        const SizedBox(height: 20),
        _section('Mahasiswa'),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          _empty('Belum ada presensi bulan ini')
        else
          ...rows.map((r) {
            final m = r['mahasiswa'] ?? {};
            final user = m['user'] ?? {};
            final stats = r['stats'] ?? {};
            return _tile(
              user['name'] ?? m['nim'] ?? 'Mahasiswa',
              '${r['percentage'] ?? 0}%',
              'Hadir ${stats['hadir'] ?? 0}, Izin ${stats['izin'] ?? 0}, Sakit ${stats['sakit'] ?? 0}, Alpha ${stats['alpha'] ?? 0}',
            );
          }),
      ];
    }

    final stats = _report?['stats'] as Map? ?? {};
    final presences = _report?['presences'] as List? ?? [];
    return [
      _summaryGrid({
        'hadir': stats['hadir'] ?? 0,
        'izin': stats['izin'] ?? 0,
        'sakit': stats['sakit'] ?? 0,
        'alpha': stats['alpha'] ?? 0,
        'attendance_rate': _report?['percentage'] ?? 0,
      }),
      const SizedBox(height: 20),
      _section('Riwayat'),
      const SizedBox(height: 10),
      if (presences.isEmpty)
        _empty('Belum ada riwayat presensi')
      else
        ...presences.map(
          (p) => _tile(
            _formatDate(p['tanggal']),
            (p['status'] ?? '-').toString().toUpperCase(),
            p['note'] ?? '',
          ),
        ),
    ];
  }

  Widget _summaryGrid(Map summary) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _metric('Hadir', summary['hadir'] ?? 0, AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metric('Izin', summary['izin'] ?? 0, AppColors.info),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _metric('Sakit', summary['sakit'] ?? 0, AppColors.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metric('Alpha', summary['alpha'] ?? 0, AppColors.error),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _metric(
        'Kehadiran',
        '${summary['attendance_rate'] ?? 0}%',
        AppColors.primary,
      ),
    ],
  );

  Widget _metric(String label, dynamic value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral),
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String trailing, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final s = raw.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Widget _section(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: AppColors.neutral,
    ),
  );

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
