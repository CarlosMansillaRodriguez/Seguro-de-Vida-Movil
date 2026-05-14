import 'package:flutter/material.dart';
import '../screen/auth/login_screen.dart';
import '../screen/auth/register_screen.dart';
import '../screen/auth/forgot_password_screen.dart';
import '../screen/dashboard/dashboard_screen.dart';
import '../screen/cotizacion/cotizar_screen.dart';
import '../screen/cotizacion/resultado_cotizacion_screen.dart';
import '../screen/poliza/polizas_screen.dart';
import '../screen/poliza/emitir_poliza_screen.dart';
import '../screen/documentos/documentos_screen.dart';
import '../screen/renovacion/renovacion_screen.dart';

class AppRoutes {
  static final routes = <String, WidgetBuilder>{
    '/': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot': (context) => const ForgotPasswordScreen(),
    '/dashboard': (context) => const DashboardScreen(),
    '/cotizar': (context) => const CotizarScreen(),
    '/polizas': (context) => const PolizasScreen(),
    '/polizas/emitir': (context) => const EmitirPolizaScreen(),
    '/renovaciones': (context) => const RenovacionScreen(),
  };

  /// Para rutas con parámetros usa Navigator.push directo:
  /// Navigator.push(context, MaterialPageRoute(
  ///   builder: (_) => DocumentosScreen(cotizacionId: id),
  /// ));
}