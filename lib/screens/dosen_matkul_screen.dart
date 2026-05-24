import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class DosenMatkulScreen extends StatefulWidget {
  const DosenMatkulScreen({super.key});

  @override
  State<DosenMatkulScreen> createState() => _DosenMatkulScreenState();
}

class _DosenMatkulScreenState extends State<DosenMatkulScreen> {
  final _api = ApiService();
  bool _loading = true;
  String _error = '';
  List<dynamic> _matkuls = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getDosenMatkuls();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _matkuls = res['data']['matkuls'] ?? [];
        _error = '';
      } else {
        _error = res['message'] ?? 'Gagal';
      }
    });
  }

  Future<void> _openForm({Map<String, dynamic>? matkul}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MatkulFormScreen(matkul: matkul)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> matkul) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: Text(
          'Mata kuliah "${matkul['nama']}" beserta data presensinya akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await _api.deleteMatkul(matkul['id'] as int);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ?? (res['success'] == true ? 'Dihapus' : 'Gagal'),
        ),
        backgroundColor: res['success'] == true
            ? AppColors.success
            : AppColors.error,
      ),
    );
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Mata Kuliah')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
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
    }
    if (_matkuls.isEmpty) {
      return Center(
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
                Icons.class_outlined,
                size: 48,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Mata Kuliah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol Tambah untuk membuat mata kuliah.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutral),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _matkuls.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final m = Map<String, dynamic>.from(_matkuls[i] as Map);
          return Container(
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
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip(m['kode'] ?? '-', AppColors.neutral),
                          _chip(
                            '${m['credits'] ?? '-'} SKS',
                            AppColors.primary,
                          ),
                          _chip(m['hari'] ?? '-', AppColors.secondary),
                          _chip(m['jam'] ?? '-', AppColors.tertiary),
                          _chip(
                            m['ruangan'] ?? 'Tanpa ruang',
                            AppColors.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _openForm(matkul: m),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () => _delete(m),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class MatkulFormScreen extends StatefulWidget {
  final Map<String, dynamic>? matkul;
  const MatkulFormScreen({super.key, this.matkul});

  @override
  State<MatkulFormScreen> createState() => _MatkulFormScreenState();
}

class _MatkulFormScreenState extends State<MatkulFormScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kode;
  late final TextEditingController _nama;
  late final TextEditingController _jam;
  late final TextEditingController _ruangan;
  late final TextEditingController _deskripsi;
  late final TextEditingController _semester;
  late final TextEditingController _credits;
  String _hari = 'Senin';
  bool _saving = false;

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  bool get _isEdit => widget.matkul != null;

  @override
  void initState() {
    super.initState();
    final m = widget.matkul;
    _kode = TextEditingController(text: m?['kode']?.toString() ?? '');
    _nama = TextEditingController(text: m?['nama']?.toString() ?? '');
    _jam = TextEditingController(text: m?['jam']?.toString() ?? '');
    _ruangan = TextEditingController(text: m?['ruangan']?.toString() ?? '');
    _deskripsi = TextEditingController(text: m?['deskripsi']?.toString() ?? '');
    _semester = TextEditingController(text: m?['semester']?.toString() ?? '');
    _credits = TextEditingController(text: m?['credits']?.toString() ?? '');
    final hari = m?['hari']?.toString();
    if (hari != null && _days.contains(hari)) _hari = hari;
  }

  @override
  void dispose() {
    _kode.dispose();
    _nama.dispose();
    _jam.dispose();
    _ruangan.dispose();
    _deskripsi.dispose();
    _semester.dispose();
    _credits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final res = await _api.saveMatkul(
      id: _isEdit ? widget.matkul!['id'] as int : null,
      kode: _kode.text.trim(),
      nama: _nama.text.trim(),
      hari: _hari,
      jam: _jam.text.trim(),
      ruangan: _ruangan.text.trim(),
      deskripsi: _deskripsi.text.trim(),
      semester: int.parse(_semester.text.trim()),
      credits: int.parse(_credits.text.trim()),
    );
    if (!mounted) return;
    setState(() => _saving = false);
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
    if (res['success'] == true) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('KODE'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _kode,
              decoration: const InputDecoration(
                hintText: 'mis. MK001',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Kode wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _label('NAMA MATA KULIAH'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                hintText: 'mis. Pemrograman Web',
                prefixIcon: Icon(Icons.book_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _label('HARI'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _hari,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              items: _days
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _hari = v ?? 'Senin'),
            ),
            const SizedBox(height: 16),
            _label('JAM'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _jam,
              decoration: const InputDecoration(
                hintText: 'mis. 08:00-10:00',
                prefixIcon: Icon(Icons.access_time_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Jam wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _label('RUANGAN'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _ruangan,
              decoration: const InputDecoration(
                hintText: 'mis. Lab 301',
                prefixIcon: Icon(Icons.meeting_room_rounded),
              ),
            ),
            const SizedBox(height: 16),
            _label('DESKRIPSI'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _deskripsi,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Catatan singkat mata kuliah',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('SEMESTER'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _semester,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'mis. 5'),
                        validator: (v) => int.tryParse(v?.trim() ?? '') == null
                            ? 'Angka'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('SKS'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _credits,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'mis. 3'),
                        validator: (v) => int.tryParse(v?.trim() ?? '') == null
                            ? 'Angka'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
