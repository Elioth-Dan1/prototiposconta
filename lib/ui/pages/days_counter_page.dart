import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DaysCounterPage extends StatefulWidget {
  const DaysCounterPage({super.key});

  @override
  State<DaysCounterPage> createState() => _DaysCounterPageState();
}

class _DaysCounterPageState extends State<DaysCounterPage> {
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null); // ✅ aquí se soluciona
  }

  int get _daysWithoutUse {
    if (_startDate == null) return 0;
    final now = DateTime.now();
    return now.difference(_startDate!).inDays;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _startDate != null
        ? DateFormat.yMMMMd('es_ES').format(_startDate!)
        : 'No seleccionada';

    return Scaffold(
      appBar: AppBar(title: const Text('Contador de Días sin Consumo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              _startDate != null
                  ? '¡Has estado sin consumir durante:'
                  : 'Selecciona la fecha de inicio:',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            if (_startDate != null)
              Text(
                '$_daysWithoutUse días',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _selectStartDate(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Seleccionar fecha de inicio'),
            ),
            const SizedBox(height: 20),
            Text('Fecha seleccionada: $formattedDate'),
          ],
        ),
      ),
    );
  }
}
