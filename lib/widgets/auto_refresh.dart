import 'dart:async';
import 'package:flutter/material.dart';

/// Observer ringan untuk lifecycle aplikasi yang meneruskan event "resumed"
/// ke sebuah callback. Dipakai oleh [AutoRefreshMixin] supaya kita tidak perlu
/// meng-implement seluruh method [WidgetsBindingObserver] (yang berubah-ubah
/// antar versi Flutter).
class _ResumeObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _ResumeObserver(this.onResume);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// Memberi perilaku "near real-time" pada sebuah screen: data di-fetch ulang
/// secara berkala dan setiap kali aplikasi kembali ke foreground, sehingga
/// pembaruan dari sisi lain (dosen ↔ mahasiswa) langsung terlihat cukup dengan
/// membuka/refresh layar — tanpa perlu logout lalu login lagi.
///
/// Cara pakai:
/// 1. `with AutoRefreshMixin` pada State.
/// 2. Implement [onAutoRefresh] — biasanya memanggil `_load(silent: true)`
///    agar tidak memunculkan spinner layar penuh saat refresh otomatis.
/// 3. Panggil [startAutoRefresh] di `initState` dan [stopAutoRefresh] di
///    `dispose`.
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoRefreshTimer;
  _ResumeObserver? _resumeObserver;

  /// Interval refresh otomatis. Override bila perlu lebih cepat/lambat.
  Duration get autoRefreshInterval => const Duration(seconds: 12);

  /// Fetch ulang data tanpa menampilkan loading layar penuh.
  Future<void> onAutoRefresh();

  void startAutoRefresh() {
    _resumeObserver = _ResumeObserver(() {
      if (mounted) onAutoRefresh();
    });
    WidgetsBinding.instance.addObserver(_resumeObserver!);
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(autoRefreshInterval, (_) {
      if (mounted) onAutoRefresh();
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    if (_resumeObserver != null) {
      WidgetsBinding.instance.removeObserver(_resumeObserver!);
      _resumeObserver = null;
    }
  }
}
