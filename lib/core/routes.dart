/*
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
import '../screen/agente/agente_dashboard_screen.dart';
import '../screen/agente/cotizaciones_pendientes_screen.dart';
import '../screen/agente/renovaciones_agente_screen.dart';
import '../screen/admin/admin_dashboard_screen.dart';
import '../screen/admin/gestionar_agentes_screen.dart';
import '../screen/admin/gestionar_clientes_screen.dart';
import '../screen/admin/reportes_screen.dart';
import '../screen/admin/bitacora_screen.dart';
import '../screen/sistema/sistema_dashboard_screen.dart';
import '../screen/sistema/tenants_lista_screen.dart';
import '../screen/pago/historial_pagos_screen.dart';
import '../screen/siniestro/siniestros_screen.dart';
import '../screen/siniestro/indemnizaciones_screen.dart';
import '../screen/documentos/mis_documentos_screen.dart';
import '../screen/poliza/valor_rescate_screen.dart';
import '../screen/cotizacion/recomendacion_ia_screen.dart';

class AppRoutes {
  static final routes = <String, WidgetBuilder>{
    '/': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot': (context) => const ForgotPasswordScreen(),

    // ── Cliente ───────────────────────────────────────────────────────────
    '/dashboard': (context) => const DashboardScreen(),
    '/cotizar': (context) => const CotizarScreen(),
    '/polizas': (context) => const PolizasScreen(),
    '/polizas/emitir': (context) => const EmitirPolizaScreen(),
    '/renovaciones': (context) => const RenovacionScreen(),
    '/orden-medica': (context) => const OrdenMedicaScreen(),
    '/pagos': (context) => const HistorialPagosScreen(),
    '/siniestros': (context) => const SiniestrosScreen(),
    '/mis-documentos': (context) => const MisDocumentosScreen(),

    // ── Agente ────────────────────────────────────────────────────────────
    '/agente': (context) => const AgenteDashboardScreen(),
    '/agente/cotizaciones': (context) =>
        const CotizacionesPendientesScreen(),
    '/agente/renovaciones': (context) =>
        const RenovacionesAgenteScreen(),
    '/agente/siniestros': (context) =>
        const SiniestrosScreen(soloMios: false),
    '/agente/indemnizaciones': (context) =>
        const IndemnizacionesScreen(),

    // ── Admin del seguro (AdminAgencia + Administrador) ───────────────────
    '/admin': (context) => const AdminDashboardScreen(),
    '/admin/agentes': (context) => const GestionarAgentesScreen(),
    '/admin/clientes': (context) => const GestionarClientesScreen(),
    '/admin/reportes': (context) => const ReportesScreen(),
    '/admin/bitacora': (context) => const BitacoraScreen(),
    '/admin/pagos': (context) => const HistorialPagosScreen(),
    '/admin/indemnizaciones': (context) => const IndemnizacionesScreen(),

    // ── Sistema (superuser global) ────────────────────────────────────────
    '/sistema': (context) => const SistemaDashboardScreen(),
    '/sistema/tenants': (context) => const TenantsListaScreen(),

    //------------------------
    '/recomendacion-ia': (context) => const RecomendacionIAScreen(),
    '/poliza/rescate': (context) => const ValorRescateScreen(
          polizaId: 0,
          numeroPoliza: '',
        ),
  };
}