import 'package:flutter_test/flutter_test.dart';

import 'package:hackathon_code/app/app.dart';

void main() {
  testWidgets('LabScreen app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LabScreenApp());

    expect(find.text('LabScreen'), findsOneWidget);
  });
}