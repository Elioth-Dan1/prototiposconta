// archivo: login_page.dart
import 'package:app_flutter/ui/pages/home_page.dart';
import 'package:app_flutter/ui/pages/register_page.dart';
import 'package:app_flutter/ui/pages/remember_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_login_buttons/social_login_buttons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _loginWithEmail() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = credential.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      final data = doc.data()!;
      final rol = data['rol'] ?? 'usuario';
      final suscripcion = data['suscripcion'] ?? 'basico';

      final existing = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        final fechaNacStr = data['fechaNacimiento'] ?? '';
        DateTime? fechaNacimiento;
        if (fechaNacStr.isNotEmpty) {
          fechaNacimiento = DateTime.tryParse(fechaNacStr);
        }

        await Supabase.instance.client.from('usuarios').insert({
          'id': userId,
          'nombres': data['nombres'] ?? '',
          'apellido_paterno': data['apellidoPaterno'] ?? '',
          'apellido_materno': data['apellidoMaterno'] ?? '',
          'telefono': data['telefono'],
          'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
          'email': credential.user!.email,
          'rol': rol,
          'suscripcion': suscripcion,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(role: rol, suscripcion: suscripcion),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: \${e.message}")));
    }
  }

  Future<void> _loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(scopes: ['email']);
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCred = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );
    final user = userCred.user;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'nombres': user.displayName ?? '',
        'apellidoPaterno': '',
        'apellidoMaterno': '',
        'telefono': null,
        'fechaNacimiento': null,
        'email': user.email,
        'rol': 'usuario',
        'suscripcion': 'basico',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final updatedDoc = await docRef.get();
    final data = updatedDoc.data()!;
    final rol = data['rol'] ?? 'usuario';
    final suscripcion = data['suscripcion'] ?? 'basico';

    final existing = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('id', user.uid)
        .maybeSingle();

    if (existing == null) {
      final fechaNacStr = data['fechaNacimiento'] ?? '';
      DateTime? fechaNacimiento;
      if (fechaNacStr.isNotEmpty) {
        fechaNacimiento = DateTime.tryParse(fechaNacStr);
      }

      await Supabase.instance.client.from('usuarios').insert({
        'id': user.uid,
        'nombres': data['nombres'] ?? '',
        'apellido_paterno': data['apellidoPaterno'] ?? '',
        'apellido_materno': data['apellidoMaterno'] ?? '',
        'telefono': data['telefono'],
        'fecha_nacimiento': fechaNacimiento?.toIso8601String(),
        'email': user.email,
        'rol': rol,
        'suscripcion': suscripcion,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(role: rol, suscripcion: suscripcion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 32,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Center(child: Image.asset("assets/app_icon.png", width: 80)),
                  const SizedBox(height: 20),
                  const Text(
                    "Bienvenido a la comunidad",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Inicia sesión o regístrate para continuar",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      child: const Text(
                        "¿Olvidaste tu contraseña?",
                        style: TextStyle(
                          color: Colors.amber,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RememberPassword()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Iniciar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _loginWithEmail,
                      child: const Text(
                        "Iniciar sesión",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "o inicia con",
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 16),

                  SocialLoginButton(
                    buttonType: SocialLoginButtonType.google,
                    onPressed: _loginWithGoogle,
                  ),

                  const SizedBox(height: 24),
                  GestureDetector(
                    child: const Text(
                      "Crear cuenta",
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                  ),

                  const Spacer(),
                  const SizedBox(height: 30),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Al continuar, aceptas los ",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        TextSpan(
                          text: "términos de servicio",
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                        TextSpan(
                          text: " y has leído la ",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        TextSpan(
                          text: "política de privacidad",
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
