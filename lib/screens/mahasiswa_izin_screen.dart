import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class MahasiswaIzinView extends StatefulWidget {
  const MahasiswaIzinView({super.key});
  @override
  State<MahasiswaIzinView> createState() => _MahasiswaIzinViewState();
}

class _MahasiswaIzinViewState extends State<MahasiswaIzinView> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tab;
  bool _loading = true;
  String _error = '';
  List<dynamic> _matkuls = [];
  int? _selectedMatkul;
  final _alasanCtrl = TextEditingController();
  String _tanggal = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); _alasanCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    final res = await _api.getMahasiswaIzin();
    if (mounted) setState(() {
      _loading = false;
      if (res['success'] == true) _matkuls = res['data']['matkuls'] ?? [];
      else _error = res['message'] ?? 'Gagal';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.primary),
      ), child: child!),
    );
    if (picked != null) setState(() => _tanggal = picked.toIso8601String().split('T').first);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text('Error: $_error'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      Container(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: TabBar(controller: _tab, tabs: const [Tab(text: 'Ajukan Izin'), Tab(text: 'Riwayat')]),
      ),
      Expanded(child: TabBarView(controller: _tab, children: [_form(isDark), _history(isDark)])),
    ]);
  }

  Widget _form(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.edit_document, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pengajuan Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            Text('Isi form berikut untuk mengajukan izin', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      _label('MATA KULIAH'),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(
        value: _selectedMatkul,
        decoration: const InputDecoration(prefixIcon: Icon(Icons.class_rounded)),
        hint: const Text('Pilih mata kuliah'),
        items: _matkuls.map<DropdownMenuItem<int>>((m) => DropdownMenuItem<int>(value: m['id'] as int, child: Text(m['nama'] ?? ''))).toList(),
        onChanged: (v) => setState(() => _selectedMatkul = v),
      ),
      const SizedBox(height: 16),
      _label('TANGGAL IZIN'),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.neutral, size: 20),
            const SizedBox(width: 12),
            Text(_tanggal.isEmpty ? 'Pilih tanggal...' : _tanggal,
              style: TextStyle(color: _tanggal.isEmpty ? AppColors.neutral : (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight))),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      _label('ALASAN IZIN'),
      const SizedBox(height: 8),
      TextField(
        controller: _alasanCtrl,
        maxLines: 4,
        decoration: const InputDecoration(hintText: 'Jelaskan alasan izin Anda...', prefixIcon: Padding(padding: EdgeInsets.only(bottom: 64), child: Icon(Icons.notes_rounded))),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _submitting ? null : () {
            if (_selectedMatkul == null || _tanggal.isEmpty || _alasanCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua field harus diisi.')));
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan izin dikirim!')));
          },
          icon: const Icon(Icons.send_rounded),
          label: const Text('Kirim Pengajuan'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    ]),
  );

  Widget _history(bool isDark) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: AppColors.infoLight, shape: BoxShape.circle),
          child: const Icon(Icons.history_rounded, size: 48, color: AppColors.info)),
        const SizedBox(height: 16),
        const Text('Riwayat Izin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Riwayat izin Anda akan ditampilkan di sini.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.neutral)),
      ]),
    ),
  );

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.neutral));
}
