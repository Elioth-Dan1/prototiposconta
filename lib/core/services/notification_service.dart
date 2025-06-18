import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Solicita permisos (importante en iOS, también útil en Android 13+)
    await FirebaseMessaging.instance.requestPermission();

    // Configura canal para Android
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(initSettings);

    // Obtiene token FCM
    final token = await FirebaseMessaging.instance.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Guarda en Supabase
    if (token != null && uid != null) {
      await Supabase.instance.client
          .from('usuarios')
          .update({'fcm_token': token})
          .eq('id', uid);
    }

    // Cuando la app está abierta y recibe una notificación
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        _local.show(
          n.hashCode,
          n.title,
          n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminders', // ID del canal
              'Recordatorios',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
}
