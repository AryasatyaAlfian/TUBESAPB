import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../api_service.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'mahasiswa_dashboard.dart';
import 'dosen_dashboard.dart';
import 'mahasiswa_izin_screen.dart';
import 'dosen_izin_screen.dart';
import 'mahasiswa_enrollment_screen.dart';
import 'dosen_enrollment_screen.dart';
import 'dosen_qr_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'analytics_screen.dart';
import 'reports_screen.dart';
import 'dosen_presence_screen.dart';
import 'schedule_screen.dart';
import '../widgets/chat_assistant.dart';
import '../widgets/auto_refresh.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutoRefreshMixin {
  int _currentIndex = 0;
  bool get _isMahasiswa => widget.user['role'] == 'mahasiswa';

  // Notification badge state
  int _unreadCount = 0;
  bool _loadingNotifications = false;
  
  // Validation badge state (dosen only)
  int _pendingValidations = 0;
  bool _loadingValidations = false;
  
  late final _api = ApiService();

  List<Widget> get _pages => _isMahasiswa
      ? [
          const MahasiswaDashboardView(),
          const MahasiswaIzinView(),
          // Only mount the camera scanner while its tab is active so the
          // camera permission isn't requested at app startup.
          _currentIndex == 2 ? const _ScanQrView() : const SizedBox.shrink(),
          const MahasiswaEnrollmentView(),
          ProfileScreen(user: widget.user, onLogout: _logout),
        ]
      : [
          const DosenDashboardView(),
          const DosenIzinView(),
          const DosenQrScreen(),
          DosenEnrollmentView(onValidationUpdated: _loadValidationCount),
          ProfileScreen(user: widget.user, onLogout: _logout),
        ];

  List<String> get _titles => _isMahasiswa
      ? ['Dashboard', 'Pengajuan Izin', 'Scan QR', 'Ambil Matkul', 'Profil']
      : ['Dashboard', 'Validasi Izin', 'Generate QR', 'Validasi Mahasiswa', 'Profil'];

  void _logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    if (!_isMahasiswa) {
      _loadValidationCount();
    }
    startAutoRefresh();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }

  @override
  Future<void> onAutoRefresh() async {
    await _loadUnreadCount();
    if (!_isMahasiswa) await _loadValidationCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_loadingNotifications) return;
    setState(() => _loadingNotifications = true);
    try {
      final res = await _api.getNotifications();
      if (mounted && res['success'] == true) {
        final notifications = res['data']['notifications'] as List<dynamic>? ?? [];
        final unread = notifications.where((n) => n['read_at'] == null).length;
        setState(() => _unreadCount = unread);
      }
    } catch (e) {
      // Silently fail, badge won't update
    } finally {
      if (mounted) setState(() => _loadingNotifications = false);
    }
  }

  Future<void> _openNotifications() async {
    // Mark all as read
    await _api.markAllNotificationsRead();
    if (mounted) {
      setState(() => _unreadCount = 0);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ).then((_) {
        // Refresh on return
        _loadUnreadCount();
      });
    }
  }

  Future<void> _loadValidationCount() async {
    if (_loadingValidations) return;
    setState(() => _loadingValidations = true);
    try {
      int pendingCount = 0;
      
      // Get pending izin
      final izinRes = await _api.getDosenIzin();
      if (izinRes['success'] == true) {
        final izins = izinRes['data']['izins'] as List<dynamic>? ?? [];
        pendingCount += izins.where((i) => i['status'] == 'pending').length;
      }
      
      // Get pending enrollment requests
      final enrollRes = await _api.getDosenEnrollmentRequests();
      if (enrollRes['success'] == true) {
        final requests = enrollRes['data']['enrollmentRequests'] as List<dynamic>? ?? [];
        pendingCount += requests.where((r) => r['status'] == 'pending').length;
      }
      
      if (mounted) {
        setState(() => _pendingValidations = pendingCount);
      }
    } catch (e) {
      // Silently fail
    } finally {
      if (mounted) setState(() => _loadingValidations = false);
    }
  }

  Widget _buildTitle() {
    final title = _titles[_currentIndex];
    
    // Show validation badge for dosen on validasi izin & validasi screens
    final showValidationBadge = !_isMahasiswa && 
      (_currentIndex == 1 || _currentIndex == 3) && 
      _pendingValidations > 0;
    
    if (showValidationBadge) {
      return Stack(
        children: [
          Text(title),
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }
    
    return Text(title);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifikasi',
                icon: const Icon(Icons.notifications_rounded),
                onPressed: _openNotifications,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu lainnya',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: _openMenu,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'analytics',
                child: ListTile(
                  leading: Icon(Icons.analytics_rounded),
                  title: Text('Analytics'),
                ),
              ),
              const PopupMenuItem(
                value: 'reports',
                child: ListTile(
                  leading: Icon(Icons.summarize_rounded),
                  title: Text('Laporan'),
                ),
              ),
              const PopupMenuItem(
                value: 'schedule',
                child: ListTile(
                  leading: Icon(Icons.calendar_month_rounded),
                  title: Text('Jadwal'),
                ),
              ),
              if (!_isMahasiswa)
                const PopupMenuItem(
                  value: 'manual-presence',
                  child: ListTile(
                    leading: Icon(Icons.fact_check_rounded),
                    title: Text('Presensi Manual'),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                color: isDark ? AppColors.tertiaryLight : AppColors.neutral,
              ),
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          // Floating AI assistant — overlays every tab, for both roles.
          // The backend resolves the role from the auth token, so the answers
          // adapt automatically for any account (including newly registered).
          ChatAssistant(user: widget.user),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isDark, cs),
    );
  }

  void _openMenu(String value) {
    final role = _isMahasiswa ? 'mahasiswa' : 'dosen';
    final Widget screen = switch (value) {
      'analytics' => AnalyticsScreen(role: role),
      'reports' => ReportsScreen(role: role),
      'schedule' => ScheduleScreen(role: role),
      'manual-presence' => const DosenPresenceScreen(),
      _ => AnalyticsScreen(role: role),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildBottomNav(bool isDark, ColorScheme cs) {
    final navBg = isDark ? AppColors.surfaceDark : Colors.white;
    final items = _isMahasiswa
        ? ['Dashboard', 'Izin', 'Scan', 'Matkul', 'Profil']
        : ['Dashboard', 'Izin', 'QR', 'Validasi', 'Profil'];
    final icons = _isMahasiswa
        ? [
            Icons.home_rounded,
            Icons.edit_document,
            Icons.qr_code_scanner_rounded,
            Icons.library_books_rounded,
            Icons.person_rounded,
          ]
        : [
            Icons.home_rounded,
            Icons.fact_check_rounded,
            Icons.qr_code_2_rounded,
            Icons.people_rounded,
            Icons.person_rounded,
          ];

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final isCenter = i == 2; // Scan/QR tab (center)
              final isSelected = _currentIndex == i;

              if (isCenter) {
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [AppColors.primary, AppColors.primaryLight]
                            : [AppColors.secondary, AppColors.secondaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isSelected
                                      ? AppColors.primary
                                      : AppColors.secondary)
                                  .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icons[i], color: Colors.white, size: 28),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            icons[i],
                            size: 22,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.neutral,
                          ),
                          if (!_isMahasiswa && i == 3 && _pendingValidations > 0)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutral,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Mahasiswa QR Scan View (inline, langsung buka kamera)
class _ScanQrView extends StatefulWidget {
  const _ScanQrView();
  @override
  State<_ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends State<_ScanQrView> {
  bool _scanned = false;
  bool _processing = false;
  bool? _success;
  String _message = '';
  final _api = ApiService();
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String token) async {
    if (_scanned) return;
    setState(() {
      _scanned = true;
      _processing = true;
    });
    await _controller.stop();
    final res = await _api.scanQr(token);
    if (mounted) {
      setState(() {
        _processing = false;
        _success = res['success'] == true;
        _message =
            res['message'] ??
            (_success! ? 'Presensi berhasil!' : 'Gagal presensi.');
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw != null && raw.isNotEmpty) {
      _handleScan(raw);
    }
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _processing = false;
      _success = null;
      _message = '';
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    if (_success != null) {
      return _buildResult();
    }
    return Stack(
      children: [
        // Live camera preview
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Container(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.no_photography_rounded,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kamera tidak tersedia.\nBerikan izin kamera untuk memindai QR.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Overlay
        Container(color: Colors.black38),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _processing
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Center(
                        child: Text(
                          'Arahkan kamera ke QR Code',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text(
                'Scan QR Presensi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Posisikan QR Code dalam kotak di atas',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final ok = _success!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ok ? AppColors.successLight : AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 60,
                color: ok ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              ok ? 'Presensi Berhasil!' : 'Presensi Gagal',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ok ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: ok ? AppColors.success : AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
