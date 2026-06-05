import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import 'dosen_matkul_screen.dart';

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

  // Analytics data
  Map<String, dynamic> _analyticsData = {};
  Map<String, dynamic> _subjectAttendance = {};
  Map<String, dynamic> _atRiskStudents = {};
  Map<String, dynamic> _absentToday = {};

  // UI State
  String _chartPeriod = 'week'; // 'week' or 'month'
  bool _expandAbsentToday = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Load basic dashboard data
    final dashRes = await _api.getDosenDashboard();

    if (!mounted) return;

    // Load analytics in parallel
    final analyticsRes = await _api.getAttendanceAnalytics(period: _chartPeriod);
    final subjectRes = await _api.getAttendanceBySubject();
    final atRiskRes = await _api.getAtRiskStudents();
    final absentRes = await _api.getAbsentToday();

    setState(() {
      _loading = false;
      if (dashRes['success'] == true) {
        _data = dashRes['data'] ?? {};
        _error = '';
      } else {
        _error = dashRes['message'] ?? 'Gagal memuat dashboard';
      }

      // Store analytics data
      if (analyticsRes['success'] == true) {
        _analyticsData = analyticsRes['data'] ?? {};
      }
      if (subjectRes['success'] == true) {
        _subjectAttendance = subjectRes['data'] ?? {};
      }
      if (atRiskRes['success'] == true) {
        _atRiskStudents = atRiskRes['data'] ?? {};
      }
      if (absentRes['success'] == true) {
        _absentToday = absentRes['data'] ?? {};
      }
    });
  }

  Future<void> _changeChartPeriod(String period) async {
    setState(() => _chartPeriod = period);
    final res = await _api.getAttendanceAnalytics(period: period);
    if (!mounted) return;
    setState(() {
      if (res['success'] == true) {
        _analyticsData = res['data'] ?? {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _shimmer();
    if (_error.isNotEmpty) return _errorView();
    final total = _data['totalMahasiswa'] ?? 0;
    final matkuls = _data['matkuls'] is List ? _data['matkuls'] as List : [];
    final today = _data['todaysMatkuls'] is List ? _data['todaysMatkuls'] as List : [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Total Mahasiswa',
                  '$total',
                  Icons.people_rounded,
                  AppColors.primary,
                  const Color(0xFFD6E8FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  'Total Kelas',
                  '${matkuls.length}',
                  Icons.class_rounded,
                  AppColors.tertiary,
                  const Color(0xFFFFDDB8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Attendance Chart Section
          _sectionLabel('GRAFIK KEHADIRAN'),
          const SizedBox(height: 12),
          _buildAttendanceChart(),
          const SizedBox(height: 24),

          // Subject Attendance Percentage
          _sectionLabel('KEHADIRAN PER MATA KULIAH'),
          const SizedBox(height: 12),
          _buildSubjectAttendanceList(),
          const SizedBox(height: 24),

          // At-Risk Students
          _sectionLabel('MAHASISWA BERISIKO (< 75%)'),
          const SizedBox(height: 12),
          _buildAtRiskStudents(),
          const SizedBox(height: 24),

          // Absent Today
          _sectionLabel('ABSENT HARI INI'),
          const SizedBox(height: 12),
          _buildAbsentToday(),
          const SizedBox(height: 24),

          // Today's Schedule
          _sectionLabel('JADWAL HARI INI'),
          const SizedBox(height: 10),
          if (today.isEmpty) _emptySchedule() else ...today.map(_scheduleCard),
          const SizedBox(height: 24),

          // All Subjects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('SEMUA MATA KULIAH'),
              TextButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DosenMatkulScreen(),
                    ),
                  );
                  _load();
                },
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: const Text('Kelola'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (matkuls.isEmpty)
            _emptyCard('Belum ada mata kuliah terdaftar')
          else
            ...matkuls.map((m) => _matkulCard(m)),
        ],
      ),
    );
  }

  // ── Attendance Chart Widget ──────────────────────────

  Widget _buildAttendanceChart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartData = _analyticsData['data'] ?? {};

    // Convert data to list of FlSpot
    final spots = <FlSpot>[];
    if (chartData is Map) {
      chartData.forEach((key, value) {
        final index = spots.length.toDouble();
        final count = (value is num) ? value.toDouble() : 0.0;
        spots.add(FlSpot(index, count));
      });
    }

    if (spots.isEmpty) {
      return _emptyCard('Belum ada data kehadiran');
    }

    // Find max Y for scaling
    final maxValue = spots.isEmpty ? 10.0 : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue + 5).ceil().toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Period toggle buttons
          Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'week', label: Text('Minggu')),
                    ButtonSegment(value: 'month', label: Text('Bulan')),
                  ],
                  selected: {_chartPeriod},
                  onSelectionChanged: (v) {
                    if (v.isNotEmpty) _changeChartPeriod(v.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: (maxY / 4).ceilToDouble(),
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.dividerLight.withValues(alpha: 0.3),
                      strokeWidth: 0.5,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: AppColors.dividerLight.withValues(alpha: 0.3),
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final keys = chartData.keys.toList();
                        if (index >= 0 && index < keys.length) {
                          return Text(
                            keys[index].toString().substring(0, 5),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: AppColors.dividerLight)),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Subject Attendance List ──────────────────────────

  Widget _buildSubjectAttendanceList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = _subjectAttendance['data'] is List
        ? _subjectAttendance['data'] as List
        : [];

    if (subjects.isEmpty) {
      return _emptyCard('Belum ada data persentase kehadiran');
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: subjects.asMap().entries.map<Widget>((entry) {
          final idx = entry.key;
          final subject = entry.value;
          final percentage = (subject['attendance_percentage'] ?? 0.0) as num;
          final isLast = idx == subjects.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subject['matkul_nama'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: percentage >= 75
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: percentage >= 75 ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage.toDouble() / 100.0,
                        minHeight: 6,
                        backgroundColor: AppColors.dividerLight,
                        valueColor: AlwaysStoppedAnimation(
                          percentage >= 75 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${subject['total_students'] ?? 0} mahasiswa',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── At-Risk Students List ────────────────────────────

  Widget _buildAtRiskStudents() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atRisk = _atRiskStudents['data'] is List
        ? _atRiskStudents['data'] as List
        : [];

    if (atRisk.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success),
              const SizedBox(height: 12),
              Text(
                'Semua mahasiswa memiliki kehadiran ≥ 75%',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: atRisk.asMap().entries.map<Widget>((entry) {
          final idx = entry.key;
          final student = entry.value;
          final percentage = (student['attendance_percentage'] ?? 0.0) as num;
          final isLast = idx == atRisk.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student['nim'] ?? '-',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.neutral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Absent Today List ────────────────────────────────

  Widget _buildAbsentToday() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final absent = _absentToday['data'] is List
        ? _absentToday['data'] as List
        : [];

    if (absent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.event_available_rounded, size: 48, color: AppColors.success),
              const SizedBox(height: 12),
              const Text(
                'Semua mahasiswa hadir hari ini',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        children: [
          // Header dengan toggle
          InkWell(
            onTap: () => setState(() => _expandAbsentToday = !_expandAbsentToday),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_off_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Absent Hari Ini',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${absent.length} mahasiswa',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandAbsentToday ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.neutral,
                  ),
                ],
              ),
            ),
          ),
          // Content when expanded
          if (_expandAbsentToday)
            Column(
              children: absent.asMap().entries.map<Widget>((entry) {
                final idx = entry.key;
                final student = entry.value;
                final isLast = idx == absent.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${student['nim'] ?? '-'} • ${student['matkul_nama'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ABSENT',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                      ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.neutral,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
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
              Icons.class_rounded,
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

  Widget _matkulCard(dynamic m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
                    _chip(
                      '${m['credits'] ?? '-'} SKS',
                      AppColors.primary,
                      const Color(0xFFD6E8FF),
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      m['hari'] ?? '-',
                      AppColors.secondary,
                      const Color(0xFFDCEAFF),
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      m['jam'] ?? '-',
                      AppColors.tertiary,
                      const Color(0xFFFFDDB8),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.class_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _emptyCard(String msg) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.infoLight,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Center(
      child: Text(
        msg,
        style: const TextStyle(
          color: AppColors.info,
          fontWeight: FontWeight.w500,
        ),
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
            'Tidak ada jadwal mengajar hari ini',
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
        Row(
          children: [
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
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
