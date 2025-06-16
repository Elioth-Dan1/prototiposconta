import 'package:app_flutter/ui/pages/home_page.dart';
import 'package:app_flutter/ui/pages/register_page.dart';
import 'package:app_flutter/ui/pages/remember_password.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:social_login_buttons/social_login_buttons.dart';

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
        password: _passwordController.text,
      );

      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(credential.user!.uid)
          .get();

      final rol = doc.data()?['rol'] ?? 'usuario';
      final suscripcion = doc.data()?['suscripcion'] ?? 'basico';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(role: rol, suscripcion: suscripcion),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
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
        'nombres': user.displayName,
        'email': user.email,
        'apellidoPaterno': '',
        'apellidoMaterno': '',
        'fechaNacimiento': '',
        'rol': 'usuario',
        'suscripcion': 'basico',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snapshot.data();
      if (data == null || !data.containsKey('rol')) {
        await docRef.update({'rol': 'usuario'});
      }
      if (data == null || !data.containsKey('suscripcion')) {
        await docRef.update({'suscripcion': 'basico'});
      }
    }

    final updatedDoc = await docRef.get();
    final rol = updatedDoc.data()?['rol'] ?? 'usuario';
    final suscripcion = updatedDoc.data()?['suscripcion'] ?? 'basico';

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(role: rol, suscripcion: suscripcion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset("assets/login.jpg", width: 150, height: 150),
            const SizedBox(height: 16),
            const Text(
              "Bienvenido a mi aplicación",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              child: Text(
                "Olvidé mi contraseña",
                style: TextStyle(
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RememberPassword()),
                );
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loginWithEmail,
                child: const Text("Iniciar sesión"),
              ),
            ),
            const SizedBox(height: 24),
            const Text("o inicia con"),
            const SizedBox(height: 16),
            SocialLoginButton(
              buttonType: SocialLoginButtonType.google,
              onPressed: _loginWithGoogle,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              child: Text(
                "Crear cuenta",
                style: TextStyle(
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
