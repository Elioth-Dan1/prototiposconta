// lib/ui/pages/mood_tracker_page.dart
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

  /* ─── Catálogo de emociones ─── */
  final _moods = [
    {'label': 'Feliz', 'emoji': '😄', 'color': Colors.yellow},
    {'label': 'Triste', 'emoji': '😢', 'color': Colors.blue},
    {'label': 'Ansioso', 'emoji': '😰', 'color': Colors.orange},
    {'label': 'Relajado', 'emoji': '😌', 'color': Colors.green},
    {'label': 'Enojado', 'emoji': '😡', 'color': Colors.red},
  ];

  /* ─── Franjas ─── */
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

  Map<String, String?> _today = {
    'morning': null,
    'afternoon': null,
    'evening': null,
  };

  @override
  void initState() {
    super.initState();
    _loadToday();
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

  /* ─── UI ─── */
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '¡Buen día!'
        : hour < 18
        ? '¡Buena tarde!'
        : '¡Buena noche!';

    return Scaffold(
      backgroundColor: Colors.white, // ⬅️ fondo blanco
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mi estado de ánimo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 24),
        children: [
          Text(
            '$greeting\nSelecciona cómo te sientes en cada momento del día.',
            style: const TextStyle(fontSize: 18, color: Colors.black),
          ),
          const SizedBox(height: 24),

          /* ─── Tarjetas de franja ─── */
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
              onEdit: () => _reset(key),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/* ─── Card ─── */
class _MoodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? estado;
  final List<Map<String, Object>> moods;
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
      padding: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 10),
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
                  /* Selector */
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: moods.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2,
                        ),
                    itemBuilder: (_, i) {
                      final m = moods[i];
                      final emoji = m['emoji']! as String;
                      final txt = m['label']! as String;
                      return GestureDetector(
                        onTap: () => onSelect(txt),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                txt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  /* Estado ya guardado */
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
                          estado!,
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
      ),
    );
  }
}
