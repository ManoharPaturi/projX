import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/main.dart';

import 'helpers.dart';

void main() {
  testWidgets('first run shows the getting-started checklist', (tester) async {
    final state = await seededAppState();
    await tester.pumpWidget(OmrApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('My Institute'), findsOneWidget);
    expect(find.byKey(const Key('getting-started')), findsOneWidget);
    expect(find.text('0 of 5 done — tap a step to do it.'), findsOneWidget);
    expect(find.text('Add your students'), findsOneWidget);
    // Nothing to scan into yet: the big scan button waits for an exam.
    expect(find.text('Scan answer sheets'), findsNothing);
    expect(find.text('sheets to check'), findsOneWidget);
  });

  testWidgets('naming the institute updates the title and ticks step 1', (
    tester,
  ) async {
    final state = await seededAppState();
    await tester.pumpWidget(OmrApp(state: state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your institute name'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('institute-name-field')),
      'Sunrise Coaching',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Sunrise Coaching'), findsOneWidget);
    expect(find.text('1 of 5 done — tap a step to do it.'), findsOneWidget);
    expect(state.instituteName, 'Sunrise Coaching');
  });
}
