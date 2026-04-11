import 'package:flutter/material.dart';

class EnrollmentProvider extends ChangeNotifier {
  List<String> _enrolledCourses = [];

  List<String> get enrolledCourses => _enrolledCourses;

  Future<void> fetchEnrollments() async {
    // Simulasi fetch data
    await Future.delayed(const Duration(seconds: 1));
    _enrolledCourses = [
      'Web Programming',
      'Database Design',
      'Mobile Development',
    ];
    notifyListeners();
  }

  Future<bool> enrollCourse(String courseName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _enrolledCourses.add(courseName);
    notifyListeners();
    return true;
  }
}
