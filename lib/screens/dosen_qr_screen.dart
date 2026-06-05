import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class DosenQrScreen extends StatefulWidget {
  const DosenQrScreen({super.key});

  @override
  State<DosenQrScreen> createState() => _DosenQrScreenState();
}

class _DosenQrScreenState extends State<DosenQrScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _matkuls = [];
  int? _selectedMatkulId;
  int _selectedDuration = 15;
  bool _isLoadingMatkuls = true;
  bool _isGenerating = false;

  // QR State
  String? _qrToken;
  DateTime? _expiresAt;
  bool _isExpired = false;
  Duration _remainingTime = Duration.zero;
  Timer? _countdownTimer;

  // QR is displayed as a stable static image so projected scanning stays reliable.

  final List<int> _durationOptions = [5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _loadMatkuls();
  }

  Future<void> _loadMatkuls() async {
    final result = await _apiService.getDosenDashboard();
    if (mounted) {
      setState(() {
        _isLoadingMatkuls = false;
        if (result['success'] == true) {
          _matkuls = result['data']['matkuls'] ?? [];
          if (_matkuls.isNotEmpty) {
            _selectedMatkulId = _matkuls.first['id'];
          }
        }
      });
    }
  }

  Future<void> _generateQr() async {
    if (_selectedMatkulId == null) return;
    setState(() => _isGenerating = true);

    // Stop previous timer
    _countdownTimer?.cancel();

    final result = await _apiService.generateQrCode(
      _selectedMatkulId!,
      _selectedDuration,
    );

    if (!mounted) return;
    setState(() => _isGenerating = false);

    if (result['success'] == true) {
      final expiresAtTimestamp = result['expiresAtTimestamp'] as int?;
      setState(() {
        _qrToken = result['token'] as String;
        _isExpired = false;
        if (expiresAtTimestamp != null) {
          _expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtTimestamp);
          _remainingTime = _expiresAt!.difference(DateTime.now());
        }
      });
      _startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal generate QR'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _expiresAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        timer.cancel();
        setState(() {
          _isExpired = true;
          _remainingTime = Duration.zero;
        });
      } else {
        setState(() => _remainingTime = remaining);
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _timerColor() {
    if (_isExpired) return AppColors.error;
    if (_remainingTime.inSeconds < 60) return AppColors.warning;
    return AppColors.success;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoadingMatkuls
          ? const Center(child: CircularProgressIndicator())
          : _matkuls.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate QR Presensi',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mahasiswa scan QR untuk absensi otomatis',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Settings Card
                  _buildSectionLabel('Pengaturan QR'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.dividerDark
                            : AppColors.dividerLight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Matkul Dropdown
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mata Kuliah',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.neutral,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedMatkulId,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.class_rounded,
                                    color: cs.primary,
                                  ),
                                ),
                                items: _matkuls
                                    .map<DropdownMenuItem<int>>(
                                      (m) => DropdownMenuItem<int>(
                                        value: m['id'] as int,
                                        child: Text(
                                          m['nama'] ?? '-',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedMatkulId = v),
                              ),
                            ],
                          ),
                        ),

                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),

                        // Duration Selector
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Durasi Token Aktif',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: AppColors.neutral,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: _durationOptions
                                    .map(
                                      (d) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: _buildDurationChip(d),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateQr,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(
                        _isGenerating
                            ? 'Generating...'
                            : (_qrToken != null && _isExpired)
                            ? 'Generate Ulang'
                            : 'Generate QR Code',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // ── QR Display
                  if (_qrToken != null) ...[
                    const SizedBox(height: 24),
                    _buildSectionLabel('QR Code Presensi'),
                    const SizedBox(height: 12),
                    _buildQrCard(isDark),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDurationChip(int minutes) {
    final isSelected = _selectedDuration == minutes;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.neutral,
              ),
            ),
            Text(
              'menit',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white70 : AppColors.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpired
              ? AppColors.error.withValues(alpha: 0.5)
              : isDark
              ? AppColors.dividerDark
              : AppColors.dividerLight,
          width: _isExpired ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Timer Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isExpired ? Icons.timer_off_rounded : Icons.timer_rounded,
                color: _timerColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isExpired ? 'QR Expired' : _formatDuration(_remainingTime),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _timerColor(),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              if (!_isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _timerColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AKTIF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _timerColor(),
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // QR Code
          Stack(
              alignment: Alignment.center,
              children: [
                // QR Image
                ImageFiltered(
                  imageFilter: _isExpired
                      ? ColorFilter.mode(
                          Colors.grey.withValues(alpha: 0.8),
                          BlendMode.saturation,
                        )
                      : const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.multiply,
                        ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _qrToken!,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.onSurfaceLight,
                      ),
                    ),
                  ),
                ),

                // Expired Overlay
                if (_isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EXPIRED',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 20),

          // Info
          if (!_isExpired) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Minta mahasiswa scan QR ini untuk mencatat kehadiran secara otomatis.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'QR Code sudah tidak aktif. Generate ulang untuk sesi baru.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.neutral,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.class_outlined,
                size: 48,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum Ada Mata Kuliah',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum memiliki mata kuliah yang terdaftar. Hubungi admin untuk menambahkan mata kuliah.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral),
            ),
          ],
        ),
      ),
    );
  }
}
