import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  Future<void> _selectFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es'), // <-- importante para español
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
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
              ),
              DropdownButtonFormField<String>(
                value: _tipoSuscripcion,
                items: ['básico', 'premium', 'familiar']
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
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_fechaSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona una fecha')),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance.collection('eventos').add({
                      'titulo': _tituloController.text.trim(),
                      'descripcion': _descripcionController.text.trim(),
                      'imagenUrl': _imagenController.text.trim(),
                      'tipoSuscripcion': _tipoSuscripcion,
                      'fecha': Timestamp.fromDate(_fechaSeleccionada!),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Evento creado")),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
