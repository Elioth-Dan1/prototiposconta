import 'package:app_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construye el widget de la app y lo muestra
    await tester.pumpWidget(const MyApp());

    // Verifica que el contador empieza en 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Toca el botón '+' una vez
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // Vuelve a renderizar la UI

    // Verifica que el contador ahora muestra 1
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
