import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_event_form.dart';
import 'edit_event_form.dart';

class AdminEventPage extends StatefulWidget {
  const AdminEventPage({super.key});

  @override
  State<AdminEventPage> createState() => _AdminEventPageState();
}

class _AdminEventPageState extends State<AdminEventPage> {
  Future<List<Map<String, dynamic>>> _fetchEventos() async {
    final response = await Supabase.instance.client
        .from('eventos')
        .select('*, usuarios(nombres)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de eventos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchEventos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay eventos disponibles.'));
          }

          final eventos = snapshot.data!;

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              final creador = evento['usuarios'];
              final id = evento['id'];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading:
                      evento['imagen'] != null &&
                          evento['imagen'].toString().isNotEmpty
                      ? Image.network(
                          evento['imagen'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.event),
                  title: Text(evento['titulo'] ?? 'Sin título'),
                  subtitle: Text(
                    '${evento['descripcion'] ?? ''}\nCreado por: ${creador != null ? creador['nombres'] : 'Desconocido'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
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
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await Supabase.instance.client
                              .from('eventos')
                              .delete()
                              .eq('id', id);
                          if (mounted) {
                            setState(() {}); // refresca la lista
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Evento eliminado")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
        ).then((_) => setState(() {})),
        child: const Icon(Icons.add),
      ),
    );
  }
}
