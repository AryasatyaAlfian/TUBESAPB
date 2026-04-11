import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/enrollment_provider.dart';
import 'providers/permission_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => EnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => PermissionProvider()),
      ],
      child: MaterialApp(
        title: 'Tubes APB - Attendance and Permission Management',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final authProvider = context.read<AuthProvider>();
      final isLoggedIn = await authProvider.checkLoginStatus();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          isLoggedIn ? '/home' : '/login',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Tubes APB',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendance System',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}