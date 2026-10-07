import 'dart:typed_data';

import 'package:flutter/material.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:omr_app/features/calibration/calibration_screen.dart';
import 'package:omr_app/features/settings/settings_screen.dart';
import 'package:omr_app/src/app_state.dart';
import 'package:omr_data/omr_data.dart';
import 'package:omr_detect/omr_detect.dart';

import 'helpers.dart';

/// The M4 surfaces: the settings tiles write through SettingsDao, and the
/// calibration screen's analyze leg renders the margin report and applies
/// the suggested preset.
void main() {
  late AppState state;

  setUp(() async {
    state = await seededAppState();
  });

  tearDown(() => state.db.close());

  test('settings DAO round-trip over the seeded tenant', () async {
    final dao = SettingsDao(state.db);
    expect((await dao.settingsFor(state.tenantId)).strictness, 'normal');

    await dao.write(
      tenantId: state.tenantId,
      strictness: 'strict',
      retentionGraceDays: 14,
    );
    final settings = await dao.settingsFor(state.tenantId);
    expect(settings.strictness, 'strict');
    expect(settings.retentionGraceDays, 14);
  });

  testWidgets('strictness tile: pick Strict in the dialog, persists + '
      'subtitle updates', (tester) async {
    await tester.pumpWidget(
      wrapForTest(const SettingsScreen(key: Key('settings')), state),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Normal — recommended'), findsOneWidget);

    await tester.tap(find.text('Photo quality check'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Strict — asks for sharper photos'));
    await tester.pumpAndSettle();

    expect(
      (await SettingsDao(state.db).settingsFor(state.tenantId)).strictness,
      'strict',
    );
    expect(
      find.textContaining('Strict — asks for sharper photos'),
      findsOneWidget,
    );
  });

  testWidgets('retention tile: entering 14 days persists', (tester) async {
    await tester.pumpWidget(
      wrapForTest(const SettingsScreen(key: Key('settings')), state),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('7 days — then deleted'), findsOneWidget);

    await tester.tap(find.text('Keep full-size photos for'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('retention-days-field')), '14');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      (await SettingsDao(
        state.db,
      ).settingsFor(state.tenantId)).retentionGraceDays,
      14,
    );
    expect(find.textContaining('14 days — then deleted'), findsOneWidget);
  });

  testWidgets('calibration analyze leg shows the report; comfortable needs '
      'no preset change', (tester) async {
    var analyzed = 0;
    final screen = CalibrationScreen(
      stillSource: () async => Uint8List.fromList([1, 2, 3]),
      analyze: (bytes) async {
        analyzed++;
        return CalibrationReport(
          registrationOk: true,
          fiducialScores: const [0.9, 0.9, 0.9, 0.9],
          regions: [
            const CalibrationRegionReport(
              band: 't',
              emptyMin: 230,
              fullMax: 60,
              faintMean: 150,
              midMean: 105,
              samples: 12,
            ),
          ],
        );
      },
    );
    await tester.pumpWidget(wrapForTest(screen, state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2. Take its photo and check'));
    await tester.pumpAndSettle();

    expect(analyzed, 1);
    expect(
      find.textContaining('Sheets from this printer read well'),
      findsOneWidget,
    );
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PASS - min band margin'), findsOneWidget);
    expect(find.textContaining('Band T'), findsOneWidget);
    expect(find.textContaining('Use the suggested setting'), findsNothing);
  });

  testWidgets('tight calibration offers the strict preset and applies it', (
    tester,
  ) async {
    final screen = CalibrationScreen(
      stillSource: () async => Uint8List.fromList([1, 2, 3]),
      analyze: (bytes) async => CalibrationReport(
        registrationOk: true,
        fiducialScores: const [0.9, 0.9, 0.9, 0.9],
        regions: [
          const CalibrationRegionReport(
            band: 't',
            emptyMin: 230,
            fullMax: 205, // separation 25: tight, not comfortable
            faintMean: 215,
            midMean: 210,
            samples: 12,
          ),
        ],
      ),
    );
    await tester.pumpWidget(wrapForTest(screen, state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2. Take its photo and check'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Usable, but faint marks'), findsOneWidget);

    await tester.tap(find.textContaining('Use the suggested setting (strict)'));
    await tester.pumpAndSettle();

    expect(
      (await SettingsDao(state.db).settingsFor(state.tenantId)).strictness,
      'strict',
    );
  });

  testWidgets('retention refuses 0 days with a message', (tester) async {
    await tester.pumpWidget(
      wrapForTest(const SettingsScreen(key: Key('settings')), state),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep full-size photos for'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('retention-days-field')), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a number of days from 1 to 365'), findsOneWidget);
    expect(
      (await SettingsDao(
        state.db,
      ).settingsFor(state.tenantId)).retentionGraceDays,
      7,
    );
  });
}
