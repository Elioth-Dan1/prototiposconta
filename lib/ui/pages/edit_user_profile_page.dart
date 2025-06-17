import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUserProfilePage extends StatefulWidget {
  const EditUserProfilePage({super.key});

  @override
  State<EditUserProfilePage> createState() => _EditUserProfilePageState();
}

class _EditUserProfilePageState extends State<EditUserProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('id', user.uid)
        .maybeSingle();

    if (response != null) {
      setState(() {
        _nameController.text = response['nombres'] ?? '';
        _apellidoPaternoController.text = response['apellido_paterno'] ?? '';
        _apellidoMaternoController.text = response['apellido_materno'] ?? '';
        _telefonoController.text = response['telefono'] ?? '';
        _fechaNacimientoController.text = response['fecha_nacimiento'] ?? '';
        _selectedDate = DateTime.tryParse(response['fecha_nacimiento'] ?? '');
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('usuarios')
        .update({
          'nombres': _nameController.text.trim(),
          'apellido_paterno': _apellidoPaternoController.text.trim(),
          'apellido_materno': _apellidoMaternoController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'fecha_nacimiento': _fechaNacimientoController.text.trim(),
        })
        .eq('id', user.uid);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _fechaNacimientoController.text = DateFormat(
          'yyyy-MM-dd',
        ).format(pickedDate);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _telefonoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombres'),
                    validator: (value) =>
                        value!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _apellidoPaternoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido paterno',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _apellidoMaternoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido materno',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _fechaNacimientoController,
                    readOnly: true,
                    onTap: _seleccionarFechaNacimiento,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de nacimiento',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
