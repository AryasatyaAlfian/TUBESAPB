import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  final String role;
  const ScheduleScreen({super.key, required this.role});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _matkuls = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = widget.role == 'dosen'
        ? await _api.getDosenSchedule()
        : await _api.getMahasiswaDashboard();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        final data = res['data'] as Map;
        _matkuls = data['matkuls'] ?? [];
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal mengambil jadwal';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kuliah')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return _errorView();
    if (_matkuls.isEmpty) return _empty('Belum ada jadwal');

    final grouped = <String, List<dynamic>>{};
    for (final m in _matkuls) {
      final day = (m['hari'] ?? 'Tanpa Hari').toString();
      grouped.putIfAbsent(day, () => []).add(m);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: grouped.entries
            .expand(
              (entry) => [
                _section(entry.key),
                const SizedBox(height: 10),
                ...entry.value.map(_scheduleTile),
                const SizedBox(height: 14),
              ],
            )
            .toList(),
      ),
    );
  }

  Widget _scheduleTile(dynamic m) {
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.class_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['nama'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _chip(m['kode'] ?? '-'),
                    _chip(m['jam'] ?? '-'),
                    _chip(m['ruangan'] ?? 'Tanpa ruang'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12, color: AppColors.neutral),
  );

  Widget _section(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: AppColors.neutral,
    ),
  );

  Widget _empty(String text) => Center(
    child: Text(text, style: const TextStyle(color: AppColors.neutral)),
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
