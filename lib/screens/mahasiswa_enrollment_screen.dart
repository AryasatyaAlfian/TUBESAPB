import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class MahasiswaEnrollmentView extends StatefulWidget {
  const MahasiswaEnrollmentView({super.key});
  @override
  State<MahasiswaEnrollmentView> createState() => _MahasiswaEnrollmentViewState();
}

class _MahasiswaEnrollmentViewState extends State<MahasiswaEnrollmentView> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tab;
  bool _loading = true;
  String _error = '';
  List<dynamic> _available = [];
  List<dynamic> _enrollments = [];

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getMahasiswaEnrollments();
    if (mounted) setState(() {
      _loading = false;
      if (res['success'] == true) {
        _available = res['data']['availableMatkuls'] ?? [];
        _enrollments = res['data']['enrollments'] ?? [];
      } else _error = res['message'] ?? 'Gagal';
    });
  }

  Future<void> _enroll(int id) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await _api.requestEnrollment(id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['message'] ?? (res['success'] == true ? 'Berhasil' : 'Gagal')),
      backgroundColor: res['success'] == true ? AppColors.success : AppColors.error,
    ));
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
      const SizedBox(height: 16),
      Text(_error, style: const TextStyle(color: AppColors.error)),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Coba Lagi')),
    ]));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Container(color: isDark ? AppColors.surfaceDark : Colors.white,
        child: TabBar(controller: _tab, tabs: [
          Tab(text: 'Tersedia (${_available.length})'),
          Tab(text: 'Pengajuan Saya (${_enrollments.length})'),
        ])),
      Expanded(child: TabBarView(controller: _tab, children: [_availableList(isDark), _myEnrollments(isDark)])),
    ]);
  }

  Widget _availableList(bool isDark) {
    if (_available.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: AppColors.infoLight, shape: BoxShape.circle),
        child: const Icon(Icons.library_books_rounded, size: 48, color: AppColors.info)),
      const SizedBox(height: 16),
      const Text('Tidak Ada Mata Kuliah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Semua mata kuliah sudah diambil.', style: TextStyle(color: AppColors.neutral)),
    ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _available.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = _available[i];
          final enrolled = _enrollments.any((e) => e['matkul_id'] == m['id']);
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 4, height: 60, decoration: BoxDecoration(
                  color: enrolled ? AppColors.neutral : AppColors.secondary,
                  borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, children: [
                    _chip('${m['sks'] ?? '-'} SKS', AppColors.primary, const Color(0xFFD6E8FF)),
                    _chip(m['hari'] ?? '-', AppColors.secondary, const Color(0xFFDCEAFF)),
                    _chip(m['ruangan'] ?? '-', AppColors.neutral, AppColors.surfaceVariantLight),
                  ]),
                ])),
                const SizedBox(width: 12),
                enrolled
                    ? Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Diajukan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)))
                    : FilledButton(
                        onPressed: () => _enroll(m['id']),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                        child: const Text('Ambil', style: TextStyle(fontSize: 13)),
                      ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _myEnrollments(bool isDark) {
    if (_enrollments.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: AppColors.warningLight, shape: BoxShape.circle),
        child: const Icon(Icons.inbox_rounded, size: 48, color: AppColors.warning)),
      const SizedBox(height: 16),
      const Text('Belum Ada Pengajuan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Ambil mata kuliah untuk memulai.', style: TextStyle(color: AppColors.neutral)),
    ]));

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _enrollments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = _enrollments[i];
        final m = e['matkul'] ?? {};
        final status = e['status'] ?? 'pending';
        final statusColor = status == 'approved' ? AppColors.success : status == 'rejected' ? AppColors.error : AppColors.warning;
        final statusBg = status == 'approved' ? AppColors.successLight : status == 'rejected' ? AppColors.errorLight : AppColors.warningLight;
        final statusLabel = status == 'approved' ? 'Diterima' : status == 'rejected' ? 'Ditolak' : 'Menunggu';

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text('${m['sks'] ?? '-'} SKS • ${m['hari'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.neutral)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor))),
            ]),
          ),
        );
      },
    );
  }

  Widget _chip(String text, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
  );
}
