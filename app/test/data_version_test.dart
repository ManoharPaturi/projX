import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_app/src/data_version.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

/// Screens key their data loads on the data version. A screen covered by
/// another route (the camera over the exam page) must not reload after
/// every sheet — and must catch up once it is shown again.
void main() {
  late AppState state;

  setUp(() async => state = await seededAppState());
  tearDown(() => state.db.close());

  testWidgets('covered screens keep their version and catch up on return', (
    tester,
  ) async {
    final seen = <int>[];
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          navigatorKey: navigator,
          home: Builder(
            builder: (context) {
              seen.add(context.watchDataVersion());
              return const Text('under');
            },
          ),
        ),
      ),
    );
    final start = state.version;
    expect(seen.last, start);

    navigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('camera')),
    );
    await tester.pumpAndSettle();

    // Three sheets scanned while covered: the version moves, the screen
    // underneath keeps showing what it last loaded.
    for (var i = 0; i < 3; i++) {
      state.refresh();
      await tester.pump();
    }
    expect(state.version, start + 3);
    expect(seen.toSet(), {start});

    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(seen.last, start + 3, reason: 'one catch-up on return');

    state.refresh();
    await tester.pump();
    expect(seen.last, start + 4, reason: 'live again while on top');
  });
}
