import 'package:flutter_test/flutter_test.dart';
import 'package:main/ui/screens/home_page.dart';

void main() {
  testWidgets('exibe a tela de agendamento', (WidgetTester tester) async {
    await tester.pumpWidget(const HomePage());

    expect(find.text('Studio Cleusa'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
