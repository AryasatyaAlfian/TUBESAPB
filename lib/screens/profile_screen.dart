import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.user, required this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _mahasiswa;
  Map<String, dynamic>? _dosenProfile;
  int? _totalPresensi;
  int? _totalMahasiswa;
  bool _loadingDetail = false;

  bool get _isMahasiswa =>
      (widget.user['role'] ?? 'mahasiswa').toString() == 'mahasiswa';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    final res = _isMahasiswa
        ? await _api.getMahasiswaProfile()
        : await _api.getDosenProfile();
    if (!mounted) return;
    setState(() {
      _loadingDetail = false;
      if (res['success'] == true) {
        if (_isMahasiswa) {
          _mahasiswa = (res['data']['mahasiswa'] as Map?)
              ?.cast<String, dynamic>();
          _totalPresensi = res['data']['totalPresensi'] as int?;
        } else {
          _dosenProfile = Map<String, dynamic>.from(res['data'] as Map);
          _totalMahasiswa = res['data']['totalMahasiswa'] as int?;
        }
      }
    });
  }

  String _initial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';

  Future<void> _editProfile() async {
    final jurusanCtrl = TextEditingController(
      text: _mahasiswa?['jurusan']?.toString() ?? '',
    );
    final angkatanCtrl = TextEditingController(
      text: _mahasiswa?['angkatan']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: _mahasiswa?['phone']?.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jurusanCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jurusan',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: angkatanCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Angkatan',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No. Telepon',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final res = await _api.updateMahasiswaProfile(
      jurusan: jurusanCtrl.text.trim(),
      angkatan: angkatanCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ?? (res['success'] == true ? 'Tersimpan' : 'Gagal'),
        ),
        backgroundColor: res['success'] == true
            ? AppColors.success
            : AppColors.error,
      ),
    );
    if (res['success'] == true) _loadDetail();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.user['name'] ?? 'Pengguna';
    final email = widget.user['email'] ?? '';
    final role = (widget.user['role'] ?? 'mahasiswa').toString();
    final roleLabel = role == 'dosen' ? 'Dosen' : 'Mahasiswa';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Profile Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white24,
                child: Text(
                  _initial(name),
                  style: const TextStyle(
                    fontSize: 28,
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
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        roleLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Account info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('INFORMASI AKUN'),
            if (_isMahasiswa)
              TextButton.icon(
                onPressed: _loadingDetail ? null : _editProfile,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _infoCard(context, isDark, [
          _infoRow(context, Icons.person_rounded, 'Nama Lengkap', name),
          _infoRow(context, Icons.email_outlined, 'Email', email),
          _infoRow(context, Icons.badge_rounded, 'Role', roleLabel),
          if (_isMahasiswa) ...[
            _infoRow(
              context,
              Icons.tag_rounded,
              'NIM',
              _mahasiswa?['nim']?.toString() ?? '-',
            ),
            _infoRow(
              context,
              Icons.school_outlined,
              'Jurusan',
              _mahasiswa?['jurusan']?.toString() ?? '-',
            ),
            _infoRow(
              context,
              Icons.calendar_month_outlined,
              'Angkatan',
              _mahasiswa?['angkatan']?.toString() ?? '-',
            ),
            _infoRow(
              context,
              Icons.phone_outlined,
              'No. Telepon',
              _mahasiswa?['phone']?.toString() ?? '-',
            ),
          ],
        ]),
        if (_isMahasiswa) ...[
          const SizedBox(height: 20),
          _sectionLabel('STATISTIK'),
          const SizedBox(height: 10),
          _infoCard(context, isDark, [
            _infoRow(
              context,
              Icons.fact_check_rounded,
              'Total Presensi',
              (_totalPresensi ?? 0).toString(),
            ),
          ]),
        ] else ...[
          const SizedBox(height: 20),
          _sectionLabel('STATISTIK DOSEN'),
          const SizedBox(height: 10),
          _infoCard(context, isDark, [
            _infoRow(
              context,
              Icons.people_rounded,
              'Total Mahasiswa',
              (_totalMahasiswa ?? 0).toString(),
            ),
            _infoRow(
              context,
              Icons.class_rounded,
              'Mata Kuliah',
              ((_dosenProfile?['matkuls'] as List?)?.length ?? 0).toString(),
            ),
          ]),
        ],
        const SizedBox(height: 20),

        // About App
        _sectionLabel('TENTANG APLIKASI'),
        const SizedBox(height: 10),
        _infoCard(context, isDark, [
          _infoRow(
            context,
            Icons.school_rounded,
            'Platform',
            'Sistem Presensi Kampus',
          ),
        ]),
        const SizedBox(height: 32),

        // Logout
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Konfirmasi Logout'),
                content: const Text('Apakah Anda yakin ingin keluar?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onLogout();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: AppColors.neutral,
    ),
  );

  Widget _infoCard(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutral,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
