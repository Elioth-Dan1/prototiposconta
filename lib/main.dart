import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          return FutureBuilder<Map<String, String>>(
            future: _getUserRoleAndSuscription(uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData) {
                final data = userSnapshot.data!;
                final role = data['role'] ?? 'usuario';
                final suscripcion = data['suscripcion'] ?? 'basico';

                return HomePage(role: role, suscripcion: suscripcion);
              } else {
                return const Scaffold(
                  body: Center(child: Text('Error al obtener los datos')),
                );
              }
            },
          );
        } else {
          return const LoginPage(); // Asegúrate que LoginPage no sea `const` si usa controladores.
        }
      },
    );
  }

  Future<Map<String, String>> _getUserRoleAndSuscription(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    final data = doc.data();

    if (data != null) {
      return {
        'role': data['rol'] ?? 'usuario',
        'suscripcion': data['suscripcion'] ?? 'basico',
      };
    } else {
      return {'role': 'usuario', 'suscripcion': 'basico'};
    }
  }
}
