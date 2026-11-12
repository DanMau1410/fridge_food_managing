import 'package:flutter_test/flutter_test.dart';

import 'package:fridge_food_managing/main.dart';

void main() {
  testWidgets('Shows the empty fridge page', (WidgetTester tester) async {
    await tester.pumpWidget(const FridgeApp());

    expect(find.text('My Fridge'), findsOneWidget);
    expect(find.textContaining('Your fridge is empty'), findsOneWidget);
  });
}
