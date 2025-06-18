import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  /* ───────────────────────── Registro ───────────────────────── */
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      /* 1. Crear usuario en Firebase Auth */
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userId = userCredential.user!.uid;

      /* 2. Parsear fecha de nacimiento */
      final fechaNacStr = _fechaNacimientoController.text.trim();
      final fechaNacimiento = DateTime.tryParse(fechaNacStr);
      if (fechaNacimiento == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de nacimiento inválida')),
        );
        return;
      }

      /* 3. Obtener token FCM (puede tardar) */
      String? fcmToken;
      try {
        await FirebaseMessaging.instance.requestPermission();
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {
        // Si falla, lo dejamos nulo y lo solicitaremos luego en el Login
        fcmToken = null;
      }

      /* 4. Datos comunes */
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

      /* 5. Guardar en Firebase Firestore */
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .set({...baseData, 'created_at': FieldValue.serverTimestamp()});

      /* 6. Guardar en Supabase */
      await Supabase.instance.client.from('usuarios').insert({
        'id': userId,
        ...baseData,
        'created_at': nowIso,
      });

      if (!mounted) return;

      /* 7. Mensaje de éxito y volver */
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    }
  }

  /* ──────────────────────── UI (Formulario) ─────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildText(_nameController, 'Nombres'),
                _buildText(_apellidoPaternoController, 'Apellido paterno'),
                _buildText(_apellidoMaternoController, 'Apellido materno'),
                _buildText(_telefonoController, 'Teléfono',
                    keyboard: TextInputType.phone, required: false),
                _buildText(_fechaNacimientoController,
                    'Fecha de nacimiento (YYYY-MM-DD)'),
                _buildText(_emailController, 'Correo electrónico',
                    keyboard: TextInputType.emailAddress),
                _buildText(_passwordController, 'Contraseña',
                    obscure: true, minLen: 6),
                _buildText(_confirmPasswordController, 'Confirmar contraseña',
                    obscure: true, confirm: _passwordController),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _register,
                  child: const Text('Registrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ───────────── Helper para input con validaciones simples ───────────── */
  Widget _buildText(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    int minLen = 1,
    TextInputType keyboard = TextInputType.text,
    bool required = true,
    TextEditingController? confirm,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (required && v.isEmpty) return 'Campo obligatorio';
        if (minLen > 1 && v.length < minLen) {
          return 'Mínimo $minLen caracteres';
        }
        if (confirm != null && v != confirm.text.trim()) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }
}
