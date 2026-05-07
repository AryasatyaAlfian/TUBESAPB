import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _userType = 'mahasiswa';
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _nimCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await ApiService().register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _userType == 'mahasiswa' ? _nimCtrl.text.trim() : null,
        _passwordCtrl.text,
        _userType,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun berhasil dibuat! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registrasi gagal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Akun'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.backgroundDark, AppColors.surfaceDark]
                : [const Color(0xFFE8F0F8), const Color(0xFFF0F4F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daftar sebagai ${_userType == 'mahasiswa' ? 'Mahasiswa' : 'Dosen'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.neutral,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.3 : 0.08,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark
                              ? AppColors.dividerDark
                              : AppColors.dividerLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Type Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                _typeBtn(
                                  'mahasiswa',
                                  Icons.person_rounded,
                                  'Mahasiswa',
                                ),
                                _typeBtn(
                                  'dosen',
                                  Icons.person_4_rounded,
                                  'Dosen',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Nama Lengkap
                          _label('NAMA LENGKAP'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nama lengkap',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // NIM (hanya untuk mahasiswa)
                          if (_userType == 'mahasiswa') ...[
                            _label('NIM'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nimCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Masukkan NIM',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'NIM tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email
                          _label('EMAIL'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'nama@universitas.ac.id',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value!.contains('@')) {
                                return 'Email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          _label('PASSWORD'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value!.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Konfirmasi Password
                          _label('KONFIRMASI PASSWORD'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Konfirmasi password tidak boleh kosong';
                              }
                              if (value != _passwordCtrl.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _register,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Buat Akun',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String type, IconData icon, String label) {
    final selected = _userType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.neutral,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.neutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: AppColors.neutral,
    ),
  );
}
