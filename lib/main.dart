import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://tircyfyfhishzhzrlrup.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpcmN5ZnlmaGlzaHpoenJscnVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxMTYyMDQsImV4cCI6MjA2NTY5MjIwNH0.TpyfLjDf1DEhX8hZI4e0-6qNfoJEAQ_0rd6BxN5tZAg',
  );

  final connected = await isSupabaseConnected();

  if (!connected) {
    runApp(const SupabaseErrorApp());
    return;
  }

  runApp(const MyApp());
}

Future<bool> isSupabaseConnected() async {
  try {
    final response = await Supabase.instance.client
        .from('usuarios') // Asegúrate que esta tabla existe
        .select()
        .limit(1)
        .maybeSingle();

    return true;
  } catch (e) {
    debugPrint('❌ Error de conexión con Supabase: $e');
    return false;
  }
}

class SupabaseErrorApp extends StatelessWidget {
  const SupabaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            '❌ No se pudo conectar a Supabase.\nVerifica tu conexión o configuración.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hábitos Saludables',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb_auth.User?>(
      stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          return FutureBuilder<Map<String, String>>(
            future: _fetchUserDataWithDelay(uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData) {
                return HomePage(
                  role: userSnapshot.data!['role']!,
                  suscripcion: userSnapshot.data!['suscripcion']!,
                );
              }

              return const Scaffold(
                body: Center(
                  child: Text(
                    'No se encontró usuario, por favor intenta más tarde.',
                  ),
                ),
              );
            },
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }

  Future<Map<String, String>> _fetchUserDataWithDelay(String uid) async {
    await Future.delayed(const Duration(seconds: 1));

    final res = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (res == null) throw Exception("Usuario no encontrado en Supabase");

    return {
      'role': res['rol'] as String? ?? 'usuario',
      'suscripcion': res['suscripcion'] as String? ?? 'basico',
    };
  }

  Future<Map<String, String>> _fetchUserData(String uid) async {
    final res = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('id', uid)
        .single();

    return {
      'role': res['role'] as String? ?? 'usuario',
      'suscripcion': res['suscripcion'] as String? ?? 'basico',
    };
  }
}
