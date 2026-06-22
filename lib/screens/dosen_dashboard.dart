import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/auto_refresh.dart';
import 'dosen_matkul_screen.dart';
import 'dosen_presence_screen.dart';
import 'reports_screen.dart';
import 'schedule_screen.dart';

class DosenDashboardView extends StatefulWidget {
  const DosenDashboardView({super.key});
  @override
  State<DosenDashboardView> createState() => _DosenDashboardViewState();
}

class _DosenDashboardViewState extends State<DosenDashboardView>
    with AutoRefreshMixin {
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
  String _dosenName = '';
  // Segmented tab: 0 = Hari Ini, 1 = Analitik, 2 = Mahasiswa.
  // Progressive disclosure — only one group of sections renders at a time,
  // so the dashboard stays one short scroll instead of seven stacked blocks.
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _loadName();
    _load();
    startAutoRefresh();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  // Dashboard menembak beberapa endpoint sekaligus, jadi refresh lebih jarang
  // untuk menekan beban jaringan.
  @override
  Duration get autoRefreshInterval => const Duration(seconds: 20);

  @override
  Future<void> onAutoRefresh() => _load(silent: true);

  Future<void> _loadName() async {
    final user = await _api.getSavedUser();
    if (mounted && user != null) {
      setState(() => _dosenName = (user['name'] ?? '').toString());
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);

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
      } else if (!silent) {
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _greetingHero(total, matkuls.length),
          const SizedBox(height: 16),
          _quickActions(),
          const SizedBox(height: 20),
          _tabSelector(),
          const SizedBox(height: 16),
          // Crossfade keeps spatial continuity when switching tab content.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Column(
              key: ValueKey(_activeTab),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _tabContent(today),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────────
  // Surfaces the most-used tasks that were previously buried in the
  // overflow (⋮) menu — one tap instead of two, and discoverable.

  Widget _quickActions() {
    return Row(
      children: [
        QuickActionButton(
          icon: Icons.fact_check_rounded,
          label: 'Presensi',
          color: AppColors.secondary,
          onTap: () => _pushAndReload(const DosenPresenceScreen()),
        ),
        const SizedBox(width: 10),
        QuickActionButton(
          icon: Icons.summarize_rounded,
          label: 'Laporan',
          color: AppColors.tertiaryLight,
          onTap: () => _pushAndReload(const ReportsScreen(role: 'dosen')),
        ),
        const SizedBox(width: 10),
        QuickActionButton(
          icon: Icons.calendar_month_rounded,
          label: 'Jadwal',
          color: AppColors.success,
          onTap: () => _pushAndReload(const ScheduleScreen(role: 'dosen')),
        ),
        const SizedBox(width: 10),
        QuickActionButton(
          icon: Icons.class_rounded,
          label: 'Matkul',
          color: AppColors.primaryLight,
          onTap: () => _pushAndReload(const DosenMatkulScreen()),
        ),
      ],
    );
  }

  Future<void> _pushAndReload(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  // ── Segmented Tab Selector ───────────────────────────

  Widget _tabSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final absentCount = _absentToday['data'] is List
        ? (_absentToday['data'] as List).length
        : 0;
    final atRiskCount = _atRiskStudents['data'] is List
        ? (_atRiskStudents['data'] as List).length
        : 0;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _tabBtn(0, 'Hari Ini', badge: absentCount),
          _tabBtn(1, 'Analitik'),
          _tabBtn(2, 'Mahasiswa', badge: atRiskCount, badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _tabBtn(int index, String label, {int badge = 0, Color? badgeColor}) {
    final selected = _activeTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: [
              if (selected && !isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? cs.primary : AppColors.neutral,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.warning)
                        .withValues(alpha: selected ? 1 : 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Content ──────────────────────────────────────

  List<Widget> _tabContent(List today) {
    switch (_activeTab) {
      case 1: // Analitik — how are my classes doing?
        return [
          const SectionHeader('GRAFIK KEHADIRAN'),
          const SizedBox(height: 12),
          _buildAttendanceChart(),
          const SizedBox(height: 24),
          const SectionHeader('KEHADIRAN PER MATA KULIAH'),
          const SizedBox(height: 12),
          _buildSubjectAttendanceList(),
        ];
      case 2: // Mahasiswa — who needs attention?
        return [
          const SectionHeader('MAHASISWA BERISIKO (< 75%)'),
          const SizedBox(height: 12),
          _buildAtRiskStudents(),
        ];
      default: // Hari Ini — what's happening today?
        return [
          SectionHeader(
            'JADWAL HARI INI',
            trailing: today.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${today.length} kelas',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          if (today.isEmpty) _emptySchedule() else ...today.map(_scheduleCard),
          const SizedBox(height: 24),
          const SectionHeader('ABSEN HARI INI'),
          const SizedBox(height: 12),
          _buildAbsentToday(),
        ];
    }
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

    final cs = Theme.of(context).colorScheme;
    final lineColor = cs.primary;
    final axisColor = AppColors.neutral;
    final gridColor = (isDark ? AppColors.dividerDark : AppColors.dividerLight)
        .withValues(alpha: 0.5);

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
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 4).ceilToDouble(),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: gridColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final keys = chartData.keys.toList();
                        if (index >= 0 && index < keys.length) {
                          final k = keys[index].toString();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              k.length > 5 ? k.substring(0, 5) : k,
                              style: TextStyle(fontSize: 10, color: axisColor),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (maxY / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: axisColor),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '${s.y.toInt()} hadir',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: isDark
                              ? AppColors.surfaceDark
                              : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.25),
                          lineColor.withValues(alpha: 0.02),
                        ],
                      ),
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
                          'Absen Hari Ini',
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
                              'ABSEN',
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

  Widget _greetingHero(int total, int classes) {
    final firstName = _dosenName.isEmpty
        ? 'Dosen'
        : _dosenName.split(' ').first;
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
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
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
                  Icon(
                    greetingIcon(),
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  _heroStat(
                    Icons.people_rounded,
                    '$total',
                    'Mahasiswa',
                  ),
                  const SizedBox(width: 12),
                  _heroStat(
                    Icons.class_rounded,
                    '$classes',
                    'Kelas',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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

  Widget _emptyCard(String msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.info,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _emptySchedule() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppColors.secondary,
            ),
            SizedBox(height: 12),
            Text(
              'Tidak ada jadwal mengajar hari ini',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
        SkeletonBox(height: 150, radius: 22),
        SizedBox(height: 22),
        SkeletonBox(height: 300, radius: 16),
        SizedBox(height: 24),
        SkeletonBox(height: 150, radius: 16),
      ],
    ),
  );
}
