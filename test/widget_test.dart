import 'package:flutter_test/flutter_test.dart';

import 'package:hackathon_code/app/app.dart';

void main() {
  testWidgets('PocketScope app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PocketScopeApp());

    expect(find.text('PocketScope'), findsNothing);
  });
}