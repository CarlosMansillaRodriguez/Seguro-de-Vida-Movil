import 'package:flutter/material.dart';
import 'core/routes.dart';
import 'core/theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seguro de Vida',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: AppRoutes.routes,
    );
  }
}