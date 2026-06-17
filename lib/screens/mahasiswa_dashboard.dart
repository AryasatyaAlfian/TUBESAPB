import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'analytics_screen.dart';
import 'reports_screen.dart';
import 'schedule_screen.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _heroCard(mhs, sel),
          const SizedBox(height: 16),
          _quickActions(),
          const SizedBox(height: 20),
          const SectionHeader('STATISTIK KEHADIRAN'),
          const SizedBox(height: 12),
          if (sel != null) _statsCard(sel) else _emptyStats(),
          const SizedBox(height: 22),
          SectionHeader('JADWAL HARI INI', trailing: _todayBadge(today.length)),
          const SizedBox(height: 12),
          if (today.isEmpty) _emptySchedule() else ...today.map(_scheduleCard),
        ],
      ),
    );
  }

  // Most-used secondary tasks, previously hidden in the overflow (⋮) menu.
  Widget _quickActions() {
    return Row(
      children: [
        QuickActionButton(
          icon: Icons.calendar_month_rounded,
          label: 'Jadwal',
          color: AppColors.secondary,
          onTap: () => _push(const ScheduleScreen(role: 'mahasiswa')),
        ),
        const SizedBox(width: 10),
        QuickActionButton(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          color: AppColors.success,
          onTap: () => _push(const AnalyticsScreen(role: 'mahasiswa')),
        ),
        const SizedBox(width: 10),
        QuickActionButton(
          icon: Icons.summarize_rounded,
          label: 'Laporan',
          color: AppColors.tertiaryLight,
          onTap: () => _push(const ReportsScreen(role: 'mahasiswa')),
        ),
      ],
    );
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Widget _todayBadge(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count kelas',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.secondary,
      ),
    ),
  );

  Widget _heroCard(Map mhs, Map? sel) {
    final name = (mhs['user']?['name'] ?? mhs['nama'] ?? 'Mahasiswa')
        .toString();
    final firstName = name.split(' ').first;
    final pct = (sel?['percentage'] ?? 0) as num;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative soft circle for depth.
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              greetingIcon(),
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              greeting(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          firstName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${mhs['nim'] ?? '-'} • ${mhs['jurusan'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (sel != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.trending_up_rounded,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
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
          const SizedBox(height: 18),
          // Ring + breakdown side by side — headline metric is glanceable.
          Row(
            children: [
              AttendanceRing(
                percentage: pct.toDouble(),
                caption: 'Hadir',
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _statTile('Hadir', sel['hadir'] ?? 0,
                            AppColors.success),
                        const SizedBox(width: 8),
                        _statTile('Izin', sel['izin'] ?? 0, AppColors.info),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statTile('Sakit', sel['sakit'] ?? 0,
                            AppColors.warning),
                        const SizedBox(width: 8),
                        _statTile('Alfa', sel['alpha'] ?? 0, AppColors.error),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, int val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$val',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.neutral,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _scheduleCard(dynamic m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PressableCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
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
      ),
    );
  }

  Widget _emptyStats() => _emptyState(
    Icons.insert_chart_outlined_rounded,
    AppColors.info,
    'Belum ada data presensi',
    'Statistik kehadiran muncul setelah kamu mulai absen.',
  );

  Widget _emptySchedule() => _emptyState(
    Icons.event_available_rounded,
    AppColors.secondary,
    'Tidak ada jadwal hari ini',
    'Nikmati harimu — tidak ada kelas terjadwal.',
  );

  /// Theme-aware empty state that reads well in both light and dark mode.
  Widget _emptyState(IconData icon, Color color, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral),
          ),
        ],
      ),
    );
  }

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

  Widget _shimmer() => AdaptiveShimmer(
    child: ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 124, radius: 22),
        SizedBox(height: 22),
        SkeletonBox(height: 180, radius: 18),
        SizedBox(height: 22),
        SkeletonBox(height: 78, radius: 14),
        SizedBox(height: 10),
        SkeletonBox(height: 78, radius: 14),
      ],
    ),
  );
}
