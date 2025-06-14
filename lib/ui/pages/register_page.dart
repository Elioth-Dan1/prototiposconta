import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formRegisterKey = GlobalKey<FormState>();

  late TextEditingController _nombresController;
  late TextEditingController _paternoController;
  late TextEditingController _maternoController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmationController;
  late TextEditingController _nacimientoController;

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController();
    _paternoController = TextEditingController();
    _maternoController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmationController = TextEditingController();
    _nacimientoController = TextEditingController();
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _paternoController.dispose();
    _maternoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    _nacimientoController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmail() async {
    if (!_formRegisterKey.currentState!.validate()) return;

    try {
      // 1️⃣ Crear usuario en Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // 2️⃣ Guardar datos adicionales en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set({
            'nombres': _nombresController.text.trim(),
            'apellidoPaterno': _paternoController.text.trim(),
            'apellidoMaterno': _maternoController.text.trim(),
            'fechaNacimiento': _nacimientoController.text.trim(),
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );
      Navigator.pop(context); // Volver a la pantalla anterior
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
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/login.jpg', width: 150, height: 150),
            const SizedBox(height: 16),
            Form(
              key: _formRegisterKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombresController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      label: Text('Nombres *'),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El campo nombres es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _paternoController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            label: Text('Ap. paterno *'),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El campo apellido paterno es obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _maternoController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                            label: Text('Ap. materno'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Email *'),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El campo email es obligatorio';
                      }
                      final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailPattern.hasMatch(value.trim())) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Password *'),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El campo password es obligatorio';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmationController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      label: Text('Confirmación Password *'),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nacimientoController,
                    decoration: const InputDecoration(
                      suffixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(),
                      label: Text('Fecha de nacimiento'),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _registerWithEmail,
                      child: const Text('Crear cuenta'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
