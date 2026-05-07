import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart' as ms;
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

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomePage({super.key, required this.user});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool get _isMahasiswa => widget.user['role'] == 'mahasiswa';

  List<Widget> get _pages => _isMahasiswa
      ? [
          const MahasiswaDashboardView(),
          const _ScanQrView(),
          const MahasiswaIzinView(),
          const MahasiswaEnrollmentView(),
          ProfileScreen(user: widget.user, onLogout: _logout),
        ]
      : [
          const DosenDashboardView(),
          const DosenQrScreen(),
          const DosenIzinView(),
          const DosenEnrollmentView(),
          ProfileScreen(user: widget.user, onLogout: _logout),
        ];

  List<String> get _titles => _isMahasiswa
      ? ['Dashboard', 'Scan QR', 'Pengajuan Izin', 'Ambil Matkul', 'Profil']
      : [
          'Dashboard',
          'Generate QR',
          'Validasi Izin',
          'Validasi Mahasiswa',
          'Profil',
        ];

  void _logout() async {
    await ApiService().logout();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: false,
        actions: [
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
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(isDark, cs),
    );
  }

  Widget _buildBottomNav(bool isDark, ColorScheme cs) {
    final navBg = isDark ? AppColors.surfaceDark : Colors.white;
    final items = _isMahasiswa
        ? ['Dashboard', 'Scan', 'Izin', 'Matkul', 'Profil']
        : ['Dashboard', 'QR', 'Izin', 'Validasi', 'Profil'];
    final icons = _isMahasiswa
        ? [
            Icons.home_rounded,
            Icons.qr_code_scanner_rounded,
            Icons.edit_document,
            Icons.library_books_rounded,
            Icons.person_rounded,
          ]
        : [
            Icons.home_rounded,
            Icons.qr_code_2_rounded,
            Icons.fact_check_rounded,
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
            color: Colors.black.withOpacity(0.06),
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
              final isCenter = i == 1; // Scan/QR tab
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
                                  .withOpacity(0.4),
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
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[i],
                        size: 22,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.neutral,
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

  Future<void> _handleScan(String token) async {
    if (_scanned) return;
    setState(() {
      _scanned = true;
      _processing = true;
    });
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

  void _reset() => setState(() {
    _scanned = false;
    _processing = false;
    _success = null;
    _message = '';
  });

  @override
  Widget build(BuildContext context) {
    if (_success != null) {
      return _buildResult();
    }
    return Stack(
      children: [
        // MobileScanner placeholder - will be enabled after fixing dependencies
        Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'QR Scanner\n(Placeholder)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
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
