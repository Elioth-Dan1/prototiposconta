// admin_event_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'add_event_form.dart';
import 'edit_event_form.dart';

class AdminEventPage extends StatelessWidget {
  const AdminEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de eventos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final evento = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

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
                  subtitle: Text(evento['descripcion'] ?? ''),
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
                              existingData:
                                  evento, // ← este es el nombre correcto
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('eventos')
                              .doc(id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Evento eliminado")),
                          );
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
          builder: (context) => Material(
            child: Localizations.override(
              context: context,
              locale: const Locale('es'), // o 'en' según el idioma que uses
              child: const Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 32,
                ),
                child: AddEventForm(),
              ),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
