import 'package:flutter_test/flutter_test.dart';
import 'package:texticode_mobile/main.dart';

void main() {
  testWidgets('TexticodeApp se inicia correctamente', (WidgetTester tester) async {
    // Construir la aplicación principal de Texticode.
    await tester.pumpWidget(const TexticodeApp());

    // Verificar que la aplicación se haya iniciado.
    expect(find.byType(TexticodeApp), findsOneWidget);
  });
}