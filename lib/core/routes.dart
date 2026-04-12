import 'package:flutter/material.dart';
import '../screen/auth/login_screen.dart';
import '../screen/auth/register_screen.dart';
import '../screen/auth/forgot_password_screen.dart';
import '../screen/dashboard/dashboard_screen.dart';

class AppRoutes {
  static final routes = {
    '/': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot': (context) => const ForgotPasswordScreen(),
    '/dashboard': (context) => const DashboardScreen(),
  };
}