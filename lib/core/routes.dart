/*import 'package:flutter/material.dart';
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
//Agregado
import '../screen/agente/agente_dashboard_screen.dart';
import '../screen/agente/cotizaciones_pendientes_screen.dart';
import '../screen/agente/renovaciones_agente_screen.dart';
import '../screen/admin/admin_dashboard_screen.dart';
import '../screen/admin/gestionar_agentes_screen.dart';
import '../screen/admin/gestionar_clientes_screen.dart';
import '../screen/admin/reportes_screen.dart';
import '../screen/admin/bitacora_screen.dart';

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
    //Agregado
    '/agente': (context) => const AgenteDashboardScreen(),
    '/agente/cotizaciones': (context) => const CotizacionesPendientesScreen(),
    '/agente/renovaciones': (context) => const RenovacionesAgenteScreen(),
    '/admin': (context) => const AdminDashboardScreen(),
    '/admin/agentes': (context) => const GestionarAgentesScreen(),
    '/admin/clientes': (context) => const GestionarClientesScreen(),
    '/admin/reportes': (context) => const ReportesScreen(),
    '/admin/bitacora': (context) => const BitacoraScreen(),
  };

  /// Para rutas con parámetros usa Navigator.push directo:
  /// Navigator.push(context, MaterialPageRoute(
  ///   builder: (_) => DocumentosScreen(cotizacionId: id),
  /// ));
}*/
import 'package:flutter/material.dart';
import '../screen/auth/login_screen.dart';
import '../screen/auth/register_screen.dart';
import '../screen/auth/forgot_password_screen.dart';
import '../screen/dashboard/dashboard_screen.dart';
import '../screen/cotizacion/cotizar_screen.dart';
import '../screen/poliza/polizas_screen.dart';
import '../screen/poliza/emitir_poliza_screen.dart';
import '../screen/renovacion/renovacion_screen.dart';
import '../screen/orden_medica/orden_medica_screen.dart';
// Pantallas de agente y admin (ya existentes)
import '../screen/agente/agente_dashboard_screen.dart';
import '../screen/agente/cotizaciones_pendientes_screen.dart';
import '../screen/agente/renovaciones_agente_screen.dart';
import '../screen/admin/admin_dashboard_screen.dart';
import '../screen/admin/gestionar_agentes_screen.dart';
import '../screen/admin/gestionar_clientes_screen.dart';
import '../screen/admin/reportes_screen.dart';
import '../screen/admin/bitacora_screen.dart';

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
    '/orden-medica': (context) => const OrdenMedicaScreen(),
    '/agente': (context) => const AgenteDashboardScreen(),
    '/agente/cotizaciones': (context) =>
        const CotizacionesPendientesScreen(),
    '/agente/renovaciones': (context) =>
        const RenovacionesAgenteScreen(),
    '/admin': (context) => const AdminDashboardScreen(),
    '/admin/agentes': (context) => const GestionarAgentesScreen(),
    '/admin/clientes': (context) => const GestionarClientesScreen(),
    '/admin/reportes': (context) => const ReportesScreen(),
    '/admin/bitacora': (context) => const BitacoraScreen(),
  };
}