import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditEventForm extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> existingData;

  const EditEventForm({
    super.key,
    required this.eventId,
    required this.existingData,
  });

  @override
  State<EditEventForm> createState() => _EditEventFormState();
}

class _EditEventFormState extends State<EditEventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  late TextEditingController _imagenController;
  late String _tipoSuscripcion;
  DateTime? _fechaSeleccionada;
  String? _imagenPreview;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(
      text: widget.existingData['titulo'],
    );
    _descripcionController = TextEditingController(
      text: widget.existingData['descripcion'],
    );
    _imagenController = TextEditingController(
      text: widget.existingData['imagen'],
    );
    _tipoSuscripcion = widget.existingData['tipo_suscripcion'] ?? 'básico';

    final fechaStr = widget.existingData['fecha'];
    _fechaSeleccionada = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
    _imagenPreview = _imagenController.text.trim().isNotEmpty
        ? _imagenController.text.trim()
        : null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = _fechaSeleccionada != null
        ? DateFormat.yMMMMd('es_ES').format(_fechaSeleccionada!)
        : 'No seleccionada';

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
                "Editar Evento",
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
                decoration: const InputDecoration(labelText: 'URL de imagen'),
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
              const SizedBox(height: 10),
              Row(
                children: [
                  Text("Fecha: $fechaFormateada"),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Guardar cambios"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await Supabase.instance.client
                        .from('eventos')
                        .update({
                          'titulo': _tituloController.text.trim(),
                          'descripcion': _descripcionController.text.trim(),
                          'imagen': _imagenController.text.trim(),
                          'tipo_suscripcion': _tipoSuscripcion,
                          'fecha': _fechaSeleccionada?.toIso8601String(),
                        })
                        .eq('id', widget.eventId);

                    if (mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Evento actualizado")),
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
