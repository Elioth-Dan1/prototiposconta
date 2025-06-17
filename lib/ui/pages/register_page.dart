import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

      // Datos para Firestore
      final firestoreData = {
        'nombres': _nameController.text.trim(),
        'apellido_paterno': _apellidoPaternoController.text.trim(),
        'apellido_materno': _apellidoMaternoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'fecha_nacimiento': fechaNacStr,
        'email': _emailController.text.trim(),
        'rol': 'usuario',
        'suscripcion': 'basico',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Guardar en Firebase Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .set(firestoreData);

      // Datos para Supabase
      final supabaseData = {
        'id': userId,
        'nombres': firestoreData['nombres'],
        'apellido_paterno': firestoreData['apellido_paterno'],
        'apellido_materno': firestoreData['apellido_materno'],
        'telefono': firestoreData['telefono'],
        'fecha_nacimiento': fechaNacimiento.toIso8601String(),
        'email': firestoreData['email'],
        'rol': 'usuario',
        'suscripcion': 'basico',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insertar en Supabase
      final response = await Supabase.instance.client
          .from('usuarios')
          .insert(supabaseData)
          .select(); // obligatorio para recibir el resultado

      if (response == null || response.isEmpty) {
        debugPrint("❌ No se insertó en Supabase");
      } else {
        debugPrint("✅ Usuario registrado en Supabase: $response");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: _apellidoPaternoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido paterno',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: _apellidoMaternoController,
                  decoration: const InputDecoration(
                    labelText: 'Apellido materno',
                  ),
                ),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _fechaNacimientoController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento (YYYY-MM-DD)',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: (value) =>
                      value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: 20),
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
}
