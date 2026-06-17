import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  final String role;
  const AnalyticsScreen({super.key, required this.role});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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
    final res = await _api.getAnalytics();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _data = Map<String, dynamic>.from(res['data'] as Map);
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal mengambil analytics';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Presensi')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return _errorView();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: widget.role == 'dosen' ? _dosenCards() : _mahasiswaCards(),
      ),
    );
  }

  List<Widget> _dosenCards() {
    final stats = _data['attendanceStats'] as Map? ?? {};
    final topCourses = _data['topCourses'] as List? ?? [];
    final distribution = _data['performanceDistribution'] as Map? ?? {};
    return [
      Row(
        children: [
          Expanded(
            child: _metric(
              'Matkul',
              '${_data['totalMatkuls'] ?? 0}',
              Icons.class_rounded,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              'Mahasiswa',
              '${_data['totalEnrollments'] ?? 0}',
              Icons.people_rounded,
              AppColors.secondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _metric(
        'Kehadiran Rata-rata',
        '${(stats['attendance_rate'] ?? 0)}%',
        Icons.trending_up_rounded,
        AppColors.success,
      ),
      const SizedBox(height: 20),
      _section('Top Mata Kuliah'),
      const SizedBox(height: 10),
      if (topCourses.isEmpty)
        _empty('Belum ada data performa mata kuliah')
      else
        ...topCourses.map(
          (c) => _courseTile(
            c['name'] ?? '-',
            '${c['attendance_rate'] ?? 0}%',
            '${c['total_students'] ?? 0} mahasiswa',
          ),
        ),
      const SizedBox(height: 20),
      _section('Distribusi Performa'),
      const SizedBox(height: 10),
      _keyValue('Excellent', distribution['excellent'] ?? 0),
      _keyValue('Good', distribution['good'] ?? 0),
      _keyValue('Average', distribution['average'] ?? 0),
      _keyValue('Poor', distribution['poor'] ?? 0),
    ];
  }

  List<Widget> _mahasiswaCards() {
    final stats = _data['personalStats'] as Map? ?? {};
    final courses = _data['coursePerformance'] as List? ?? [];
    return [
      _metric(
        'Tingkat Kehadiran',
        '${stats['attendance_rate'] ?? 0}%',
        Icons.fact_check_rounded,
        AppColors.primary,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _metric(
              'Hadir',
              '${stats['hadir'] ?? 0}',
              Icons.check_rounded,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              'Alpha',
              '${stats['alpha'] ?? 0}',
              Icons.close_rounded,
              AppColors.error,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _section('Per Mata Kuliah'),
      const SizedBox(height: 10),
      if (courses.isEmpty)
        _empty('Belum ada data presensi')
      else
        ...courses.map(
          (c) => _courseTile(
            c['course_name'] ?? '-',
            '${c['attendance_rate'] ?? 0}%',
            '${c['hadir'] ?? 0}/${c['total'] ?? 0} hadir',
          ),
        ),
    ];
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseTile(String title, String value, String subtitle) {
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
                const SizedBox(height: 3),
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
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyValue(String label, dynamic value) =>
      _courseTile(label, '$value', 'jumlah mahasiswa');

  Widget _section(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: AppColors.neutral,
    ),
  );

  Widget _empty(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppColors.info)),
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
}
