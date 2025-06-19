import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentQRPage extends StatefulWidget {
  const PaymentQRPage({super.key});

  @override
  State<PaymentQRPage> createState() => _PaymentQRPageState();
}

class _PaymentQRPageState extends State<PaymentQRPage> {
  bool _loading = false;
  bool _successSent = false;

  String? _estadoPago;

  @override
  void initState() {
    super.initState();
    _verificarEstadoPago();
  }

  Future<void> _verificarEstadoPago() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select('estado_pago')
          .eq('id', user.uid)
          .single();

      if (mounted) {
        setState(() {
          _estadoPago = response['estado_pago'];
          _successSent =
              _estadoPago == 'pendiente' ||
              _estadoPago == 'pagado' ||
              _estadoPago == 'rechazado';
        });
      }
    } catch (e) {
      // Puedes manejar error si quieres
    }
  }

  Future<void> _handlePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showResultDialog(false, 'No se encontró el usuario.');
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'estado_pago': 'pendiente'})
          .eq('id', user.uid);

      setState(() => _successSent = true);
      _showResultDialog(true, 'Pago enviado correctamente. Estado: pendiente');
    } catch (e) {
      _showResultDialog(false, 'Error al actualizar el estado: $e');
    }
    setState(() => _loading = false);
  }

  void _showResultDialog(bool success, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: success ? Colors.green[50] : Colors.red[50],
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              success ? 'Éxito' : 'Error',
              style: TextStyle(color: success ? Colors.green : Colors.red),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(success ? 'Continuar' : 'Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pago con QR'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeIn(
              duration: const Duration(milliseconds: 500),
              child: Container(
                height: size.height * 0.34,
                width: size.width * 0.8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Bordes del container
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Misma medida para que coincida
                  child: Image.asset('assets/qryape.png', fit: BoxFit.contain),
                ),
              ),
            ),

            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: Card(
                color: Colors.deepPurple.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.deepPurple),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Recomendación: Realiza el pago usando el mismo nombre con el que te registraste en la app para evitar inconvenientes al validar tu comprobante.",
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ZoomIn(
              duration: const Duration(milliseconds: 500),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _successSent
                      ? const Icon(Icons.check_circle, color: Colors.white)
                      : const Icon(Icons.send, color: Colors.white),
                  label: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _successSent ? "Enviado" : "Enviar comprobante",
                          style: const TextStyle(color: Colors.white),
                        ),
                  onPressed: _loading || _successSent ? null : _handlePayment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeIn(
              duration: Duration(milliseconds: 400),
              child: Text(
                "Escanea el código QR desde tu aplicación bancaria y presiona el botón una vez realizado el pago.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
