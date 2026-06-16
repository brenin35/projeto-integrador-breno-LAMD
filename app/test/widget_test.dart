// Smoke test: sem autenticação, o app abre na tela de login.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:app/main.dart';
import 'package:app/services/api_client.dart';
import 'package:app/services/realtime_service.dart';

void main() {
  testWidgets('abre na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(
      CaronascarApp(api: ApiClient(), realtime: RealtimeService()),
    );
    await tester.pump();

    expect(find.text('Caronascar'), findsOneWidget);
    // "Entrar" aparece na aba do seletor e no botão de submit.
    expect(find.text('Entrar'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });
}
