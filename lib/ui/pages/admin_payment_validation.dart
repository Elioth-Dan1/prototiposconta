// archivo: admin_pending_payments_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPendingPaymentsPage extends StatefulWidget {
  const AdminPendingPaymentsPage({super.key});

  @override
  State<AdminPendingPaymentsPage> createState() =>
      _AdminPendingPaymentsPageState();
}

class _AdminPendingPaymentsPageState extends State<AdminPendingPaymentsPage> {
  List<Map<String, dynamic>> _pendientes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendientes();
  }

  Future<void> _fetchPendientes() async {
    setState(() => _loading = true);
    final data = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('estado_pago', 'pendiente');

    setState(() {
      _pendientes = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _aprobarPago(String userId) async {
    await Supabase.instance.client
        .from('usuarios')
        .update({'suscripcion': 'premium', 'estado_pago': 'aprobado'})
        .eq('id', userId);
    _fetchPendientes();
  }

  Future<void> _rechazarPago(String userId) async {
    await Supabase.instance.client
        .from('usuarios')
        .update({'estado_pago': 'rechazado'})
        .eq('id', userId);
    _fetchPendientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos Pendientes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendientes.isEmpty
          ? const Center(child: Text('No hay pagos pendientes'))
          : ListView.builder(
              itemCount: _pendientes.length,
              itemBuilder: (ctx, i) {
                final user = _pendientes[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(user['nombres'] ?? ''),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _aprobarPago(user['id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rechazarPago(user['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
