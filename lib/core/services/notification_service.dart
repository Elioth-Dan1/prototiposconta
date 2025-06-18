import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import '../../main.dart';                    // ← importa navigatorKey
import '../../ui/pages/mood_tracker_page.dart';
import '../../ui/pages/days_counter_page.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  /* ─────────────── PUBLIC ─────────────── */
  static Future<void> init() async {
    /* 1. Permisos (iOS / Android 13+) */
    await FirebaseMessaging.instance.requestPermission();

    /* 2. Canal Android */
    const channel = AndroidNotificationChannel(
      'reminders',
      'Recordatorios',
      description: 'Avisos diarios y de ánimo',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /* 3. Init local plugin */
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(initSettings);

    /* 4. Guarda token inicial y escucha rotaciones */
    await _saveToken(await FirebaseMessaging.instance.getToken());
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    /* 5. Notificación en primer plano */
    FirebaseMessaging.onMessage.listen(_showForeground);

    /* 6. Deep-link */
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNavigation(initial);
  }

  static Future<void> clearToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
      await Supabase.instance.client
          .from('usuarios')
          .update({'fcm_token': null})
          .eq('id', uid);
    } catch (e) {
      debugPrint('Error limpiando token FCM: $e');
    }
  }

  /* ─────────────── PRIVADOS ─────────────── */
  static Future<void> _saveToken(String? token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (token != null && uid != null) {
      await Supabase.instance.client
          .from('usuarios')
          .update({'fcm_token': token})
          .eq('id', uid);
    }
  }

  static void _showForeground(RemoteMessage msg) {
    final n = msg.notification;
    if (n != null) {
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders',
            'Recordatorios',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  static void _handleNavigation(RemoteMessage msg) {
    final route = msg.data['route'];
    if (navigatorKey.currentState == null) return;

    if (route == 'mood') {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const MoodTrackerPage()),
      );
    } else if (route == 'days') {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const DaysCounterPage()),
      );
    }
  }
}
