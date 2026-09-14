import 'package:flutter_test/flutter_test.dart';
import 'package:levetor_hub_mobile/app.dart';

void main() {
  testWidgets('Levetor Hub app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LevetorHubApp());

    expect(find.text('Levetor Hub'), findsOneWidget);
    expect(find.text('Every Gadget You Love, One Hub.'), findsOneWidget);
  });
}