import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_event_form.dart';
import 'edit_event_form.dart';

class AdminEventPage extends StatefulWidget {
  const AdminEventPage({super.key});

  @override
  State<AdminEventPage> createState() => _AdminEventPageState();
}

class _AdminEventPageState extends State<AdminEventPage> {
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _eventosFiltrados = [];

  String _searchQuery = '';
  String _filtroSuscripcion = 'todos';
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    final response = await Supabase.instance.client
        .from('eventos')
        .select('*, usuarios(nombres)')
        .order('created_at', ascending: false);

    setState(() {
      _eventos = List<Map<String, dynamic>>.from(response);
      _aplicarFiltros();
    });
  }

  void _aplicarFiltros() {
    setState(() {
      _eventosFiltrados = _eventos.where((evento) {
        final titulo = evento['titulo']?.toString().toLowerCase() ?? '';
        final descripcion =
            evento['descripcion']?.toString().toLowerCase() ?? '';
        final tipo = evento['tipo_suscripcion']?.toString().toLowerCase() ?? '';
        final estado = evento['estado']?.toString().toLowerCase() ?? '';

        final coincideBusqueda =
            titulo.contains(_searchQuery) || descripcion.contains(_searchQuery);

        final coincideSuscripcion =
            _filtroSuscripcion == 'todos' || tipo == _filtroSuscripcion;

        final coincideEstado =
            _filtroEstado == 'todos' || estado == _filtroEstado;

        return coincideBusqueda && coincideSuscripcion && coincideEstado;
      }).toList();
    });
  }

  Widget _chipEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'cancelado':
        return const Chip(
          label: Text('Cancelado'),
          backgroundColor: Colors.redAccent,
          avatar: Icon(Icons.cancel, color: Colors.white),
          labelStyle: TextStyle(color: Colors.white),
        );
      case 'finalizado':
        return const Chip(
          label: Text('Finalizado'),
          backgroundColor: Colors.green,
          avatar: Icon(Icons.check_circle, color: Colors.white),
          labelStyle: TextStyle(color: Colors.white),
        );
      default:
        return const Chip(
          label: Text('Activo'),
          backgroundColor: Colors.blueAccent,
          avatar: Icon(Icons.check, color: Colors.white),
          labelStyle: TextStyle(color: Colors.white),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de eventos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por título o descripción',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _searchQuery = value.toLowerCase();
                    _aplicarFiltros();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroSuscripcion,
                        items: const [
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todas'),
                          ),
                          DropdownMenuItem(
                            value: 'básico',
                            child: Text('Básico'),
                          ),
                          DropdownMenuItem(
                            value: 'premium',
                            child: Text('Premium'),
                          ),
                        ],
                        onChanged: (value) {
                          _filtroSuscripcion = value!;
                          _aplicarFiltros();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Suscripción',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        items: const [
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'activo',
                            child: Text('Activo'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelado',
                            child: Text('Cancelado'),
                          ),
                          DropdownMenuItem(
                            value: 'finalizado',
                            child: Text('Finalizado'),
                          ),
                        ],
                        onChanged: (value) {
                          _filtroEstado = value!;
                          _aplicarFiltros();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _eventosFiltrados.isEmpty
                ? const Center(child: Text('No hay eventos que coincidan.'))
                : ListView.builder(
                    itemCount: _eventosFiltrados.length,
                    itemBuilder: (context, index) {
                      final evento = _eventosFiltrados[index];
                      final creador = evento['usuarios'];
                      final id = evento['id'];
                      final fechaEvento =
                          DateTime.tryParse(evento['fecha'] ?? '') ??
                          DateTime.now();
                      final esPasado = fechaEvento.isBefore(DateTime.now());
                      final estado = (evento['estado'] ?? 'activo')
                          .toLowerCase();

                      final cardColor = esPasado
                          ? Colors.grey[100]
                          : (estado == 'cancelado'
                                ? Colors.red[50]
                                : Colors.white);

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (evento['imagen'] != null &&
                                      evento['imagen'].toString().isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        evento['imagen'],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.event,
                                      size: 70,
                                      color: Colors.grey,
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          evento['titulo'] ?? 'Sin título',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          evento['descripcion'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Por: ${creador?['nombres'] ?? 'Desconocido'}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    label: Text(
                                      'Suscripción: ${evento['tipo_suscripcion']}',
                                    ),
                                  ),
                                  if (evento['modalidad'] != null)
                                    Chip(
                                      label: Text(
                                        'Modalidad: ${evento['modalidad']}',
                                      ),
                                    ),
                                  _chipEstado(evento['estado'] ?? 'activo'),
                                  Chip(
                                    avatar: Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: esPasado
                                          ? Colors.red
                                          : Colors.blue,
                                    ),
                                    label: Text(
                                      DateFormat.yMMMd(
                                        'es_ES',
                                      ).format(fechaEvento),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (context) => EditEventForm(
                                          eventId: id,
                                          existingData: evento,
                                        ),
                                      ).then((_) => _cargarEventos());
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text(
                                            '¿Eliminar evento?',
                                          ),
                                          content: const Text(
                                            'Esta acción no se puede deshacer.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await Supabase.instance.client
                                            .from('eventos')
                                            .delete()
                                            .eq('id', id);
                                        if (mounted) {
                                          _cargarEventos();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Evento eliminado"),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => const Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
            child: AddEventForm(),
          ),
        ).then((_) => _cargarEventos()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
