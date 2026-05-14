/*import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MyApp());
}*/
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(const MyApp());
}