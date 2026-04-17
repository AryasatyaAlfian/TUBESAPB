import 'package:flutter/material.dart';
import 'package:tubesapb/screens/login_screen.dart';
import 'package:tubesapb/screens/home_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    home: (context) => const HomeScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}
