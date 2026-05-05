import 'package:flutter_test/flutter_test.dart';
import 'package:gizione/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GiziOneApp());
    expect(find.byType(GiziOneApp), findsOneWidget);
  });
}
