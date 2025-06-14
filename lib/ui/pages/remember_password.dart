import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RememberPassword extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RememberPasswordState();
}

class RememberPasswordState extends State<RememberPassword> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  bool _isLoading = false;
  String _feedbackMessage = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _feedbackMessage = '';
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      setState(() {
        _feedbackMessage =
            'Si el correo está registrado, recibirás un enlace para restablecer la contraseña.'; // Mensaje genérico por seguridad :contentReference[oaicite:0]{index=0}
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'invalid-email') {
        msg = 'El correo no es válido';
      } else {
        msg = 'Ocurrió un error: ${e.message}';
      }
      setState(() {
        _feedbackMessage = msg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olvidé mi contraseña'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.asset('assets/login.jpg', width: 150, height: 150),
            const SizedBox(height: 16),
            const Text(
              'Reiniciar contraseña',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Correo electrónico *',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un correo';
                  }
                  final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!pattern.hasMatch(value.trim())) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enviar enlace de restablecimiento'),
            ),

            const SizedBox(height: 16),
            if (_feedbackMessage.isNotEmpty)
              Text(
                _feedbackMessage,
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 24),
            const Text(
              'Recuerda no difundir tus credenciales y cambiar tu contraseña periódicamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
