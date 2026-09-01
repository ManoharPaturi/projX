import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/main.dart';

import 'helpers.dart';

void main() {
  testWidgets('boots to the dashboard over a seeded in-memory db',
      (tester) async {
    final state = await seededAppState();
    await tester.pumpWidget(OmrApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('My Institute'), findsOneWidget);
    expect(find.text('students'), findsOneWidget);
    expect(find.text('pending review'), findsOneWidget);
    expect(find.text('No exams yet. Create one, import the roster, then scan.'),
        findsOneWidget);
  });
}
