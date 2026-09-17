import 'package:flutter_test/flutter_test.dart';
import 'package:phone_game/main.dart';

void main() {
  testWidgets('home screen shows Play', (WidgetTester tester) async {
    await tester.pumpWidget(const SumTenApp());
    expect(find.text('Sum Ten'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });
}
