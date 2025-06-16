import 'package:flutter/material.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  final List<String> _activities = [
    'Deporte',
    'Arte',
    'Socialización',
    'Lectura',
    'Meditación',
    'Voluntariado',
  ];

  final List<String> _loggedActivities = [];
  final TextEditingController _customActivityController =
      TextEditingController();

  void _addActivity(String activity) {
    if (activity.isEmpty || _loggedActivities.contains(activity)) return;

    setState(() {
      _loggedActivities.add(activity);
    });
  }

  void _submitCustomActivity() {
    final activity = _customActivityController.text.trim();
    if (activity.isNotEmpty) {
      _addActivity(activity);
      _customActivityController.clear();
    }
  }

  @override
  void dispose() {
    _customActivityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Actividades Saludables")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Selecciona o agrega una actividad:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _activities.map((activity) {
                return ElevatedButton(
                  onPressed: () => _addActivity(activity),
                  child: Text(activity),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customActivityController,
                    decoration: const InputDecoration(
                      labelText: "Otra actividad",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _submitCustomActivity,
                  child: const Text("Agregar"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "Actividades registradas hoy:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loggedActivities.isEmpty
                  ? const Center(
                      child: Text("Aún no has registrado actividades."),
                    )
                  : ListView.builder(
                      itemCount: _loggedActivities.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          title: Text(_loggedActivities[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
