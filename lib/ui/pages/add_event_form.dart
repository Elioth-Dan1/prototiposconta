import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddEventForm extends StatefulWidget {
  const AddEventForm({super.key});

  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _imagenController = TextEditingController();
  String _tipoSuscripcion = 'básico';
  DateTime? _fechaSeleccionada;
  String? _imagenPreview;

  Future<void> _selectFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaSeleccionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una fecha')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
      return;
    }

    final data = {
      'titulo': _tituloController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'imagen': _imagenController.text.trim(),
      'tipo_suscripcion': _tipoSuscripcion,
      'fecha': _fechaSeleccionada!.toIso8601String(),
      'usuario_id': user.uid,
    };

    final response = await Supabase.instance.client
        .from('eventos')
        .insert(data)
        .select();

    if (response.isEmpty) {
      debugPrint("❌ Error al crear evento");
    } else {
      debugPrint("✅ Evento creado: $response");
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Evento creado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Nuevo Evento",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _imagenController,
                decoration: const InputDecoration(
                  labelText: 'URL de imagen (opcional)',
                ),
                onChanged: (value) {
                  setState(() {
                    _imagenPreview = value.trim().isNotEmpty
                        ? value.trim()
                        : null;
                  });
                },
              ),
              const SizedBox(height: 8),
              if (_imagenPreview != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _imagenPreview!,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Text('No se pudo cargar la imagen'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _tipoSuscripcion,
                items: ['básico', 'premium']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _tipoSuscripcion = value!),
                decoration: const InputDecoration(labelText: 'Suscripción'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _fechaSeleccionada == null
                          ? 'Selecciona una fecha'
                          : 'Fecha: ${DateFormat.yMMMMd('es_ES').format(_fechaSeleccionada!)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: () => _selectFecha(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Guardar evento"),
                onPressed: _guardarEvento,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
