// archivo: admin_users_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchUsuarios();
  }

  Future<void> _fetchUsuarios() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client.from('usuarios').select();
    setState(() {
      _usuarios = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _crearUsuario(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nombresController = TextEditingController();
    final apPaternoController = TextEditingController();
    final apMaternoController = TextEditingController();
    final telefonoController = TextEditingController();
    final fechaNacimientoController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String rol = 'usuario';
    String suscripcion = 'basico';

    showDialog(
      context: context,
      builder: (ctx) {
        final screenSize = MediaQuery.of(ctx).size;

        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: screenSize.width * 0.9,
            height: screenSize.height * 0.85,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Nuevo usuario',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            _input(nombresController, 'Nombres'),
                            _input(apPaternoController, 'Apellido paterno'),
                            _input(apMaternoController, 'Apellido materno'),
                            _input(
                              telefonoController,
                              'Teléfono',
                              keyboard: TextInputType.phone,
                              required: false,
                            ),
                            _inputDatePicker(
                              fechaNacimientoController,
                              'Fecha de nacimiento',
                            ),
                            _input(
                              emailController,
                              'Correo electrónico',
                              keyboard: TextInputType.emailAddress,
                            ),
                            _input(
                              passwordController,
                              'Contraseña',
                              obscure: true,
                              minLen: 6,
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Rol',
                                border: OutlineInputBorder(),
                              ),
                              value: rol,
                              items: ['usuario', 'admin', 'psicologo']
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => rol = value!),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Suscripción',
                                border: OutlineInputBorder(),
                              ),
                              value: suscripcion,
                              items: ['basico', 'premium']
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => suscripcion = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final fecha = DateTime.tryParse(
                            fechaNacimientoController.text.trim(),
                          );
                          if (fecha == null) return;
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          try {
                            final cred = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                                  email: email,
                                  password: password,
                                );

                            final nowIso = DateTime.now().toIso8601String();
                            final userId = cred.user!.uid;
                            final data = {
                              'id': userId,
                              'nombres': nombresController.text.trim(),
                              'apellido_paterno': apPaternoController.text
                                  .trim(),
                              'apellido_materno': apMaternoController.text
                                  .trim(),
                              'telefono': telefonoController.text.trim(),
                              'fecha_nacimiento': fecha.toIso8601String(),
                              'email': email,
                              'rol': rol,
                              'suscripcion': suscripcion,
                              'created_at': nowIso,
                            };

                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(userId)
                                .set(data);
                            await Supabase.instance.client
                                .from('usuarios')
                                .insert(data);

                            if (!mounted) return;
                            Navigator.of(ctx).pop();
                            _fetchUsuarios();
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editarUsuario(Map<String, dynamic> usuario) async {
    final nombres = TextEditingController(text: usuario['nombres'] ?? '');
    String rol = usuario['rol'] ?? 'usuario';
    String suscripcion = usuario['suscripcion'] ?? 'basico';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _input(nombres, 'Nombres'),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Rol'),
              value: rol,
              items: [
                'usuario',
                'admin',
                'psicologo',
              ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (value) => setState(() => rol = value!),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Suscripción'),
              value: suscripcion,
              items: [
                'basico',
                'premium',
                'familiar',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) => setState(() => suscripcion = value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client
                  .from('usuarios')
                  .update({
                    'nombres': nombres.text.trim(),
                    'rol': rol,
                    'suscripcion': suscripcion,
                  })
                  .eq('id', usuario['id']);
              if (!mounted) return;
              Navigator.of(ctx).pop();
              _fetchUsuarios();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    int minLen = 1,
    TextInputType keyboard = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          final val = v?.trim() ?? '';
          if (required && val.isEmpty) return 'Campo obligatorio';
          if (minLen > 1 && val.length < minLen)
            return 'Mínimo $minLen caracteres';
          return null;
        },
      ),
    );
  }

  Widget _inputDatePicker(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            helpText: 'Selecciona la fecha de nacimiento',
            locale: const Locale('es'),
          );
          if (pickedDate != null) {
            controller.text = pickedDate.toIso8601String().split('T').first;
          }
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Campo obligatorio';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _crearUsuario(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _usuarios.length,
              itemBuilder: (ctx, i) {
                final u = _usuarios[i];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(u['nombres'] ?? ''),
                  subtitle: Text(
                    '${u['email']}\nRol: ${u['rol']} | Sub: ${u['suscripcion']}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editarUsuario(u),
                  ),
                );
              },
            ),
    );
  }
}
