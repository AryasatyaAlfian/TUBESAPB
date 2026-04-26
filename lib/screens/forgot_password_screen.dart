import 'package:flutter/material.dart';
import '../api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  final ApiService _apiService = ApiService();

  void _sendOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email harus diisi.')),
      );
      return;
    }

    setState(() { _isLoading = true; });
    final result = await _apiService.sendOtpReset(_emailController.text);
    setState(() { _isLoading = false; });

    if (!mounted) return;

    if (result['success']) {
      setState(() { _otpSent = true; });
      // Simulasi dari backend (Tampil OTP di layar)
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Simulasi Email Masuk'),
        content: Text(result['message']),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))
        ],
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Gagal mengirim OTP.')),
      );
    }
  }

  void _resetPassword() async {
    if (_otpController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua form harus diisi.')),
      );
      return;
    }

    setState(() { _isLoading = true; });
    final result = await _apiService.resetPassword(
      _emailController.text, 
      _otpController.text, 
      _passwordController.text
    );
    setState(() { _isLoading = false; });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success']) {
      // Kembali ke halaman login
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lupa Password', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
               width: double.infinity,
               constraints: const BoxConstraints(maxWidth: 400),
               padding: const EdgeInsets.all(32),
               decoration: BoxDecoration(
                 color: Theme.of(context).colorScheme.surface,
                 borderRadius: BorderRadius.circular(32),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.2),
                     blurRadius: 24,
                     offset: const Offset(0, 12),
                   ),
                 ],
               ),
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _otpSent ? Icons.lock_reset : Icons.mark_email_read, 
                      size: 64, 
                      color: Theme.of(context).colorScheme.primary
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _otpSent ? 'Reset Password' : 'Cari Akun Anda',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _otpSent ? 'Masukkan OTP yang dikirim ke email beserta password baru Anda.' 
                               : 'Masukkan email universitas Anda untuk menerima kode OTP pemulihan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _emailController,
                      enabled: !_otpSent, // disable when otp is sent
                      decoration: const InputDecoration(
                        hintText: 'student@university.ac.id',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    if (_otpSent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _otpController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 6-Digit OTP',
                          prefixIcon: Icon(Icons.password),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password Baru',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : (_otpSent ? _resetPassword : _sendOtp),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_otpSent ? 'Reset Password' : 'Kirim Kode OTP'),
                      ),
                    ),
                  ],
               ),
            ),
          )
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
