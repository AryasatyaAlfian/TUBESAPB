import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class DosenDashboardView extends StatefulWidget {
  const DosenDashboardView({super.key});
  @override
  State<DosenDashboardView> createState() => _DosenDashboardViewState();
}

class _DosenDashboardViewState extends State<DosenDashboardView> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _data = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getDosenDashboard();
    if (mounted) setState(() {
      _loading = false;
      if (res['success'] == true) _data = res['data'];
      else _error = res['message'] ?? 'Gagal';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _shimmer();
    if (_error.isNotEmpty) return _errorView();
    final total = _data['totalMahasiswa'] ?? 0;
    final matkuls = _data['matkuls'] as List? ?? [];
    final today = _data['todaysMatkuls'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards row
          Row(children: [
            Expanded(child: _summaryCard('Total Mahasiswa', '$total', Icons.people_rounded, AppColors.primary, const Color(0xFFD6E8FF))),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard('Total Kelas', '${matkuls.length}', Icons.class_rounded, AppColors.tertiary, const Color(0xFFFFDDB8))),
          ]),
          const SizedBox(height: 24),
          _sectionLabel('JADWAL HARI INI'),
          const SizedBox(height: 10),
          if (today.isEmpty) _emptySchedule() else ...today.map(_scheduleCard),
          const SizedBox(height: 24),
          _sectionLabel('SEMUA MATA KULIAH'),
          const SizedBox(height: 10),
          if (matkuls.isEmpty)
            _emptyCard('Belum ada mata kuliah terdaftar')
          else
            ...matkuls.map((m) => _matkulCard(m)),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color, Color bg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _scheduleCard(dynamic m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Row(children: [
        Container(width: 4, height: 52, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 14),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.class_rounded, color: AppColors.primary, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.room_rounded, size: 13, color: AppColors.neutral),
            const SizedBox(width: 3),
            Text(m['ruangan'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.neutral)),
            const SizedBox(width: 10),
            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.neutral),
            const SizedBox(width: 3),
            Text(m['jam_mulai'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.neutral)),
          ]),
        ])),
      ]),
    );
  }

  Widget _matkulCard(dynamic m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            _chip('${m['sks'] ?? '-'} SKS', AppColors.primary, const Color(0xFFD6E8FF)),
            const SizedBox(width: 6),
            _chip(m['hari'] ?? '-', AppColors.secondary, const Color(0xFFDCEAFF)),
          ]),
        ])),
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.class_rounded, color: AppColors.primary, size: 20)),
      ]),
    );
  }

  Widget _chip(String text, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _emptyCard(String msg) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(16)),
    child: Center(child: Text(msg, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w500))),
  );

  Widget _emptySchedule() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(16)),
    child: const Center(child: Column(children: [
      Icon(Icons.event_busy_rounded, size: 48, color: AppColors.warning),
      SizedBox(height: 12),
      Text('Tidak ada jadwal mengajar hari ini', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500)),
    ])),
  );

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
    const SizedBox(height: 16),
    Text(_error, style: const TextStyle(color: AppColors.error)),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba Lagi')),
  ]));

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: const Color(0xFFE2E8F0), highlightColor: const Color(0xFFF8FAFC),
    child: ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)))),
      ]),
      const SizedBox(height: 20),
      Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
      const SizedBox(height: 10),
      Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))),
    ]),
  );

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.neutral));
}
