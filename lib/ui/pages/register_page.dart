// archivo: register_page.dart
import 'package:app_flutter/ui/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      final userId = userCredential.user!.uid;

      final fechaNacStr = _fechaNacimientoController.text.trim();
      final fechaNacimiento = DateTime.tryParse(fechaNacStr);
      if (fechaNacimiento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de nacimiento inválida')),
        );
        return;
      }

      String? fcmToken;
      try {
        await FirebaseMessaging.instance.requestPermission();
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {
        fcmToken = null;
      }

      final nowIso = DateTime.now().toIso8601String();
      final baseData = {
        'nombres': _nameController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'fecha_nacimiento': fechaNacimiento.toIso8601String(),
        'email': _emailController.text.trim(),
        'rol': 'usuario',
        'suscripcion': 'basico',
        'fcm_token': fcmToken,
      };

      await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
        ...baseData,
        'created_at': FieldValue.serverTimestamp(),
      });

      await Supabase.instance.client.from('usuarios').insert({
        'id': userId,
        ...baseData,
        'created_at': nowIso,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInput(_nameController, 'Nombres'),
              _buildInput(_apellidoPaternoController, 'Apellido paterno'),
              _buildInput(_apellidoMaternoController, 'Apellido materno'),
              _buildInput(
                _telefonoController,
                'Teléfono',
                keyboard: TextInputType.phone,
                required: false,
              ),
              _buildInput(
                _fechaNacimientoController,
                'Fecha de nacimiento (YYYY-MM-DD)',
              ),
              _buildInput(
                _emailController,
                'Correo electrónico',
                keyboard: TextInputType.emailAddress,
              ),
              _buildInput(
                _passwordController,
                'Contraseña',
                obscure: true,
                minLen: 6,
              ),
              _buildInput(
                _confirmPasswordController,
                'Confirmar contraseña',
                obscure: true,
                confirm: _passwordController,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Registrar',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    int minLen = 1,
    TextInputType keyboard = TextInputType.text,
    bool required = true,
    TextEditingController? confirm,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          final v = value?.trim() ?? '';
          if (required && v.isEmpty) return 'Campo obligatorio';
          if (minLen > 1 && v.length < minLen)
            return 'Mínimo $minLen caracteres';
          if (confirm != null && v != confirm.text.trim())
            return 'Las contraseñas no coinciden';
          return null;
        },
      ),
    );
  }
}
