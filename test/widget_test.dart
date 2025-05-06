import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uberonv1beta/main.dart'; // Aponte para o arquivo main

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Construa o aplicativo com a estrutura do MaterialApp.
    await tester.pumpWidget(UberON()); // Usando o UberON como a entrada.

    // Verifique se o contador começa em 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Toque no ícone '+' e acione um novo frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifique se o contador foi incrementado.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}