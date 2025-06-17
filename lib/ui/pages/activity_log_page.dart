import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

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

  final TextEditingController _customActivityController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _loggedActivitiesForDate = [];
  String? _mostFrequentActivity;

  @override
  void initState() {
    super.initState();
    _loadActivitiesForDate(_selectedDate);
    _loadMostFrequentActivity();
  }

  Future<void> _loadActivitiesForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await Supabase.instance.client
        .from('actividades')
        .select()
        .eq('usuario_id', user.uid)
        .eq('fecha', formattedDate);

    setState(() {
      _loggedActivitiesForDate = List<Map<String, dynamic>>.from(
        response as List,
      );
    });
  }

  Future<void> _loadMostFrequentActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client.rpc(
      'get_most_frequent_activity',
      params: {'uid': user.uid},
    );

    if (response != null && response is String) {
      setState(() {
        _mostFrequentActivity = response;
      });
    }
  }

  Future<void> _addActivity(String activity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || activity.isEmpty) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final response = await Supabase.instance.client.from('actividades').insert({
      'usuario_id': user.uid,
      'actividad': activity,
      'fecha': formattedDate,
    }).select();

    if (response != null) {
      await _loadActivitiesForDate(_selectedDate);
      await _loadMostFrequentActivity();
    }
  }

  Future<void> _deleteActivity(String activity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    await Supabase.instance.client
        .from('actividades')
        .delete()
        .eq('usuario_id', user.uid)
        .eq('actividad', activity)
        .eq('fecha', formattedDate);

    await _loadActivitiesForDate(_selectedDate);
    await _loadMostFrequentActivity();
  }

  void _submitCustomActivity() {
    final activity = _customActivityController.text.trim();
    if (activity.isNotEmpty &&
        !_loggedActivitiesForDate.any(
          (element) => element['actividad'] == activity,
        )) {
      _addActivity(activity);
      _customActivityController.clear();
    }
  }

  bool _isTodaySelected() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2023),
              lastDay: DateTime(2100),
              focusedDay: _selectedDate,
              locale: 'es_ES',
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, _) {
                setState(() {
                  _selectedDate = selectedDay;
                });
                _loadActivitiesForDate(selectedDay);
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Selecciona o agrega una actividad:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: _activities.map((activity) {
                return ElevatedButton(
                  onPressed: () {
                    if (!_loggedActivitiesForDate.any(
                      (e) => e['actividad'] == activity,
                    )) {
                      _addActivity(activity);
                    }
                  },
                  child: Text(activity),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
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
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitCustomActivity,
                  child: const Text("Agregar"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Actividades para el ${DateFormat.yMMMMd('es_ES').format(_selectedDate)}:",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            _loggedActivitiesForDate.isEmpty
                ? const Text("No hay actividades registradas.")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _loggedActivitiesForDate.length,
                    itemBuilder: (context, index) {
                      final activity =
                          _loggedActivitiesForDate[index]['actividad'];
                      return ListTile(
                        leading: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        title: Text(activity),
                        trailing: _isTodaySelected()
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteActivity(activity),
                              )
                            : null,
                      );
                    },
                  ),
            const SizedBox(height: 12),
            if (_mostFrequentActivity != null)
              Text(
                "Actividad más frecuente: $_mostFrequentActivity",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}
