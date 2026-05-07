import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.user, required this.onLogout});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_data');
    if (raw != null && mounted) {
      setState(() => _userData = jsonDecode(raw));
    }
  }

  String _initial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _userData['name'] ?? widget.user['name'] ?? 'Pengguna';
    final email = _userData['email'] ?? widget.user['email'] ?? '';
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
                child: Text(_initial(name), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text(roleLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Info Section
        _sectionLabel('INFORMASI AKUN'),
        const SizedBox(height: 10),
        _infoCard(context, isDark, [
          _infoRow(context, Icons.person_rounded, 'Nama Lengkap', name),
          _infoRow(context, Icons.email_outlined, 'Email', email),
          _infoRow(context, Icons.badge_rounded, 'Role', roleLabel),
        ]),
        const SizedBox(height: 20),

        // About App
        _sectionLabel('TENTANG APLIKASI'),
        const SizedBox(height: 10),
        _infoCard(context, isDark, [
          _infoRow(context, Icons.info_outline_rounded, 'Versi', '2.0.0'),
          _infoRow(context, Icons.school_rounded, 'Platform', 'Sistem Presensi Kampus'),
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
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                  FilledButton(
                    onPressed: () { Navigator.pop(context); widget.onLogout(); },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: AppColors.neutral));

  Widget _infoCard(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neutral, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
