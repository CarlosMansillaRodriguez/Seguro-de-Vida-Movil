/*import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
    // TODO: enviar este token al backend
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Permiso: ${settings.authorizationStatus}');
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
}