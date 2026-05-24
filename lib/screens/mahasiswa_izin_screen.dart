import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class MahasiswaIzinView extends StatefulWidget {
  const MahasiswaIzinView({super.key});
  @override
  State<MahasiswaIzinView> createState() => _MahasiswaIzinViewState();
}

class _MahasiswaIzinViewState extends State<MahasiswaIzinView>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _picker = ImagePicker();
  late TabController _tab;
  bool _loading = true;
  String _error = '';
  List<dynamic> _matkuls = [];
  List<dynamic> _izins = [];
  int? _selectedMatkul;
  final _alasanCtrl = TextEditingController();
  String _tanggal = '';
  File? _buktiFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _alasanCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final res = await _api.getMahasiswaIzin();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _matkuls = res['data']['matkuls'] ?? [];
        _izins = res['data']['izins'] ?? [];
      } else {
        _error = res['message'] ?? 'Gagal';
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tanggal = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _pickFile(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() => _buktiFile = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih file: $e')));
      }
    }
  }

  void _showFileSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedMatkul == null || _tanggal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mata kuliah dan tanggal harus diisi.')),
      );
      return;
    }
    if (_buktiFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti izin (foto) wajib dilampirkan.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final res = await _api.submitIzin(
      matkulId: _selectedMatkul!,
      tanggal: _tanggal,
      alasan: _alasanCtrl.text,
      buktiFile: _buktiFile!,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ?? (res['success'] == true ? 'Berhasil' : 'Gagal'),
        ),
        backgroundColor: res['success'] == true
            ? AppColors.success
            : AppColors.error,
      ),
    );

    if (res['success'] == true) {
      setState(() {
        _selectedMatkul = null;
        _tanggal = '';
        _alasanCtrl.clear();
        _buktiFile = null;
      });
      await _load();
      if (mounted) _tab.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) return Center(child: Text('Error: $_error'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          child: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Ajukan Izin'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_form(isDark), _history(isDark)],
          ),
        ),
      ],
    );
  }

  Widget _form(bool isDark) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_document, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengajuan Izin',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Lampirkan bukti agar izin dapat divalidasi dosen',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _label('MATA KULIAH'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedMatkul,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.class_rounded),
          ),
          hint: const Text('Pilih mata kuliah'),
          items: _matkuls
              .map<DropdownMenuItem<int>>(
                (m) => DropdownMenuItem<int>(
                  value: m['id'] as int,
                  child: Text(m['nama'] ?? ''),
                ),
              )
              .toList(),
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
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.neutral,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _tanggal.isEmpty ? 'Pilih tanggal...' : _tanggal,
                  style: TextStyle(
                    color: _tanggal.isEmpty
                        ? AppColors.neutral
                        : (isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurfaceLight),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _label('BUKTI IZIN (FOTO)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showFileSourceSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _buktiFile != null
                    ? AppColors.primary
                    : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _buktiFile != null
                      ? Icons.check_circle_rounded
                      : Icons.upload_file_rounded,
                  color: _buktiFile != null
                      ? AppColors.success
                      : AppColors.neutral,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _buktiFile != null
                        ? _buktiFile!.path.split(Platform.pathSeparator).last
                        : 'Lampirkan foto bukti (galeri / kamera)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _buktiFile != null
                          ? (isDark
                                ? AppColors.onSurfaceDark
                                : AppColors.onSurfaceLight)
                          : AppColors.neutral,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_buktiFile != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _buktiFile!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _label('ALASAN IZIN'),
        const SizedBox(height: 8),
        TextField(
          controller: _alasanCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Jelaskan alasan izin Anda...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 64),
              child: Icon(Icons.notes_rounded),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Mengirim...' : 'Kirim Pengajuan'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _history(bool isDark) {
    if (_izins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.infoLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 48,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum Ada Riwayat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pengajuan izin Anda akan tampil di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.neutral),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _izins.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final iz = _izins[i];
          final matkul = iz['matkul'] ?? {};
          final status = (iz['status'] ?? 'pending').toString();
          final color = _statusColor(status);
          final bg = _statusBg(status);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        matkul['nama'] ?? 'Mata Kuliah',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: AppColors.neutral,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(iz['tanggal']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
                if ((iz['alasan'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    iz['alasan'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutral,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final s = raw.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Color _statusColor(String s) => switch (s) {
    'approved' => AppColors.success,
    'rejected' => AppColors.error,
    _ => AppColors.warning,
  };
  Color _statusBg(String s) => switch (s) {
    'approved' => AppColors.successLight,
    'rejected' => AppColors.errorLight,
    _ => AppColors.warningLight,
  };
  String _statusLabel(String s) => switch (s) {
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    _ => 'Menunggu',
  };

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: AppColors.neutral,
    ),
  );
}
