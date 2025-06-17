import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class DaysCounterPage extends StatefulWidget {
  const DaysCounterPage({super.key});

  @override
  State<DaysCounterPage> createState() => _DaysCounterPageState();
}

class _DaysCounterPageState extends State<DaysCounterPage> {
  final supabase = Supabase.instance.client;
  String? _usuarioId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _fechaRegistro;
  Map<DateTime, bool> _historialConsumo = {};
  bool? _consumoHoy;
  int _rachaActual = 0;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usuario = await supabase
        .from('usuarios')
        .select('created_at')
        .eq('id', user.uid)
        .maybeSingle();

    if (usuario == null) return;

    setState(() {
      _usuarioId = user.uid;
      _fechaRegistro = DateTime.parse(usuario['created_at']);
    });

    await _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    if (_usuarioId == null) return;

    final response = await supabase
        .from('registro_consumo')
        .select('fecha, consumo')
        .eq('usuario_id', _usuarioId!);

    final Map<DateTime, bool> historial = {};
    for (var item in response) {
      final fecha = DateTime.parse(item['fecha']).toLocal();
      final cleanDate = DateTime(fecha.year, fecha.month, fecha.day);
      historial[cleanDate] = item['consumo'];
    }

    final hoy = DateTime.now();
    final hoyClean = DateTime(hoy.year, hoy.month, hoy.day);

    setState(() {
      _historialConsumo = historial;
      _consumoHoy = historial[hoyClean];
      _rachaActual = _calcularRacha(historial);
    });
  }

  int _calcularRacha(Map<DateTime, bool> historial) {
    int racha = 0;
    DateTime hoy = DateTime.now();

    while (true) {
      final dia = DateTime(
        hoy.year,
        hoy.month,
        hoy.day,
      ).subtract(Duration(days: racha));
      if (historial.containsKey(dia)) {
        if (historial[dia] == false) {
          racha++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return racha;
  }

  Future<void> _registrarConsumo(bool consumio) async {
    if (_usuarioId == null) return;

    final hoy = DateTime.now();
    final fechaString = DateFormat('yyyy-MM-dd').format(hoy);

    final existing = await supabase
        .from('registro_consumo')
        .select()
        .eq(
          'usuario_id',
          _usuarioId!,
        ) // 👈 Aquí usamos ! porque ya validamos que no es null
        .eq('fecha', fechaString)
        .maybeSingle();

    if (existing == null) {
      // Si no existe, inserta
      await supabase.from('registro_consumo').insert({
        'usuario_id': _usuarioId!,
        'fecha': fechaString,
        'consumo': consumio,
      });
    } else {
      // Si existe, actualiza
      await supabase
          .from('registro_consumo')
          .update({'consumo': consumio})
          .eq('usuario_id', _usuarioId!) // 👈 Aquí también
          .eq('fecha', fechaString);
    }

    await _cargarHistorial();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          consumio
              ? "Registro guardado: Hoy consumiste."
              : "¡Muy bien! Hoy no consumiste.",
        ),
      ),
    );
  }

  Color? _getDayColor(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    if (_historialConsumo.containsKey(normalized)) {
      return _historialConsumo[normalized]!
          ? Colors.red[300]
          : Colors.green[400];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final diasDesdeInicio = _fechaRegistro != null
        ? hoy.difference(_fechaRegistro!).inDays
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Contador de Días sin Consumo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: _fechaRegistro ?? DateTime(2023),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, DateTime.now()),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final color = _getDayColor(day);
                  if (color != null) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  return null;
                },
              ),
              onDaySelected: (_, __) {},
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Días desde tu inicio: $diasDesdeInicio"),
            const SizedBox(height: 10),
            Text(
              "🔥 Racha actual sin consumo: $_rachaActual días",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (_consumoHoy == null) ...[
              const Text("¿Hoy consumiste?", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _registrarConsumo(true),
                    icon: const Icon(Icons.warning),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    label: const Text("Sí consumí"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _registrarConsumo(false),
                    icon: const Icon(Icons.check_circle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    label: const Text("No consumí"),
                  ),
                ],
              ),
            ] else ...[
              Card(
                color: _consumoHoy! ? Colors.red[50] : Colors.green[50],
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _consumoHoy! ? Icons.warning : Icons.check_circle,
                        color: _consumoHoy! ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _consumoHoy!
                              ? "Hoy consumiste. No pasa nada, lo importante es levantarte y seguir. ¡Puedes hacerlo!"
                              : "¡Felicidades! Hoy no consumiste. Cada día cuenta, sigue así.",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Editar respuesta"),
                        content: const Text(
                          "¿Estás seguro de que deseas cambiar tu respuesta de hoy?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Sí, editar"),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      setState(() {
                        _consumoHoy = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Editar respuesta"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
