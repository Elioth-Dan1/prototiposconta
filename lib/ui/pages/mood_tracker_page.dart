import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodTrackerPage extends StatefulWidget {
  const MoodTrackerPage({super.key});

  @override
  State<MoodTrackerPage> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<MoodTrackerPage> {
  final supabase = Supabase.instance.client;

  final _moods = [
    {'label': 'Feliz', 'emoji': '😄', 'color': Colors.yellow[700]},
    {'label': 'Triste', 'emoji': '😢', 'color': Colors.blue[400]},
    {'label': 'Ansioso', 'emoji': '😰', 'color': Colors.orange[400]},
    {'label': 'Relajado', 'emoji': '😌', 'color': Colors.green[400]},
    {'label': 'Enojado', 'emoji': '😡', 'color': Colors.red[400]},
  ];

  final _slots = [
    {
      'key': 'morning',
      'label': 'Mañana',
      'hour': 8,
      'icon': Icons.wb_sunny_outlined,
      'color': Colors.orangeAccent,
    },
    {
      'key': 'afternoon',
      'label': 'Tarde',
      'hour': 14,
      'icon': Icons.sunny_snowing,
      'color': Colors.blueAccent,
    },
    {
      'key': 'evening',
      'label': 'Noche',
      'hour': 18,
      'icon': Icons.nights_stay_outlined,
      'color': Colors.indigoAccent,
    },
  ];

  List<Map<String, dynamic>> _history = [];
  bool _loadingHistory = true;

  Map<String, String?> _today = {
    'morning': null,
    'afternoon': null,
    'evening': null,
  };

  @override
  void initState() {
    super.initState();
    _loadToday();
    _fetchHistory();
  }

  bool _slotIsAvailable(int hour) => DateTime.now().isAfter(
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour,
    ),
  );

  Future<void> _loadToday() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final res = await supabase
        .from('estado_animo')
        .select('franja, estado')
        .eq('usuario_id', uid)
        .eq('fecha', today);

    final Map<String, String?> map = {
      'morning': null,
      'afternoon': null,
      'evening': null,
    };
    for (final r in res) {
      map[r['franja'] as String] = r['estado'] as String?;
    }
    setState(() => _today = map);
  }

  Future<void> _save(String slot, String estado) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await supabase.from('estado_animo').upsert({
      'usuario_id': uid,
      'fecha': fecha,
      'franja': slot,
      'estado': estado,
    }, onConflict: 'usuario_id,fecha,franja');

    setState(() => _today[slot] = estado);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Estado guardado: $estado')));
    }
  }

  Future<void> _reset(String slot) async => setState(() => _today[slot] = null);

  Future<void> _confirmReset(BuildContext context, String slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Editar estado"),
        content: const Text("¿Seguro que quieres editar tu estado?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sí, editar"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _reset(slot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '¡Buen día!'
        : hour < 18
        ? '¡Buena tarde!'
        : '¡Buena noche!';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi estado de ánimo',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          Text(
            '$greeting\nSelecciona cómo te sientes en cada momento del día.',
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 28),
          ..._slots.map((slot) {
            final key = slot['key'] as String;
            final hour = slot['hour'] as int;
            final estado = _today[key];
            final disponible = _slotIsAvailable(hour);
            if (!disponible && estado == null) return const SizedBox();

            return _MoodCard(
              icon: slot['icon'] as IconData,
              label: slot['label'] as String,
              color: slot['color'] as Color,
              estado: estado,
              moods: _moods,
              onSelect: (e) => _save(key, e),
              onEdit: () => _confirmReset(context, key),
            );
          }).toList(),
          const SizedBox(height: 36),

          if (_loadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isNotEmpty) ...[
            const Text(
              "Historial reciente",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (_, idx) {
                final dia = _history[idx];
                final fecha = DateFormat(
                  'EEE d/MM',
                  'es_ES',
                ).format(DateTime.parse(dia['fecha'] as String));
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        fecha,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.teal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ...["morning", "afternoon", "evening"].map((f) {
                      final est = dia[f] ?? "";
                      final mood = _moods.firstWhere(
                        (m) => m['label'] == est,
                        orElse: () => {},
                      );
                      return est == null || est.isEmpty
                          ? const SizedBox(width: 50)
                          : Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (mood['color'] as Color?)?.withOpacity(
                                      0.09,
                                    ) ??
                                    Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color:
                                      (mood['color'] as Color?)?.withOpacity(
                                        0.18,
                                      ) ??
                                      Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (mood['emoji'] != null)
                                    Text(
                                      mood['emoji'] as String,
                                      style: const TextStyle(fontSize: 19),
                                    ),
                                  const SizedBox(width: 5),
                                  Text(
                                    est,
                                    style: TextStyle(
                                      color:
                                          mood['color'] as Color? ??
                                          Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _fetchHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final start = DateTime.now().subtract(const Duration(days: 8));
    final today = DateTime.now();

    final res = await supabase
        .from('estado_animo')
        .select('fecha, franja, estado')
        .eq('usuario_id', uid)
        .gte('fecha', DateFormat('yyyy-MM-dd').format(start))
        .lte('fecha', DateFormat('yyyy-MM-dd').format(today))
        .order('fecha', ascending: false);

    // Agrupa por fecha y pone una lista por franja
    final Map<String, Map<String, String>> map = {};
    for (final r in res) {
      final f = r['fecha'] as String;
      final fr = r['franja'] as String;
      final est = r['estado'] as String? ?? "";
      map.putIfAbsent(f, () => {});
      map[f]![fr] = est;
    }

    _history = map.entries.map((e) => {"fecha": e.key, ...e.value}).toList();

    setState(() {
      _loadingHistory = false;
    });
  }
}

/* ─── Modern Card ─── */
class _MoodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? estado;
  final List<Map<String, Object?>> moods;
  final ValueChanged<String> onSelect;
  final VoidCallback onEdit;

  const _MoodCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.estado,
    required this.moods,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.09),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.15), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (estado == null) ...[
                // Selector de emociones
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: moods.map((m) {
                    final emoji = m['emoji']! as String;
                    final txt = m['label']! as String;
                    final emColor = m['color'] as Color?;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            emColor?.withOpacity(0.14) ?? Colors.grey[200],
                        foregroundColor: emColor ?? Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => onSelect(txt),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            txt,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: emColor ?? Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                // Estado ya guardado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '$estado',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(foregroundColor: color),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
