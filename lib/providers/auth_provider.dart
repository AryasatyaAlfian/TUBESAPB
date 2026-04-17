import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  Future<bool> checkLoginStatus() async {
    // Simulasi pengecekan login status
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoggedIn = false; // Default belum login
    notifyListeners();
    return _isLoggedIn;
  }

  Future<bool> login(String email, String password) async {
    // Simulasi login
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
  }
}
