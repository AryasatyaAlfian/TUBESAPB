import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tubesapb/providers/auth_provider.dart';
import 'package:tubesapb/providers/attendance_provider.dart';
import 'package:tubesapb/providers/enrollment_provider.dart';
import 'package:tubesapb/providers/permission_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final attendance = context.read<AttendanceProvider>();
    final enrollment = context.read<EnrollmentProvider>();
    final permission = context.read<PermissionProvider>();

    await Future.wait([
      attendance.fetchAttendance(),
      enrollment.fetchEnrollments(),
      permission.fetchPermissions(),
    ]);
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attendance Section
              Text(
                'Attendance Records',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<AttendanceProvider>(
                builder: (context, provider, _) {
                  if (provider.attendanceRecords.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No attendance records'),
                      ),
                    );
                  }
                  return Column(
                    children: provider.attendanceRecords
                        .map((record) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(record),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Enrollment Section
              Text(
                'Enrolled Courses',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<EnrollmentProvider>(
                builder: (context, provider, _) {
                  if (provider.enrolledCourses.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No enrolled courses'),
                      ),
                    );
                  }
                  return Column(
                    children: provider.enrolledCourses
                        .map((course) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(course)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Permissions Section
              Text(
                'Permissions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<PermissionProvider>(
                builder: (context, provider, _) {
                  if (provider.permissions.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No permissions'),
                      ),
                    );
                  }
                  return Column(
                    children: provider.permissions
                        .map((permission) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle),
                                    const SizedBox(width: 12),
                                    Expanded(child: Text(permission)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
