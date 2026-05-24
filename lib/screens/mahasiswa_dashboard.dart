import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class MahasiswaDashboardView extends StatefulWidget {
  const MahasiswaDashboardView({super.key});
  @override
  State<MahasiswaDashboardView> createState() => _MahasiswaDashboardViewState();
}

class _MahasiswaDashboardViewState extends State<MahasiswaDashboardView> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getMahasiswaDashboard();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _data = res['data'];
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _shimmer();
    if (_error.isNotEmpty) return _errorView();
    final mhs = _data['mahasiswa'] ?? {};
    final sel = _data['selectedData'];
    final today = _data['todaysMatkuls'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _heroCard(mhs),
          const SizedBox(height: 20),
          _sectionLabel('STATISTIK KEHADIRAN'),
          const SizedBox(height: 10),
          if (sel != null) _statsCard(sel) else _emptyStats(),
          const SizedBox(height: 20),
          _sectionLabel('JADWAL HARI INI'),
          const SizedBox(height: 10),
          if (today.isEmpty) _emptySchedule() else ...today.map(_scheduleCard),
        ],
      ),
    );
  }

  Widget _heroCard(Map mhs) {
    final name = (mhs['user']?['name'] ?? mhs['nama'] ?? 'Mahasiswa')
        .toString();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'M',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${mhs['nim'] ?? '-'} • ${mhs['jurusan'] ?? '-'}',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsCard(Map sel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = (sel['percentage'] ?? 0) as num;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.class_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sel['matkul']['nama'] ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statTile(
                'Hadir',
                sel['hadir'] ?? 0,
                AppColors.success,
                AppColors.successLight,
              ),
              const SizedBox(width: 10),
              _statTile(
                'Izin',
                sel['izin'] ?? 0,
                AppColors.info,
                AppColors.infoLight,
              ),
              const SizedBox(width: 10),
              _statTile(
                'Sakit',
                sel['sakit'] ?? 0,
                AppColors.warning,
                AppColors.warningLight,
              ),
              const SizedBox(width: 10),
              _statTile(
                'Alfa',
                sel['alpha'] ?? 0,
                AppColors.error,
                AppColors.errorLight,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tingkat Kehadiran',
                style: TextStyle(color: AppColors.neutral, fontSize: 13),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 10,
              backgroundColor: AppColors.dividerLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 75
                    ? AppColors.success
                    : pct >= 50
                    ? AppColors.warning
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, int val, Color color, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$val',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _scheduleCard(dynamic m) {
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
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['nama'] ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      size: 13,
                      color: AppColors.neutral,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      m['kode'] ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.neutral,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      m['jam'] ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStats() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.infoLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
      child: Column(
        children: [
          Icon(
            Icons.insert_chart_outlined_rounded,
            size: 48,
            color: AppColors.info,
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada data presensi',
            style: TextStyle(
              color: AppColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptySchedule() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.warningLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: AppColors.warning),
          SizedBox(height: 12),
          Text(
            'Tidak ada jadwal hari ini',
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: const Color(0xFFE2E8F0),
    highlightColor: const Color(0xFFF8FAFC),
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.neutral,
    ),
  );
}
