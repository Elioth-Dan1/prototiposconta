// archivo: event_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, dynamic> evento;

  const EventDetailPage({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.tryParse(evento['fecha'] ?? '');
    final fechaTexto = fecha != null
        ? DateFormat('dd MMMM yyyy', 'es_ES').format(fecha)
        : 'Sin fecha';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Image.network(
                  evento['imagen'] ?? '',
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 260,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map),
                  label: const Text('Mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento['titulo'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(fechaTexto),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const Text(" 4.5"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _detalleChip(Icons.access_time, evento['duracion']),
                        _detalleChip(Icons.people, evento['modalidad']),
                        _detalleChip(Icons.vpn_key, evento['tipo_suscripcion']),
                        _detalleChip(Icons.flag, evento['estado']),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      evento['descripcion'] ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Divider(height: 30),
                    _infoDetalle("🎤 Ponente(s)", evento['ponentes']),
                    _infoDetalle(
                      "📍 Lugar / Enlace",
                      evento['lugar'],
                      isLink: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detalleChip(IconData icon, String? texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.teal),
          const SizedBox(width: 4),
          Text(texto ?? "-", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _infoDetalle(String label, String? contenido, {bool isLink = false}) {
    if (contenido == null || contenido.trim().isEmpty) {
      contenido = '-';
    }
    final isUrl =
        isLink && (contenido.startsWith('http') || contenido.startsWith('www'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          isUrl
              ? InkWell(
                  onTap: () => launchUrl(Uri.parse(contenido!)),
                  child: Text(
                    contenido,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  contenido ?? '-',
                  style: const TextStyle(color: Colors.black87),
                ),
        ],
      ),
    );
  }
}
