import 'package:flutter/material.dart';

class PermissionProvider extends ChangeNotifier {
  List<String> _permissions = [];

  List<String> get permissions => _permissions;

  Future<void> fetchPermissions() async {
    // Simulasi fetch data
    await Future.delayed(const Duration(seconds: 1));
    _permissions = [
      'Izin Sakit - 2024-01-10',
      'Izin Keluarga - 2024-01-20',
    ];
    notifyListeners();
  }

  Future<bool> requestPermission(String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _permissions.add('Pending - $reason');
    notifyListeners();
    return true;
  }
}
