/*
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Notificación en background: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'seguro_vida_channel',
    'Seguros de Vida',
    description: 'Notificaciones de tu seguro de vida',
    importance: Importance.high,
  );

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Cada vez que el token rota (puede pasar en cualquier momento),
    // lo reenviamos al backend si el usuario está autenticado.
    _messaging.onTokenRefresh.listen((nuevoToken) {
      _enviarTokenAlBackend(nuevoToken);
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Permiso: ${settings.authorizationStatus}');
  }

  /// Debe llamarse DESPUÉS de un login exitoso (cuando ya hay authHeaders
  /// válidos), para registrar el dispositivo del usuario actual.
  Future<void> registrarTokenEnBackend() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _enviarTokenAlBackend(token);
    } catch (e) {
      debugPrint('Error obteniendo/enviando token FCM: $e');
    }
  }

  Future<void> _enviarTokenAlBackend(String token) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) return;

    try {
      final res = await http.post(
        Uri.parse('${auth.baseUrl}/dispositivos/'),
        headers: auth.authHeaders,
        body: jsonEncode({
          'fcm_token': token,
          'plataforma': 'android',
        }),
      );
      if (res.statusCode == 200) {
        debugPrint('Token FCM registrado correctamente en backend.');
      } else {
        debugPrint('No se pudo registrar el token FCM: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error de red registrando token FCM: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}*/
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Notificación en background: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Flag para evitar doble init
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'seguro_vida_channel',
    'Seguros de Vida',
    description: 'Notificaciones de tu seguro de vida',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // Pedir permisos ANTES de intentar obtener el token
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Cuando el token rota, re-registrar si hay sesión activa
    _messaging.onTokenRefresh.listen((nuevoToken) {
      debugPrint('[FCM] Token rotado: $nuevoToken');
      _enviarTokenAlBackend(nuevoToken);
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');
  }

  /// Llamar DESPUÉS de login exitoso y DESPUÉS de init().
  /// Espera hasta 3 segundos para obtener el token si aún no está listo.
  Future<void> registrarTokenEnBackend() async {
    try {
      // Intentar obtener token con reintentos
      String? token;
      for (int i = 0; i < 3; i++) {
        token = await _messaging.getToken();
        if (token != null) break;
        await Future.delayed(const Duration(seconds: 1));
        debugPrint('[FCM] Reintento ${i + 1} para obtener token...');
      }

      if (token == null) {
        debugPrint('[FCM] No se pudo obtener token después de 3 intentos.');
        return;
      }

      debugPrint('[FCM] Token obtenido: ${token.substring(0, 20)}...');
      await _enviarTokenAlBackend(token);
    } catch (e) {
      debugPrint('[FCM] Error al registrar token: $e');
    }
  }

  Future<void> _enviarTokenAlBackend(String token) async {
    final auth = AuthService();
    if (!auth.isAuthenticated) {
      debugPrint('[FCM] No autenticado, omitiendo registro de token.');
      return;
    }

    try {
      // Registrar en DispositivoUsuario (para push via Firebase Admin)
      final res = await http.post(
        Uri.parse('${auth.baseUrl}/dispositivos/'),
        headers: auth.authHeaders,
        body: jsonEncode({
          'fcm_token': token,
          'plataforma': 'android',
        }),
      );

      if (res.statusCode == 200) {
        debugPrint('[FCM] Token registrado en DispositivoUsuario ✅');
      } else {
        debugPrint('[FCM] Error registrando en DispositivoUsuario: ${res.statusCode} ${res.body}');
      }

      // También actualizar en Usuario.fcm_token (endpoint legacy)
      final res2 = await http.post(
        Uri.parse('${auth.baseUrl}/update-token/'),
        headers: auth.authHeaders,
        body: jsonEncode({'fcm_token': token}),
      );

      if (res2.statusCode == 200) {
        debugPrint('[FCM] Token actualizado en Usuario.fcm_token ✅');
      } else {
        debugPrint('[FCM] Error actualizando Usuario.fcm_token: ${res2.statusCode}');
      }
    } catch (e) {
      debugPrint('[FCM] Error de red registrando token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint('[FCM] Mensaje en foreground: ${notification.title}');

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
}