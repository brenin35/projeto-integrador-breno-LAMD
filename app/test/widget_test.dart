// Smoke test: sem autenticação, o app abre na tela de login.
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Entrar'), findsOneWidget);
  });
}
