import 'package:flutter/material.dart';

class AttendanceProvider extends ChangeNotifier {
  List<String> _attendanceRecords = [];

  List<String> get attendanceRecords => _attendanceRecords;

  Future<void> fetchAttendance() async {
    // Simulasi fetch data
    await Future.delayed(const Duration(seconds: 1));
    _attendanceRecords = [
      'Hadir - 2024-01-15',
      'Hadir - 2024-01-16',
      'Izin - 2024-01-17',
    ];
    notifyListeners();
  }

  Future<bool> markAttendance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _attendanceRecords.add('Hadir - ${DateTime.now()}');
    notifyListeners();
    return true;
  }
}
